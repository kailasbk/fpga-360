`default_nettype none
`timescale 1ns / 1ps

module fp32_round (
  input wire clk_in,

  input wire [8:0] normalized_exp_in,
  input wire [47:0] normalized_frac_in,

  output logic [8:0] rounded_exp_out,
  output logic [22:0] rounded_frac_out
);

  logic [23:0] frac_upper_half, frac_lower_half;
  assign frac_upper_half = normalized_frac_in[47:24];
  assign frac_lower_half = normalized_frac_in[23:0];

  logic frac_upper_lsb;
  assign frac_upper_lsb = normalized_frac_in[24];

  logic frac_rounding_add;
  always_comb begin
    if (frac_lower_half > 24'b1000_0000_0000_0000_0000_0000) begin
      frac_rounding_add = 1'b1;
    end else if (frac_lower_half < 24'b1000_0000_0000_0000_0000_0000) begin
      frac_rounding_add = 1'b0;
    end else begin
      frac_rounding_add = frac_upper_lsb;
    end
  end

  logic exp_rounding_add;
  assign exp_rounding_add = &frac_upper_half && frac_rounding_add;

  always_ff @(posedge clk_in) begin
    // calculate rounded c fraction
    rounded_frac_out <= normalized_frac_in[46:24] + frac_rounding_add;

    // calculate rounded c exponent
    rounded_exp_out <= normalized_exp_in + exp_rounding_add;
  end

endmodule

`default_nettype wire
