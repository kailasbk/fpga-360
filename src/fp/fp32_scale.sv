`default_nettype none
`timescale 1ns / 1ps

module fp32_scale (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [3:0][31:0] a_in,
  input wire [31:0] b_in,

  output logic valid_out,
  output logic [3:0][31:0] c_out
);

  fp32_mul x_mul (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(a_in[0]),
    .b_in(b_in),
    .valid_out,
    .c_out(c_out[0])
  );

  fp32_mul y_mul (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(a_in[1]),
    .b_in(b_in),
    .valid_out(),
    .c_out(c_out[1])
  );

  fp32_mul z_mul (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(a_in[2]),
    .b_in(b_in),
    .valid_out(),
    .c_out(c_out[2])
  );

endmodule

`default_nettype wire
