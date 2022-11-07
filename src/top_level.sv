`default_nettype none
`timescale 1ns / 1ps

module top_level (
  input wire clk_in,

  input wire [15:0] sw,
  // other inputs go here

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

  logic rst;
  assign rst = sw[15];

  logic valid_in;
  logic [8:0] x_in;
  logic [7:0] y_in;
  logic [7:0] z_in;
  logic [11:0] rgb_in;
  assign valid_in = sw[0];
  assign x_in = {1'b0, sw[14:8], 1'b0};
  assign y_in = {sw[7:1], 1'b0};
  assign z_in = 8'd0;
  assign rgb_in = 12'hFFF;

  framebuffer framebuffer (
    .gpu_clk_in(gpu_clk),
    .vga_clk_in(vga_clk),
    .rst_in(rst),
    .clear_in(1'b0),
    .switch_in(1'b0),

    .valid_in,
    .x_in,
    .y_in,
    .z_in,
    .rgb_in,

    .hsync_out,
    .vsync_out,
    .rgb_out
  );

endmodule

`default_nettype wire
