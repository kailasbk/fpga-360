`default_nettype none
`timescale 1ns / 1ps

module fp32_dot (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [3:0][31:0] a_in,
  input wire [3:0][31:0] b_in,

  output logic valid_out,
  output logic [31:0] c_out
);

  // stage 1: multiply component-wise
  logic prod_valid;
  logic [31:0] x_prod;
  fp32_mul x_mul (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(a_in[0]),
    .b_in(b_in[0]),
    .valid_out(prod_valid),
    .c_out(x_prod)
  );

  logic [31:0] y_prod;
  fp32_mul y_mul (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(a_in[1]),
    .b_in(b_in[1]),
    .valid_out(),
    .c_out(y_prod)
  );

  logic [31:0] z_prod;
  fp32_mul z_mul (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(a_in[2]),
    .b_in(b_in[2]),
    .valid_out(),
    .c_out(z_prod)
  );

  logic [31:0] w_prod;
  fp32_mul w_mul (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in(a_in[3]),
    .b_in(b_in[3]),
    .valid_out(),
    .c_out(w_prod)
  );

  // stage 2: merge from 4 products to 2 sums
  logic add_valid;
  logic [31:0] xy_sum;
  fp32_add xy_add (
    .clk_in,
    .rst_in,
    .valid_in(prod_valid),
    .a_in(x_prod),
    .b_in(y_prod),
    .valid_out(add_valid),
    .c_out(xy_sum)
  );

  logic [31:0] zw_sum;
  fp32_add zw_add (
    .clk_in,
    .rst_in,
    .valid_in(prod_valid),
    .a_in(z_prod),
    .b_in(w_prod),
    .valid_out(),
    .c_out(zw_sum)
  );

  // stage 3: merge from 2 sums to 1 sum
  logic final_valid;
  fp32_add add (
    .clk_in,
    .rst_in,
    .valid_in(add_valid),
    .a_in(xy_sum),
    .b_in(zw_sum),
    .valid_out,
    .c_out
  );

endmodule

`default_nettype wire
