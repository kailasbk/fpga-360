`default_nettype none
`timescale 1ns / 1ps

module framebuffer (
  input wire gpu_clk_in,
  input wire vga_clk_in,
  input wire rst_in,
  input wire clear_in,
  input wire switch_in,

  input wire valid_in,
  input wire [8:0] x,
  input wire [7:0] y,
  input wire [7:0] z,
  input wire [11:0] rgb_in,

  output logic hsync_out,
  output logic vsync_out,
  output logic [11:0] rgb_out
);

  // vga module goes here

  // two port bram

endmodule

`default_nettype wire
