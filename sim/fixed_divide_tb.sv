`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"

`include "src/util/valid_pipe.sv"
`include "src/util/fixed_divide.sv"

module fixed_divide_tb;

  logic clk_in;
  logic [23:0] dividend_in;
  logic [23:0] divisor_in;

  logic overflow_out;
  logic [25:0] quotient_out;

  fixed_divide uut (
    .clk_in,
    .dividend_in,
    .divisor_in,
    .overflow_out,
    .quotient_out
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(3, fixed_divide_tb);
    clk_in = 0;
    #10;

    dividend_in = 24'b1000_0100_0110_1010_1001_0111;
    divisor_in = 24'b1100_1001_1111_1010_1010_0100;
    // quotient = 0.65559451231 = 0x14FAA14
    // overflow = 0
    #10;

    dividend_in = 24'b1111_0100_0110_1010_1001_0111;
    divisor_in = 24'b0011_1001_1111_1010_1010_0100;
    // quotient = N/A
    // overflow = 1
    #10;

    #300;

    $finish;
  end

endmodule;

`default_nettype wire
