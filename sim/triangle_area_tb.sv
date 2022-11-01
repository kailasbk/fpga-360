`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"

`include "src/util/valid_pipe.sv"
`include "src/graphics/triangle_area.sv"

module triangle_area_tb;

  logic clk_in;
  logic rst_in;

  logic valid_in;
  logic [2:0][1:0][16:0] vertices_in;

  logic valid_out;
  logic negative_out;
  logic [33:0] area_out;

  triangle_area uut (
    .clk_in,
    .rst_in,
    .valid_in,
    .vertices_in,
    .valid_out,
    .negative_out,
    .area_out
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(3, triangle_area_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    valid_in = 0;
    #10;

    valid_in = 1;
    vertices_in[0] = {17'h004_00, 17'h060_00}; // (96, 4)
    vertices_in[1] = {17'h053_00, 17'h000_00}; // (0, 83)
    vertices_in[2] = {17'h053_00, 17'h0C0_00}; // (192, 83)
    // area = 7584 = 0_1DA0_0000
    #10;
    vertices_in[0] = {17'h04B_E0, 17'h01E_00}; // (30, 75.875)
    vertices_in[1] = {17'h00D_80, 17'h003_C0}; // (3.75, 13.5)
    vertices_in[2] = {17'h03C_20, 17'h003_C0}; // (3.75, 60.125)
    // area = 611.953125 = 0_0263_F400
    #10;
    valid_in = 0;

    #100;

    $finish;
  end

endmodule;

`default_nettype wire
