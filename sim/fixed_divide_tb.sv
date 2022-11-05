`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"

`include "src/util/valid_pipe.sv"
`include "src/util/fixed_divide.sv"

module fixed_divide_tb;

  logic clk_in;
  logic [23:0] dividend_in;
  logic [23:0] divisor_in;

  logic [25:0] quotient_out;

  fixed_divide uut (
    .clk_in,
    .dividend_in,
    .divisor_in,
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

    dividend_in = 24'b101111010111111101110111;
    divisor_in = 24'b110111101110001011101001;
    // quotient = 
    #10;
    #10;

    #300;

    $finish;
  end

endmodule;

`default_nettype wire
