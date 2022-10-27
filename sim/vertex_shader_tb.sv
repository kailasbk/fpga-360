`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"
`include "sim/vivado.svh"

`include "src/pipe.sv"
`include "src/fp32_round.sv"
`include "src/fp32_add.sv"
`include "src/fp32_mul.sv"
`include "src/vertex_shader.sv"

module vertex_shader_tb;

  logic clk_in;
  logic rst_in;

  logic col_set_in;
  logic [3:0][31:0] col_in;

  logic valid_in;
  logic [2:0][31:0] vertex_in;

  logic valid_out;
  logic [3:0][31:0] vertex_out;

  vertex_shader uut (
    .clk_in,
    .rst_in,
    .col_set_in,
    .col_in,
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
    $dumpvars(0, vertex_shader_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10;

    // set the matrix
    col_set_in = 1;
    col_in = {32'h40C00000, 32'h3F800000, 32'h40000000, 32'h41100000}; // order: w, z, y, x
    #10;
    col_in = {32'h40400000, 32'h00000000, 32'h41100000, 32'h40C00000};
    #10;
    col_in = {32'h3F800000, 32'h40400000, 32'h3F800000, 32'h40A00000};
    #10;
    col_in = {32'h3F800000, 32'h40A00000, 32'h40E00000, 32'h00000000};
    #10;
    col_set_in = 0;
    valid_in = 1;
    vertex_in = {32'h40800000, 32'h3F800000, 32'h40A00000};
    #10;
    valid_in = 0;

    #300;

    $finish;
  end

endmodule;

`default_nettype wire
