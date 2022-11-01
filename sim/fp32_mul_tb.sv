`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"

`include "src/util/pipe.sv"
`include "src/util/valid_pipe.sv"
`include "src/fp/fp32_round.sv"
`include "src/fp/fp32_mul.sv"

module fp32_mul_tb;

  logic clk_in;
  logic rst_in;
  logic valid_in;
  logic [31:0] a_in;
  logic [31:0] b_in;

  logic valid_out;
  logic [31:0] c_out;

  fp32_mul uut (
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
    $dumpvars(3, fp32_mul_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    valid_in = 0;
    #10;

    valid_in = 1;
    a_in = 32'h43970FFD; // 302.1249
    b_in = 32'h40C91759; // 6.2841
    // res = 0x44ED52A9 = 1898.5831
    #10;

    valid_in = 1;
    a_in = 32'h3DFFCB92; // 0.1249
    b_in = 32'h3FA45D64; // 1.2841
    // res = 0x3E243BBA = 0.16038409
    #10;

    valid_in = 1;
    a_in = 32'hC141BE77; // -12.109
    b_in = 32'h40E6C99B; // 7.21211
    // res = 0xC2AEA9B3 = -87.33144
    #10;

    valid_in = 1;
    a_in = 32'h3DE31F8A; // 0.1109
    b_in = 32'hBDD53261; // -0.1041
    // res = 0xBC3D25F0 = -0.01154469
    #10;

    valid_in = 0;
    #90;
    $finish;
  end

endmodule;

`default_nettype wire
