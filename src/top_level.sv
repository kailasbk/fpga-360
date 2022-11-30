`default_nettype none
`timescale 1ns / 1ps

module top_level (
  input wire clk_in,

  input wire [15:0] sw,
  // other inputs go here
  output logic [15:0] led,
  output logic [6:0] ca,
  output logic [7:0] an,

  output logic hsync_out,
  output logic vsync_out,
  output logic [11:0] rgb_out
);

  logic gpu_clk;
  logic vga_clk;
  clk_wiz clk_wiz (
    .clk_in1(clk_in),
    .clk_out1(gpu_clk),
    .clk_out2(vga_clk)
  );

  logic rst_in;
  assign rst_in = sw[15];
  assign led[15] = rst_in;

  enum {WaitBuffer, UpdateCounters, WaitEnd} state;

  logic [21:0] timer;

  logic fetch_rst;
  logic matrix_rst;
  logic framebuffer_clear;
  logic framebuffer_switch;
  logic framebuffer_ready;

  logic [15:0] upper_count;
  logic [15:0] pixel_count;
  logic [15:0] frame_count;

  always_ff @(posedge gpu_clk) begin
    if (rst_in) begin
      timer <= 22'd0;
      fetch_rst <= 1'b1;
      framebuffer_switch <= 1'b0;
      framebuffer_clear <= 1'b1;
      upper_count <= 16'd0;
      pixel_count <= 16'd0;
      frame_count <= 16'd0;
      state <= WaitEnd;
    end else begin
      case (state)
        WaitBuffer: begin
          matrix_rst <= 1'b0;
          if (framebuffer_ready) begin
            fetch_rst <= 1'b0;
            state <= UpdateCounters;
          end
        end
        UpdateCounters: begin
          pixel_count <= 0;
          frame_count <= frame_count + 1;
          state <= WaitEnd;
        end
        WaitEnd: begin
          if (pixel_valid) begin
            pixel_count <= pixel_count + 1;
          end

          if (!framebuffer_ready) begin
            upper_count <= pixel_count;
            matrix_rst <= 1'b1;
            fetch_rst <= 1'b1;
            state <= WaitBuffer;
          end
        end
      endcase

      if (timer == 22'd2_000_000) begin
        timer <= 22'd0;
        framebuffer_switch <= 1'b1;
        framebuffer_clear <= 1'b1;
      end else begin
        timer <= timer + 1;
        framebuffer_switch <= 1'b0;
        framebuffer_clear <= 1'b0;
      end
    end
  end

  seven_segment_controller ssc (
    .clk_in(gpu_clk),
    .rst_in,
    .val_in({upper_count, frame_count}),
    .cat_out(ca),
    .an_out(an)
  );
  assign led[11:0] = rgb_out;

  logic matrix_valid;
  logic [3:0][31:0] matrix_col;
  matrix_gen matrix_gen (
    .clk_in,
    .rst_in,
    .valid_in(matrix_rst),
    .right_in(96'hBF3504F3_00000000_3F3504F3),
    .up_in(96'hBEB504F3_3F5DB3D7_BEB504F3),
    .direction_in(96'h3F1CC471_3F000000_3F1CC471),
    .pos_in(96'h40000000_40000000_40000000),
    .valid_out(matrix_valid),
    .col_out(matrix_col)
  );

  // vertex fetch stage
  logic fetch_valid;
  logic [15:0] fetch_id;
  logic [2:0][31:0] fetch_vertex;
  logic [11:0] fetch_material;
  vertex_fetch vertex_fetch (
    .clk_in(gpu_clk),
    .rst_in(rst_in || fetch_rst),
    .valid_out(fetch_valid),
    .vertex_id_out(fetch_id),
    .vertex_out(fetch_vertex),
    .material_out(fetch_material)
  );

  // vertex shader stage
  logic shader_valid;
  logic [3:0][31:0] shader_vertex;
  logic [11:0] shader_material;
  vertex_shader vertex_shader (
    .clk_in(gpu_clk),
    .rst_in,
    .col_set_in(matrix_valid),
    .col_in(matrix_col),
    .valid_in(fetch_valid),
    .vertex_in(fetch_vertex),
    .material_in(fetch_material),
    .valid_out(shader_valid),
    .vertex_out(shader_vertex),
    .material_out(shader_material)
  );

  // triangle clipping stage
  logic clip_valid;
  logic [3:0][31:0] clip_vertex;
  logic [11:0] clip_material;
  triangle_clip triangle_clip (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(shader_valid),
    .vertex_in(shader_vertex),
    .material_in(shader_material),
    .valid_out(clip_valid),
    .vertex_out(clip_vertex),
    .material_out(clip_material)
  );

  // perspective divide stage
  logic ndc_valid;
  logic [3:0][31:0] ndc_vertex;
  perspective_divide perspective_divide (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(clip_valid),
    .vertex_in(clip_vertex),
    .valid_out(ndc_valid),
    .vertex_out(ndc_vertex)
  );

  // viewport transform state
  logic viewport_valid;
  logic [3:0][31:0] viewport_vertex;
  viewport_transform viewport_transform (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(ndc_valid),
    .vertex_in(ndc_vertex),
    .valid_out(viewport_valid),
    .vertex_out(viewport_vertex)
  );

  // triangle fifo stage
  logic fifo_valid;
  logic [3:0][31:0] fifo_vertex;
  logic [11:0] fifo_material;
  logic rasterizer_ready;
  triangle_fifo triangle_fifo (
    .clk_in(gpu_clk),
    .rst_in,
    .vertex_valid_in(viewport_valid),
    .vertex_in(viewport_vertex),
    .material_valid_in(clip_valid),
    .material_in(clip_material),
    .valid_out(fifo_valid),
    .ready_in(rasterizer_ready),
    .vertex_out(fifo_vertex),
    .material_out(fifo_material)
  );

  // rasterizer
  logic fragment_valid;
  logic [15:0] triangle_id;
  logic [2:0][16:0] fragment;
  logic [11:0] fragment_material;
  rasterizer rasterizer (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(fifo_valid),
    .ready_out(rasterizer_ready),
    .vertex_in(fifo_vertex),
    .material_in(fifo_material),
    .valid_out(fragment_valid),
    .triangle_id_out(triangle_id),
    .fragment_out(fragment),
    .material_out(fragment_material)
  );

  // fragment shader stage
  logic pixel_valid;
  logic [8:0] pixel_x;
  logic [7:0] pixel_y;
  logic [15:0] pixel_z;
  logic [11:0] pixel_rgb;
  fragment_shader fragment_shader (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(fragment_valid),
    .triangle_id_in(triangle_id),
    .fragment_in(fragment),
    .normal_in({32'h3F13CD3A, 32'h3F13CD3A, 32'h3F13CD3A}),
    .material_in(fragment_material),
    .valid_out(pixel_valid),
    .x_out(pixel_x),
    .y_out(pixel_y),
    .z_out(pixel_z),
    .rgb_out(pixel_rgb)
  );

  // framebuffer stage
  framebuffer framebuffer (
    .gpu_clk_in(gpu_clk),
    .vga_clk_in(vga_clk),
    .rst_in,
    .clear_in(framebuffer_clear),
    .switch_in(framebuffer_switch),
    .crosshair_in(sw[0]),
    .valid_in(pixel_valid),
    .ready_out(framebuffer_ready),
    .x_in(pixel_x),
    .y_in(pixel_y),
    .z_in(pixel_z),
    .rgb_in(pixel_rgb),
    .hsync_out,
    .vsync_out,
    .rgb_out
  );

endmodule

`default_nettype wire
