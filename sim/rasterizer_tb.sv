`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"

`include "src/util/pipe.sv"
`include "src/util/valid_pipe.sv"
`include "src/util/fixed_divide.sv"
`include "src/graphics/triangle_area.sv"
`include "src/graphics/barycentric.sv"
`include "src/graphics/rasterizer.sv"

module rasterizer_tb;

  logic clk_in;
  logic rst_in;

  logic valid_in;
  logic [3:0][31:0] vertex_in;

  logic valid_out;
  logic [15:0] triangle_id_out;
  logic [2:0][16:0] fragment_out;

  rasterizer uut (
    .clk_in,
    .rst_in,
    .valid_in,
    .vertex_in,
    .valid_out,
    .triangle_id_out,
    .fragment_out
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(3, rasterizer_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    valid_in = 0;
    #10;

    valid_in = 1;
    vertex_in = {32'hAAAAAAAA, 32'h3F000000, 32'h42200000, 32'h43200000}; // (160, 40)
    #10;
    valid_in = 0;
    #20;

    valid_in = 1;
    vertex_in = {32'hAAAAAAAA, 32'hBBBBBBBB, 32'h42A00000, 32'h42C80000}; // (100, 80)
    #10;
    valid_in = 0;
    #20;

    valid_in = 1;
    vertex_in = {32'hAAAAAAAA, 32'hBBBBBBBB, 32'h42C80000, 32'h43480000}; // (200, 100)
    #10;
    valid_in = 0;
    #10;

    #1000000;

    $finish;
  end

endmodule;

`default_nettype wire
