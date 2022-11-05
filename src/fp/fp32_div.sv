`default_nettype none
`timescale 1ns / 1ps

module fp32_div (
  input wire clk_in,
  input wire rst_in,
  
  input wire valid_in,
  input wire [31:0] a_in,
  input wire [31:0] b_in,

  output logic valid_out,
  output logic [31:0] c_out
);

  valid_pipe #(
    .LATENCY(30)
  ) valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in,
    .valid_out
  );

  logic a_lead, b_lead;
  assign a_lead = a_in[30:23] != 8'b0;
  assign b_lead = b_in[30:23] != 8'b0;

  logic a_sign, b_sign;
  logic [8:0] a_exp, b_exp;
  logic [23:0] a_frac, b_frac;
  always_ff @(posedge clk_in) begin
    if (valid_in) begin
      // a and b signs
      a_sign <= a_in[31];
      b_sign <= b_in[31];

      // a and b biased exponents
      a_exp <= {1'b0, a_in[30:23]};
      b_exp <= {1'b0, b_in[30:23]};

      // a and b fractions
      a_frac <= {a_lead, a_in[22:0]};
      b_frac <= {b_lead, b_in[22:0]};
    end
  end

  logic is_zero, is_infinity;
  pipe #(
    .LATENCY(28),
    .WIDTH(2)
  ) flag_pipe (
    .clk_in,
    .data_in({a_exp == 9'h00 || b_exp == 9'hFF, a_exp == 9'hFF || b_exp == 9'h00}),
    .data_out({is_zero, is_infinity})
  );

  logic [8:0] exp_diff;
  always_ff @(posedge clk_in) begin
    exp_diff <= a_exp - b_exp;
  end

  logic [8:0] c_base_exp;
  pipe #(
    .LATENCY(25),
    .WIDTH(9)
  ) exp_pipe (
    .clk_in,
    .data_in(exp_diff + 9'd127),
    .data_out(c_base_exp)
  );

  logic [25:0] c_base_frac;
  fixed_divide divide (
    .clk_in,
    .dividend_in(a_frac),
    .divisor_in(b_frac),
    .quotient_out(c_base_frac)
  );

  logic [8:0] c_normalized_exp;
  logic [47:0] c_normalized_frac;
  always_ff @(posedge clk_in) begin
    if (c_base_frac[25]) begin
      // frac = 1.xxxx
      c_normalized_exp <= c_base_exp;
      c_normalized_frac <= {c_base_frac[25:0], 22'b0};
    end else begin
      // frac = 0.xxxx
      c_normalized_exp <= c_base_exp - 9'd1;
      c_normalized_frac <= {c_base_frac[24:0], 23'b0};
    end
  end

  logic [8:0] c_rounded_exp;
  logic [22:0] c_rounded_frac;
  fp32_round round (
    .clk_in,
    .normalized_exp_in(c_normalized_exp),
    .normalized_frac_in(c_normalized_frac),
    .rounded_exp_out(c_rounded_exp),
    .rounded_frac_out(c_rounded_frac)
  );

  logic [7:0] c_exp;
  logic [22:0] c_frac;
  always_ff @(posedge clk_in) begin
    if (is_zero || (c_rounded_exp >= 9'd384 && !is_infinity)) begin
      // round to zero
      c_exp <= 8'b0000_0000;
      c_frac <= c_rounded_frac;
    end else if (is_infinity || c_rounded_exp >= 9'd256) begin
      // round to infinity
      c_exp <= 8'b1111_1111;
      c_frac <= c_rounded_frac;
    end else begin
      // keep in bounds
      c_exp <= c_rounded_exp[7:0];
      c_frac <= c_rounded_frac;
    end
  end

  pipe #(
    .LATENCY(29),
    .WIDTH(1)
  ) sign_pipe (
    .clk_in,
    .data_in(a_sign ^ b_sign),
    .data_out(c_out[31])
  );

  assign c_out[30:23] = c_exp;
  assign c_out[22:0] = c_frac;

endmodule

`default_nettype wire
