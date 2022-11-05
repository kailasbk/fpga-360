`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"
`include "sim/vivado.svh"

`include "src/util/pipe.sv"
`include "src/util/valid_pipe.sv"
`include "src/fp/fp32_round.sv"
`include "src/fp/fp32_add.sv"
`include "src/fp/fp32_mul.sv"
`include "src/graphics/viewport_transform.sv"

module viewport_transform_tb;

  logic clk_in;
  logic rst_in;

  logic valid_in;
  logic [3:0][31:0] vertex_in;

  logic valid_out;
  logic [3:0][31:0] vertex_out;

  viewport_transform uut (
    .clk_in,
    .rst_in,
    .valid_in,
    .vertex_in,
    .valid_out,
    .vertex_out
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(3, viewport_transform_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    valid_in = 0;
    #10;

    // (-1, 1) => (0, 0)
    valid_in = 1;
    vertex_in = {32'hAAAAAAAA, 32'hBBBBBBBB, 32'h3F800000, 32'hBF800000};
    #10;

    // (-1, -1) => (0, 240)
    valid_in = 1;
    vertex_in = {32'hAAAAAAAA, 32'hBBBBBBBB, 32'hBF800000, 32'hBF800000};
    #10;

    // (1, -1) => (320, 240)
    valid_in = 1;
    vertex_in = {32'hAAAAAAAA, 32'hBBBBBBBB, 32'hBF800000, 32'h3F800000};
    #10;
  
    // (1, 1) => (320, 0)
    valid_in = 1;
    vertex_in = {32'hAAAAAAAA, 32'hBBBBBBBB, 32'h3F800000, 32'h3F800000};
    #10;

    // (0, 0) => (160, 120)
    valid_in = 1;
    vertex_in = {32'hAAAAAAAA, 32'hBBBBBBBB, 32'h00000000, 32'h00000000};
    #10;

    valid_in = 0;
    #10;

    #200;

    $finish;
  end

endmodule;

`default_nettype wire
