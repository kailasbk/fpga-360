`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"

`include "src/util/pipe.sv"
`include "src/util/valid_pipe.sv"
`include "src/util/fixed_divide.sv"
`include "src/fp/fp32_round.sv"
`include "src/fp/fp32_div.sv"

module fp32_div_tb;

  logic clk_in;
  logic rst_in;
  logic valid_in;
  logic [31:0] a_in;
  logic [31:0] b_in;

  logic valid_out;
  logic [31:0] c_out;

  fp32_div uut (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in,
    .b_in,
    .valid_out,
    .c_out
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(3, fp32_div_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    valid_in = 0;
    #10;

    valid_in = 1;
    a_in = 32'h4268DA1D;
    b_in = 32'h44E60989;
    // res = 0x3D0190F4
    #10;

    valid_in = 1;
    a_in = 32'h43F5906C;
    b_in = 32'h460B3931;
    // res = 0x3D61C4A6
    #10;
    
    valid_in = 1;
    a_in = 32'h421C5604;
    b_in = 32'hBFA624DD;
    // res = 0xC1F0E335
    #10;

    valid_in = 0;
    #10;

    #400;

    $finish;
  end

endmodule;

`default_nettype wire
