`default_nettype none
`timescale 1ns / 1ps

module top_level (
  input wire clk_in,

  input wire [15:0] sw,
  input wire btnr,
  input wire vjoyp3, vjoyn3, vjoyp11, vjoyn11,
  input wire uart_txd_in,
  output logic uart_rxd_out,
  output logic joy_s,
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

  logic pause;
  assign pause = sw[14];

  logic rx_in;
  assign rx_in = uart_txd_in;

  logic tx_out;
  assign uart_rxd_out = tx_out;

  logic skylight;
  assign skylight = sw[13];

  logic crosshair_in;
  assign crosshair_in = sw[12];

  logic [15:0] upper_count;
  logic [15:0] lower_count;
  seven_segment_controller ssc (
    .clk_in(gpu_clk),
    .rst_in,
    .val_in({upper_count, lower_count}),
    .cat_out(ca),
    .an_out(an)
  );

  // CONTROL LOGIC

  logic [2:0][31:0] right, up, direction;
  logic [2:0][31:0] position;
  logic [1:0][1:0][11:0] debug_joystick_data;
  dual_joystick_smooth_ctrl ctrl (
    .clk(gpu_clk),
    .rst(rst_in),
    .btnr,
    .vjoyp3, .vjoyn3, .vjoyp11, .vjoyn11,
    .joy_s,
    .debug_joystick_data,
    .x_vec(right),
    .y_vec(up),
    .z_vec(direction),
    .pos(position)
  );

  // GRAPHICS LOGIC

  enum {WaitBuffer, UpdateCounters, WaitEnd} state;

  logic [21:0] timer;

  logic pipeline_rst;
  logic matrix_rst;
  logic framebuffer_clear;
  logic framebuffer_switch;
  logic framebuffer_ready;

  logic [15:0] pixel_count;
  logic [15:0] vertex_count;
  logic [15:0] frame_count;

  always_ff @(posedge gpu_clk) begin
    if (rst_in) begin
      timer <= 22'd0;
      pipeline_rst <= 1'b1;
      matrix_rst <= 1'b0;
      framebuffer_switch <= 1'b0;
      framebuffer_clear <= 1'b1;
      pixel_count <= 16'd0;
      vertex_count <= 16'd0;
      frame_count <= 16'd0;
      state <= WaitEnd;
    end else begin
      case (state)
        WaitBuffer: begin
          matrix_rst <= 1'b0;
          if (framebuffer_ready) begin
            pipeline_rst <= 1'b0;
            state <= UpdateCounters;
          end
        end
        UpdateCounters: begin
          pixel_count <= 0;
          vertex_count <= 0;
          frame_count <= frame_count + 1;
          state <= WaitEnd;
        end
        WaitEnd: begin
          if (pixel_valid) begin
            pixel_count <= pixel_count + 1;
          end

          if (fetch_valid) begin
            vertex_count <= vertex_count + 1;
          end

          if (!framebuffer_ready && timer > 100) begin
            matrix_rst <= 1'b1;
            pipeline_rst <= 1'b1;
            state <= WaitBuffer;
          end
        end
      endcase

      if (pause) begin
        framebuffer_switch <= 1'b0;
        framebuffer_clear <= 1'b0;
      end else if (timer == 22'd2_000_000) begin
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

  logic matrix_valid;
  logic [3:0][31:0] matrix_col;
  matrix_gen matrix_gen (
    .clk_in,
    .rst_in,
    .valid_in(matrix_rst),
    .right_in(right),
    .up_in(up),
    .direction_in(direction),
    .pos_in(position),
    .valid_out(matrix_valid),
    .col_out(matrix_col)
  );

  logic [15:0] memory_index_id;
  logic [2:0][11:0] memory_index;
  logic [11:0] memory_position_id;
  logic [2:0][31:0] memory_position;
  logic [11:0] memory_normal_id;
  logic [2:0][31:0] memory_normal;
  logic [11:0] memory_material_id;
  logic [2:0][31:0] memory_material;
  model_memory model_memory (
    .clk_in(gpu_clk),
    .rst_in,
    .rx_in,
    .tx_out,
    .index_id_in(memory_index_id),
    .index_out(memory_index),
    .position_id_in(memory_position_id),
    .position_out(memory_position),
    .normal_id_in(memory_normal_id),
    .normal_out(memory_normal),
    .material_id_in(memory_material_id),
    .material_out(memory_material)
  );

  // vertex fetch stage
  logic fetch_valid;
  logic [2:0][31:0] fetch_position;
  logic [11:0] fetch_debug_position_id;
  logic [11:0] fetch_normal;
  logic [11:0] fetch_material;
  vertex_fetch vertex_fetch (
    .clk_in(gpu_clk),
    .rst_in(rst_in || pipeline_rst),
    .index_id_out(memory_index_id),
    .index_in(memory_index),
    .position_id_out(memory_position_id),
    .position_in(memory_position),
    .valid_out(fetch_valid),
    .position_out(fetch_position),
    .debug_position_id_out(fetch_debug_position_id),
    .normal_out(fetch_normal),
    .material_out(fetch_material)
  );

  // vertex shader stage
  logic shader_valid;
  logic [3:0][31:0] shader_position;
  logic [11:0] shader_normal;
  logic [11:0] shader_material;
  vertex_shader vertex_shader (
    .clk_in(gpu_clk),
    .rst_in,
    .col_set_in(matrix_valid),
    .col_in(matrix_col),
    .valid_in(fetch_valid),
    .position_in(fetch_position),
    .normal_in(fetch_normal),
    .material_in(fetch_material),
    .valid_out(shader_valid),
    .position_out(shader_position),
    .normal_out(shader_normal),
    .material_out(shader_material)
  );

  // triangle clipping stage
  logic clip_valid;
  logic [3:0][31:0] clip_position;
  logic [11:0] clip_normal;
  logic [11:0] clip_material;
  triangle_clip triangle_clip (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(shader_valid),
    .position_in(shader_position),
    .normal_in(shader_normal),
    .material_in(shader_material),
    .valid_out(clip_valid),
    .position_out(clip_position),
    .normal_out(clip_normal),
    .material_out(clip_material)
  );

  // perspective divide stage
  logic ndc_valid;
  logic [3:0][31:0] ndc_position;
  perspective_divide perspective_divide (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(clip_valid),
    .vertex_in(clip_position),
    .valid_out(ndc_valid),
    .vertex_out(ndc_position)
  );

  // viewport transform state
  logic viewport_valid;
  logic [3:0][31:0] viewport_position;
  viewport_transform viewport_transform (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(ndc_valid),
    .vertex_in(ndc_position),
    .valid_out(viewport_valid),
    .vertex_out(viewport_position)
  );

  // triangle fifo stage
  logic fifo_valid;
  logic [3:0][31:0] fifo_position;
  logic [11:0] fifo_normal;
  logic [11:0] fifo_material;
  logic rasterizer_ready;
  triangle_fifo triangle_fifo (
    .clk_in(gpu_clk),
    .rst_in,
    .position_valid_in(viewport_valid),
    .position_in(viewport_position),
    .normal_valid_in(clip_valid),
    .normal_in(clip_normal),
    .material_valid_in(clip_valid),
    .material_in(clip_material),
    .valid_out(fifo_valid),
    .ready_in(rasterizer_ready),
    .position_out(fifo_position),
    .normal_out(fifo_normal),
    .material_out(fifo_material)
  );

  // rasterizer
  logic fragment_valid;
  logic [15:0] triangle_id;
  logic [2:0][16:0] fragment;
  logic [11:0] fragment_normal;
  logic [11:0] fragment_material;
  rasterizer rasterizer (
    .clk_in(gpu_clk),
    .rst_in,
    .valid_in(fifo_valid),
    .ready_out(rasterizer_ready),
    .position_in(fifo_position),
    .normal_in(fifo_normal),
    .material_in(fifo_material),
    .valid_out(fragment_valid),
    .triangle_id_out(triangle_id),
    .fragment_out(fragment),
    .normal_out(fragment_normal),
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
    .light_direction(skylight ? 96'h3F13CD3A_3F13CD3A_3F13CD3A : direction),
    .triangle_id_in(triangle_id),
    .fragment_in(fragment),
    .normal_id_in(fragment_normal),
    .material_id_in(fragment_material),

    .normal_id_out(memory_normal_id),
    .normal_in(memory_normal),
    .material_id_out(memory_material_id),
    .material_in(memory_material),

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
    .crosshair_in,
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

  // DEBUG PANEL CONTROL

  always_ff @(posedge gpu_clk) begin
    case (sw[4:0])
      5'b00000: begin
        lower_count <= debug_joystick_data[0][0];
        upper_count <= debug_joystick_data[0][1];
      end
      5'b00001: begin
        lower_count <= debug_joystick_data[1][0];
        upper_count <= debug_joystick_data[1][1];
      end
      5'b00010: begin
        lower_count <= state;
        upper_count <= memory_index_id;
      end
      5'b00011: begin
        if (fetch_valid) begin
          {upper_count, lower_count} <= {fetch_debug_position_id, fetch_normal, fetch_material[7:0]};
        end
      end
      5'b00100: begin
        lower_count <= vertex_count;
        upper_count <= pixel_count;
      end
    endcase
  end

endmodule

`default_nettype wire
