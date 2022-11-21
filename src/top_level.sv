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

  enum {Vertex1, WaitEnd, WaitBuffer} state;

  logic [21:0] timer;

  logic fetch_rst;
  logic framebuffer_clear;
  logic framebuffer_switch;
  logic framebuffer_ready;

  logic [15:0] pixel_count;
  logic [15:0] frame_count;

  always_ff @(posedge gpu_clk) begin
    if (rst_in) begin
      timer <= 22'd0;
      fetch_rst <= 1'b1;
      framebuffer_switch <= 1'b0;
      framebuffer_clear <= 1'b0;
      pixel_count <= 16'd0;
      frame_count <= 16'd0;
      state <= WaitBuffer;
    end else begin
      case (state)
        WaitBuffer: begin
          if (framebuffer_ready) begin
            fetch_rst <= 1'b0;
            state <= Vertex1;
          end
        end
        Vertex1: begin
          pixel_count <= 0;
          frame_count <= frame_count + 1;
          state <= WaitEnd;
        end
        WaitEnd: begin
          if (pixel_valid) begin
            pixel_count <= pixel_count + 1;
          end

          if (!framebuffer_ready) begin
            state <= WaitBuffer;
            fetch_rst <= 1'b1;
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
    .val_in({pixel_count, frame_count}),
    .cat_out(ca),
    .an_out(an)
  );
  assign led[11:0] = rgb_out;

  logic fetch_valid;
  logic [15:0] fetch_id;
  logic [2:0][31:0] fetch_vertex;
  logic [11:0] fetch_color;
  vertex_fetch vertex_fetch (
    .clk_in(gpu_clk),
    .rst_in(rst_in || fetch_rst),
    .valid_out(fetch_valid),
    .vertex_id_out(fetch_id),
    .vertex_out(fetch_vertex),
    .color_out(fetch_color)
  );

  logic shader_valid;
  logic [3:0][31:0] shader_vertex;
  vertex_shader vertex_shader (
    .clk_in(gpu_clk),
    .rst_in,
    .col_set_in(1'b0), // TODO: route this
    .col_in(128'b0), // TODO: route this
    .valid_in(fetch_valid),
    .vertex_in(fetch_vertex),
    .valid_out(shader_valid),
    .vertex_out(shader_vertex)
  );

  logic ndc_valid;
  logic [3:0][31:0] ndc_vertex;
  perspective_divide perspective_divide (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(shader_valid),
    .vertex_in(shader_vertex),
    .valid_out(ndc_valid),
    .vertex_out(ndc_vertex)
  );

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

  logic fifo_valid;
  logic [3:0][31:0] fifo_vertex;
  logic [11:0] fifo_color;
  logic rasterizer_ready;
  triangle_fifo triangle_fifo (
    .clk_in(gpu_clk),
    .rst_in,
    .vertex_valid_in(viewport_valid),
    .vertex_in(viewport_vertex),
    .color_valid_in(fetch_valid),
    .color_in(fetch_color),
    .valid_out(fifo_valid),
    .ready_in(rasterizer_ready),
    .vertex_out(fifo_vertex),
    .color_out(fifo_color)
  );

  // rasterizer
  logic fragment_valid;
  logic [15:0] triangle_id;
  logic [2:0][16:0] fragment;
  logic [11:0] fragment_color;
  rasterizer rasterizer (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(fifo_valid),
    .ready_out(rasterizer_ready),
    .vertex_in(fifo_vertex),
    .color_in(fifo_color),
    .valid_out(fragment_valid),
    .triangle_id_out(triangle_id),
    .fragment_out(fragment),
    .color_out(fragment_color)
  );

  // fragment shader stage
  logic pixel_valid;
  logic [8:0] pixel_x;
  logic [7:0] pixel_y;
  logic [7:0] pixel_z;
  logic [11:0] pixel_rgb;
  fragment_shader fragment_shader (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(fragment_valid),
    .triangle_id_in(triangle_id),
    .fragment_in(fragment),
    .color_in(fragment_color),
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
