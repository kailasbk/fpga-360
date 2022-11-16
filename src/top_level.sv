`default_nettype none
`timescale 1ns / 1ps

module top_level (
  input wire clk_in,

  input wire [15:0] sw,
  // other inputs go here
  output logic [15:0] led,

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

  enum {Vertex1, Wait1, Vertex2, Wait2, Vertex3, Wait3, WaitEnd, WaitBuffer} state;

  logic [21:0] counter;
  logic [5:0] color_counter;
  logic rasterizer_ready;
  logic fifo_valid;
  logic [3:0][31:0] fifo_vertex;
  logic [11:0] fifo_color;
  logic framebuffer_clear, framebuffer_switch;
  always_ff @(posedge gpu_clk) begin
    if (rst_in) begin
      counter <= 22'd0;
      color_counter <= 6'd0;
      fifo_valid <= 1'b0;
      fifo_color <= 12'hFFF;
      framebuffer_switch <= 1'b0;
      framebuffer_clear <= 1'b0;
      state <= Vertex1;
    end else begin
      case (state)
        Vertex1: begin
          fifo_valid <= 1'b1;
          fifo_vertex = {32'h00000000, 32'h3F000000, 32'h42200000, 32'h43200000}; // (160, 40)
          state <= Wait1;
        end
        Wait1: begin
          if (rasterizer_ready) begin
            fifo_valid <= 1'b0;
            state <= Vertex2;
          end
        end
        Vertex2: begin
          fifo_valid <= 1'b1;
          fifo_vertex = {32'h00000000, 32'h3F000000, 32'h42A00000, 32'h42C80000}; // (100, 80)
          state <= Wait2;
        end
        Wait2: begin
          if (rasterizer_ready) begin
            fifo_valid <= 1'b0;
            state <= Vertex3;
          end
        end
        Vertex3: begin
          fifo_valid <= 1'b1;
          fifo_vertex = {32'h00000000, 32'h3F000000, 32'h42C80000, 32'h43480000}; // (200, 100)
          state <= Wait3;
        end
        Wait3: begin
          if (rasterizer_ready) begin
            fifo_valid <= 1'b0;
            state <= WaitEnd;
          end
        end
        WaitEnd: begin
          if (!framebuffer_ready) begin
            state <= WaitBuffer;
          end
        end
        WaitBuffer: begin
          if (framebuffer_ready) begin
            state <= Vertex1;
          end
        end
      endcase

      if (counter == 22'd2_000_000) begin
        counter <= 22'd0;
        framebuffer_switch <= 1'b1;
        framebuffer_clear <= 1'b1;

        if (color_counter == 6'd63) begin
          fifo_color <= fifo_color + 1;
        end
        color_counter <= color_counter + 1;
      end else begin
        counter <= counter + 1;
        framebuffer_switch <= 1'b0;
        framebuffer_clear <= 1'b0;
      end
    end
  end

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
  logic framebuffer_ready;
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
