`default_nettype none
`timescale 1ns / 1ps

module fragment_shader (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [3:0][31:0] fragment_in,

  output logic valid_out,
  output logic [8:0] x_out,
  output logic [7:0] y_out,
  output logic [7:0] z_out,
  output logic [11:0] rgb_out
);

  // implementation here

endmodule

`default_nettype wire
