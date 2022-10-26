`default_nettype none
`timescale 1ns / 1ps

// iverilog friendly definitions of vivado macros

module ADDSUB_MACRO (
  output logic CARRYOUT,
  output logic [47:0] RESULT,
  input wire [47:0] A,
  input wire ADD_SUB,
  input wire [47:0] B,
  input wire CARRYIN,
  input wire CE,
  input wire CLK,
  input wire RST
);

  logic [47:0] a, b;
  logic add, carry_in;
  always_ff @(posedge CLK) begin
    a <= A;
    b <= B;
    add <= ADD_SUB;
    carry_in <= CARRYIN;
  end

  always_ff @(posedge CLK) begin
    if (add) begin
      {CARRYOUT, RESULT} <= a + b;
    end else begin
      {CARRYOUT, RESULT} <= a - b;
    end
  end

endmodule

`default_nettype wire
