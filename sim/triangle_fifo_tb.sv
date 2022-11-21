`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"

`include "src/ip/xilinx_dual_port_ram.v"
`include "src/graphics/triangle_fifo.sv"

module triangle_fifo_tb;

  logic clk_in;
  logic rst_in;

  logic vertex_valid_in;
  logic [3:0][31:0] vertex_in;
  logic color_valid_in;
  logic [11:0] color_in;

  logic valid_out;
  logic ready_in;
  logic [3:0][31:0] vertex_out;
  logic [11:0] color_out;

  triangle_fifo uut (
    .clk_in,
    .rst_in,

    .vertex_valid_in,
    .vertex_in,
    .color_valid_in,
    .color_in,

    .valid_out,
    .ready_in,
    .vertex_out,
    .color_out
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.lxt");
    $dumpvars(3, triangle_fifo_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10;

    ready_in = 1;
    vertex_valid_in = 1;
    vertex_in = {32'hAAAAAAAA, 32'h3F000000, 32'h42200000, 32'h43200000};
    #10;

    vertex_valid_in = 0;
    #100;

    $finish;
  end

endmodule;

`default_nettype wire
