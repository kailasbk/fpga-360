`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"

`include "src/util/pipe.sv"
`include "src/util/valid_pipe.sv"
`include "src/ip/xilinx_single_port_ram.v"
`include "src/graphics/vertex_fetch.sv"

module vertex_fetch_tb;

  logic clk_in;
  logic rst_in;

  logic valid_out;
  logic [15:0] vertex_id_out;
  logic [2:0][31:0] vertex_out;
  logic [11:0] color_out;

  vertex_fetch uut (
    .clk_in,
    .rst_in,
    .valid_out,
    .vertex_id_out,
    .vertex_out,
    .color_out
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.lxt");
    $dumpvars(3, vertex_fetch_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10;

    #100;

    $finish;
  end

endmodule;

`default_nettype wire

