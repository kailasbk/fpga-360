`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"

`include "src/util/pipe.sv"
`include "src/util/valid_pipe.sv"
`include "src/util/addsub.sv"
`include "src/fp/fp32_round.sv"
`include "src/fp/fp32_add.sv"
`include "src/fp/fp32_mul.sv"
`include "src/fp/fp32_dot.sv"
`include "src/graphics/matrix_gen.sv"

module matrix_gen_tb;

  logic clk_in;
  logic rst_in;

  logic valid_in;
  logic [2:0][31:0] right_in;
  logic [2:0][31:0] up_in;
  logic [2:0][31:0] direction_in;
  logic [2:0][31:0] pos_in;

  logic valid_out;
  logic [3:0][31:0] col_out;

  matrix_gen uut (
    .clk_in,
    .rst_in,
    .valid_in,
    .pos_in,
    .right_in,
    .up_in,
    .direction_in,
    .valid_out,
    .col_out
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.lxt");
    $dumpvars(3, matrix_gen_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    valid_in = 0;
    #10;

    // test case where view is only translation
    valid_in = 1;
    right_in = {32'h00000000, 32'h00000000, 32'h3F800000};
    up_in = {32'h00000000, 32'h3F800000, 32'h00000000};
    direction_in = {32'h3F800000, 32'h00000000, 32'h00000000};
    pos_in = {32'h3F8A9FBE, 32'h411C8B44, 32'hC19B1EB8};
    #10;
    valid_in = 0;
    #10;

    #3000;

    // test random matrix:
    // 67.16376 17.50700 20.04971
    // 32.53432 99.48499 54.00246
    // 24.47954 93.89921 54.82002
    // test position:
    // 6.30332 5.14939 8.15683
    // resulting matrix:
    // 67.16376 17.507 20.04971 -677.0471184325
    // 32.53432 99.48499 54.00246 -1157.8501284003
    // 24.47954 93.89921 54.82002 -1084.9836107913
    // 0 0 0 1
    // in hex:
    // C4294304_41A065CE_418C0E56_428653D8
    // C490BB34_42580285_42C6F851_42022325
    // C4879F7A_425B47B3_42BBCC65_41C3D619
    // 3F800000_00000000_00000000_00000000
    valid_in = 1;
    right_in = {32'h41A065CE, 32'h418C0E56, 32'h428653D8};
    up_in = {32'h42580285, 32'h42C6F851, 32'h42022325};
    direction_in = {32'h425B47B3, 32'h42BBCC65, 32'h41C3D619};
    pos_in = {32'h41028260, 32'h40A4C7CE, 32'h40C9B4CC};
    #10;
    valid_in = 0;
    #10;

    #3000;

    $finish;
  end

endmodule;

`default_nettype wire
