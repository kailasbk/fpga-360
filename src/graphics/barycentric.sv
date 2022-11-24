`default_nettype none
`timescale 1ns / 1ps

module barycentric (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [1:0][16:0] point_in,
  input wire [2:0][1:0][16:0] vertices_in,

  output logic valid_out,
  output logic [2:0] coeffs_negative_out,
  output logic [2:0][25:0] coeffs_out
);

  valid_pipe #(
    .LATENCY(32) // 1 (input) + 5 (triangle_area) + 26 (fixed_divide) = 32
  ) valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in,
    .valid_out
  );

  logic [1:0][16:0] point;
  logic [1:0][16:0] vertices [3];
  always_ff @(posedge clk_in) begin
    if (valid_in) begin
      point <= point_in;
      vertices[0] <= vertices_in[0];
      vertices[1] <= vertices_in[1];
      vertices[2] <= vertices_in[2];
    end
  end

  logic full_area_negative;
  logic [33:0] full_area;
  triangle_area full_triangle_area (
    .clk_in,
    .vertices_in({vertices[2], vertices[1], vertices[0]}),
    .negative_out(full_area_negative),
    .area_out(full_area)
  );

  logic a_area_negative;
  logic [33:0] a_area;
  triangle_area a_triangle_area (
    .clk_in,
    .vertices_in({vertices[2], vertices[1], point}),
    .negative_out(a_area_negative),
    .area_out(a_area)
  );

  logic b_area_negative;
  logic [33:0] b_area;
  triangle_area b_triangle_area (
    .clk_in,
    .vertices_in({vertices[0], vertices[2], point}),
    .negative_out(b_area_negative),
    .area_out(b_area)
  );

  logic c_area_negative;
  logic [33:0] c_area;
  triangle_area c_triangle_area (
    .clk_in,
    .vertices_in({vertices[1], vertices[0], point}),
    .negative_out(c_area_negative),
    .area_out(c_area)
  );

  pipe #(
    .LATENCY(26),
    .WIDTH(3)
  ) coeff_negative_pipe (
    .clk_in,
    .data_in({c_area_negative, b_area_negative, a_area_negative}),
    .data_out(coeffs_negative_out)
  );

  logic [25:0] a_coeff;
  logic a_overflow;
  fixed_divide a_divide (
    .clk_in,
    .dividend_in(a_area[33:10]),
    .divisor_in(full_area[33:10]),
    .overflow_out(a_overflow),
    .quotient_out(a_coeff)
  );

  logic [25:0] b_coeff;
  logic b_overflow;
  fixed_divide b_divide (
    .clk_in,
    .dividend_in(b_area[33:10]),
    .divisor_in(full_area[33:10]),
    .overflow_out(b_overflow),
    .quotient_out(b_coeff)
  );

  logic [25:0] c_coeff;
  logic c_overflow;
  fixed_divide c_divide (
    .clk_in,
    .dividend_in(c_area[33:10]),
    .divisor_in(full_area[33:10]),
    .overflow_out(c_overflow),
    .quotient_out(c_coeff)
  );

  assign coeffs_out = {c_coeff, b_coeff, a_coeff};

endmodule

`default_nettype wire
