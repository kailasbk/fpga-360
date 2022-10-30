`default_nettype none
`timescale 1ns / 1ps

module fp32_mul (
  input wire clk_in,
  input wire rst_in,
  
  input wire valid_in,
  input wire [31:0] a_in,
  input wire [31:0] b_in,

  output logic valid_out,
  output logic [31:0] c_out
);

  valid_pipe #(
    .LATENCY(6)
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

  logic is_zero, is_infinity;
  logic [8:0] exp_sum;
  logic [8:0] c_base_exp;
  always_ff @(posedge clk_in) begin
    is_zero <= (a_exp == 9'b0) || (b_exp == 9'b0);
    is_infinity <= (a_exp == 9'd31) || (b_exp == 9'd31);
    exp_sum <= a_exp + b_exp;

    // calculate pre-normalization c exponent
    c_base_exp <= exp_sum - 9'd127;
  end

  logic [47:0] frac_prod;
  logic [47:0] c_base_frac;
  always_ff @(posedge clk_in) begin
    // calculate pre-normalization c fraction
    frac_prod <= a_frac * b_frac;
    c_base_frac <= frac_prod;
  end

  logic [8:0] c_normalized_exp;
  logic [47:0] c_normalized_frac;
  always_ff @(posedge clk_in) begin
    // calculate normalized c exponent and fraction
    if (c_base_frac[47]) begin
      // frac = 1x.xxxx
      c_normalized_exp <= c_base_exp + 9'd1;
      c_normalized_frac <= c_base_frac[47:0];
    end else begin
      // frac = 01.xxxx or 00.xxxx
      c_normalized_exp <= c_base_exp;
      c_normalized_frac <= {c_base_frac[46:0], 1'b0};
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

  logic is_zero_out, is_infinity_out;
  pipe #(
    .LATENCY(3),
    .WIDTH(2)
  ) flag_pipe (
    .clk_in,
    .data_in({is_zero, is_infinity}),
    .data_out({is_zero_out, is_infinity_out})
  );

  logic [7:0] c_exp;
  logic [22:0] c_frac;
  always_ff @(posedge clk_in) begin
    if (is_zero_out || (c_rounded_exp >= 9'd384 && !is_infinity_out)) begin
      // round to zero
      c_exp <= 8'b0000_0000;
      c_frac <= c_rounded_frac;
    end else if (is_infinity_out || c_rounded_exp >= 9'd256) begin
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
    .LATENCY(5),
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
