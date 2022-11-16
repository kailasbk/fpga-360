`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"
`include "sim/ip/blk_mem_gen_v8_4.v"
`include "sim/ip/frame_ram.v"
`include "sim/ip/depth_ram.v"
`include "sim/ip/clk_wiz.v"

`include "src/util/pipe.sv"
`include "src/util/valid_pipe.sv"
`include "src/util/fixed_divide.sv"
`include "src/graphics/triangle_area.sv"
`include "src/graphics/barycentric.sv"
`include "src/graphics/rasterizer.sv"
`include "src/graphics/vga.sv"
`include "src/graphics/framebuffer.sv"
`include "src/graphics/fragment_shader.sv"
`include "src/top_level.sv"

module top_level_tb;

  logic clk_in;
  logic rst_in;

  logic hsync_out;
  logic vsync_out;
  logic [11:0] rgb_out;

  top_level uut (
    .clk_in,
    .sw({rst_in, 15'b0}),
    .hsync_out,
    .vsync_out,
    .rgb_out
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.lxt");
    $dumpvars(3, top_level_tb);
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #50;
    rst_in = 0;
    #10;

    #80000000;

    $finish;
  end

endmodule;

`default_nettype wire
