`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"
`include "sim/vivado.svh"

`include "src/util/pipe.sv"
`include "src/util/valid_pipe.sv"
`include "src/fp/fp32_bound.sv"
`include "src/graphics/triangle_clip.sv"

module triangle_clip_tb;

  logic clk_in;
  logic rst_in;

  logic valid_in;
  logic [3:0][31:0] vertex_in;

  logic valid_out;
  logic [3:0][31:0] vertex_out;

  triangle_clip uut (
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
    $dumpvars(3, triangle_clip_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    valid_in = 0;
    #10;

    valid_in = 1;
    // vertex = {w, z, y, x};
    vertex_in = {32'h3F800000, 32'h3F687FCC, 32'h3E5C28F6, 32'h3F25E354};
    #10;
    vertex_in = {32'h3F800000, 32'hBDF3B646, 32'h3F7B22D1, 32'hBEFEF9DB};
    #10;
    valid_in = 0;
    #10;
    valid_in = 1;
    vertex_in = {32'h3F800000, 32'h3F7F837B, 32'hBE6147AE, 32'h3EFB7E91};
    #10;

    valid_in = 1;
    vertex_in = {32'h3F800000, 32'h3F687FCC, 32'h3E5C28F6, 32'h3F25E354};
    #10;
    vertex_in = {32'h3F800000, 32'h41BBEB85, 32'h3E5C28F6, 32'h3F25E354};
    #10;
    vertex_in = {32'h3F800000, 32'h3F7F837B, 32'hBE6147AE, 32'h3EFB7E91};
    #10;

    valid_in = 1;
    vertex_in = {32'h3F800000, 32'hBDF3B646, 32'h3F7B22D1, 32'hBEFEF9DB};
    #10;
    vertex_in = {32'h3F800000, 32'hBDF3B646, 32'hC104C49C, 32'hBEFEF9DB};
    #10;
    vertex_in = {32'h3F800000, 32'h3F7F837B, 32'hBE6147AE, 32'h3EFB7E91};
    #10;

    valid_in = 1;
    vertex_in = {32'h3F800000, 32'h3F687FCC, 32'h3E5C28F6, 32'h3F25E354};
    #10;
    vertex_in = {32'h3F800000, 32'hBDF3B646, 32'h3F7B22D1, 32'hBEFEF9DB};
    #10;
    vertex_in = {32'h3F800000, 32'h3F7F837B, 32'hBE6147AE, 32'h3EFB7E91};
    #10;
    vertex_in = {32'h3F800000, 32'h3F687FCC, 32'h3E5C28F6, 32'h3F25E354};
    #10;
    vertex_in = {32'h3F800000, 32'hBDF3B646, 32'h3F7B22D1, 32'hBEFEF9DB};
    #10;
    vertex_in = {32'h3F800000, 32'h3F7F837B, 32'hBE6147AE, 32'h3EFB7E91};
    #10;
    valid_in = 0;
    #10;

    #100;

    $finish;
  end

endmodule;

`default_nettype wire
