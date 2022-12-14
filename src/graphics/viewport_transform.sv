`default_nettype none
`timescale 1ns / 1ps

module viewport_transform (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [3:0][31:0] vertex_in,

  output logic valid_out,
  output logic [3:0][31:0] vertex_out
);

  // behavior should match the following:
  // x = 160 * x + 160
  // y = -120 * y + 120
  // z = (z + 1) * 0.5
  // w = w

  pipe #(
    .LATENCY(16), // 7 cycles for fp32_mul + 9 cycles for fp32_add
    .WIDTH(32)
  ) w_pipe (
    .clk_in,
    .data_in(vertex_in[3]),
    .data_out(vertex_out[3])
  );

  logic x_mul_valid;
  logic [31:0] x_mul_result;
  fp32_mul x_mul (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(vertex_in[0]),
    .b_in(32'h43200000), // 160
    .valid_out(x_mul_valid),
    .c_out(x_mul_result)
  );

  logic y_mul_valid;
  logic [31:0] y_mul_result;
  fp32_mul y_mul (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(vertex_in[1]),
    .b_in(32'hC2F00000), // -120
    .valid_out(y_mul_valid),
    .c_out(y_mul_result)
  );

  logic z_add_valid;
  logic [31:0] z_add_result;
  fp32_add z_add (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(vertex_in[2]),
    .b_in(32'h3F800000), // 1
    .valid_out(z_add_valid),
    .c_out(z_add_result)
  );

  logic x_add_valid;
  fp32_add x_add (
    .clk_in,
    .rst_in,
    .valid_in(x_mul_valid),
    .a_in(x_mul_result),
    .b_in(32'h43200000), // 160
    .valid_out(x_add_valid),
    .c_out(vertex_out[0])
  );

  logic y_add_valid;
  fp32_add y_add (
    .clk_in,
    .rst_in,
    .valid_in(y_mul_valid),
    .a_in(y_mul_result),
    .b_in(32'h42F00000), // 120
    .valid_out(y_add_valid),
    .c_out(vertex_out[1])
  );

  logic z_mul_valid;
  fp32_mul z_mul (
    .clk_in,
    .rst_in,
    .valid_in(z_add_valid),
    .a_in(z_add_result),
    .b_in(32'h3F000000), // 0.5
    .valid_out(z_mul_valid),
    .c_out(vertex_out[2])
  );

  assign valid_out = x_add_valid && y_add_valid && z_mul_valid;

endmodule

`default_nettype wire
