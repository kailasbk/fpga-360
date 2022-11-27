`default_nettype none
`timescale 1ns / 1ps

module perspective_divide (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [3:0][31:0] vertex_in,

  output logic valid_out,
  output logic [3:0][31:0] vertex_out
);

  logic x_valid;
  fp32_div x_div (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(vertex_in[0]),
    .b_in(vertex_in[3]),
    .valid_out(x_valid),
    .c_out(vertex_out[0])
  );

  logic y_valid;
  fp32_div y_div (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(vertex_in[1]),
    .b_in(vertex_in[3]),
    .valid_out(y_valid),
    .c_out(vertex_out[1])
  );

  logic z_valid;
  fp32_div z_div (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(vertex_in[2]),
    .b_in(vertex_in[3]),
    .valid_out(z_valid),
    .c_out(vertex_out[2])
  );

  logic w_valid;
  fp32_div w_div (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(32'h3F800000),
    .b_in(vertex_in[3]),
    .valid_out(w_valid),
    .c_out(vertex_out[3])
  );

  assign valid_out = x_valid && y_valid && z_valid && w_valid;

endmodule

`default_nettype wire
