`default_nettype none
`timescale 1ns / 1ps

module fp32_add (
  input wire clk_in,
  
  input wire valid_in,
  input wire [31:0] a_in,
  input wire [31:0] b_in,

  output logic valid_out,
  output logic [31:0] c_out
);

  pipe #(
    .LATENCY(10),
    .WIDTH(1)
  ) valid_pipe (
    .clk_in,
    .data_in(valid_in),
    .data_out(valid_out)
  );

  logic a_lead, b_lead;
  assign a_lead = a_in[30:23] != 8'b0;
  assign b_lead = b_in[30:23] != 8'b0;

  logic a_sign, b_sign;
  logic [7:0] a_exp, b_exp;
  logic [23:0] a_frac, b_frac;
  logic a_larger;
  always_ff @(posedge clk_in) begin
    // a and b signs
    a_sign <= a_in[31];
    b_sign <= b_in[31];

    // a and b biased exponents
    a_exp <= a_in[30:23];
    b_exp <= b_in[30:23];

    // a and b fractions
    a_frac <= {a_lead, a_in[22:0]};
    b_frac <= {b_lead, b_in[22:0]};

    a_larger <= a_in[30:23] > b_in[30:23] || (a_in[30:23] == b_in[30:23] && a_in[22:0] >= b_in[22:0]);
  end
  
  logic h_sign, l_sign;
  logic is_infinity;
  logic [7:0] h_exp;
  logic [23:0] h_frac, l_frac;
  logic [4:0] adj_shift;
  always_ff @(posedge clk_in) begin
    if (a_larger) begin
      // a is larger number
      h_sign <= a_sign;
      h_exp <= a_exp;
      h_frac <= a_frac;

      // b is smaller number
      l_sign <= b_sign;
      l_frac <= b_frac;

      adj_shift <= a_exp - b_exp;
      is_infinity <= a_exp == 8'd255;
    end else begin
      // b is larger number
      h_sign <= b_sign;
      h_exp <= b_exp;
      h_frac <= b_frac;

      // a is smaller number
      l_sign <= a_sign;
      l_frac <= a_frac;

      adj_shift <= b_exp - a_exp;
      is_infinity <= b_exp == 8'd255;
    end
  end

  logic [7:0] c_base_exp;
  pipe #(
    .LATENCY(3),
    .WIDTH(8)
  ) base_exp_pipe (
    .clk_in,
    .data_in(h_exp),
    .data_out(c_base_exp)
  );

  logic add;
  logic [23:0] h_part_adj_frac;
  logic [47:0] l_part_adj_frac;
  logic [2:0] adj_remaining_shift;
  always_ff @(posedge clk_in) begin
    add <= h_sign == l_sign;
    h_part_adj_frac <= h_frac;
    l_part_adj_frac <= {l_frac, 24'b0} >> {adj_shift[4:3], 3'b0};
    adj_remaining_shift <= adj_shift[2:0];
  end

  logic [47:0] h_adj_frac;
  logic [47:0] l_adj_frac;
  assign h_adj_frac = {h_part_adj_frac, 24'b0};
  assign l_adj_frac = l_part_adj_frac >> adj_remaining_shift;

  logic [48:0] c_base_frac;
  ADDSUB_MACRO adder (
    .CARRYOUT(c_base_frac[48]),
    .RESULT(c_base_frac[47:0]),
    .A(h_adj_frac),
    .ADD_SUB(add),
    .B(l_adj_frac),
    .CARRYIN(1'b0),
    .CE(1'b1),
    .CLK(clk_in),
    .RST(1'b0)
  );

  logic found_one;
  logic [4:0] exp_shift;
  always_comb begin
    found_one = 1'b0;
    exp_shift = 5'b0;
    for (int i = 0; i < 24; i = i + 1) begin
      if (c_base_frac[47-i]) begin
        found_one = 1'b1;
      end
      if (!found_one) begin
        exp_shift = exp_shift + 1;
      end
    end
  end

  logic [4:0] c_exp_shift;
  logic [8:0] c_shift_exp;
  logic [47:0] c_shift_frac;
  always_ff @(posedge clk_in) begin
    if (c_base_frac[48]) begin
      // frac = 1x.xxxx
      c_shift_exp <= c_base_exp + 1;
      c_exp_shift <= 8'b0;
      c_shift_frac <= c_base_frac[48:1];
    end else begin
      // frac = 0x.xxxx
      c_shift_exp <= c_base_exp;
      c_exp_shift <= exp_shift;
      c_shift_frac <= c_base_frac[47:0];
    end
  end

  logic [2:0] c_remaining_shift;
  logic [8:0] c_part_normalized_exp;
  logic [47:0] c_part_normalized_frac;
  always_ff @(posedge clk_in) begin
    c_part_normalized_frac <= c_shift_frac << {c_exp_shift[4:3], 3'b0};
    c_part_normalized_exp <= c_shift_exp - {c_exp_shift[4:3], 3'b0};
    c_remaining_shift <= c_exp_shift[2:0];
  end

  logic [8:0] c_normalized_exp;
  logic [47:0] c_normalized_frac;
  always_ff @(posedge clk_in) begin
    c_normalized_frac <= c_part_normalized_frac << c_remaining_shift;
    c_normalized_exp <= c_part_normalized_exp - c_remaining_shift;
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

  logic is_infinity_out;
  pipe #(
    .LATENCY(5),
    .WIDTH(1)
  ) flag_pipe (
    .clk_in,
    .data_in(is_infinity),
    .data_out(is_infinity_out)
  );

  logic [7:0] c_exp;
  logic [22:0] c_frac;
  always_ff @(posedge clk_in) begin
    if (c_rounded_exp >= 9'd384 && !is_infinity_out) begin
      c_exp <= 8'b0000_0000;
      c_frac <= c_rounded_frac;
    end else if (is_infinity_out || c_rounded_exp >= 9'd256) begin
      c_exp <= 8'b1111_1111;
      c_frac <= c_rounded_frac;
    end else begin
      c_exp <= c_rounded_exp[7:0];
      c_frac <= c_rounded_frac;
    end
  end

  pipe #(
    .LATENCY(8),
    .WIDTH(1)
  ) sign_pipe (
    .clk_in,
    .data_in(h_sign),
    .data_out(c_out[31])
  );

  assign c_out[30:23] = c_exp;
  assign c_out[22:0] = c_frac;

endmodule

`default_nettype wire
