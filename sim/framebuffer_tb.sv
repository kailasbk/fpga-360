`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"
`include "sim/ip/blk_mem_gen_v8_4.v"
`include "sim/ip/frame_ram.v"
`include "sim/ip/depth_ram.v"

`include "src/util/pipe.sv"
`include "src/util/valid_pipe.sv"
`include "src/graphics/vga.sv"
`include "src/graphics/framebuffer.sv"

module framebuffer_tb;

  logic gpu_clk_in;
  logic vga_clk_in;
  logic rst_in;

  logic clear_in;
  logic switch_in;
  logic valid_in;
  logic [8:0] x_in;
  logic [7:0] y_in;
  logic [7:0] z_in;
  logic [11:0] rgb_in;

  logic hsync_out;
  logic vsync_out;
  logic [11:0] rgb_out;

  framebuffer uut (
    .gpu_clk_in,
    .vga_clk_in,
    .rst_in,
    .clear_in,
    .switch_in,
    .valid_in,
    .x_in,
    .y_in,
    .z_in,
    .rgb_in,
    .hsync_out,
    .vsync_out,
    .rgb_out
  );

  always begin
    #5;
    gpu_clk_in = !gpu_clk_in;
  end

  always begin
    #20;
    vga_clk_in = !vga_clk_in;
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(3, framebuffer_tb);
    gpu_clk_in = 0;
    vga_clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #50;
    rst_in = 0;
    valid_in = 0;
    clear_in = 0;
    switch_in = 0;
    #10;

    #1000000;

    for (int j = 0; j < 240; j = j + 1) begin
      for (int i = 0; i < 320; i = i + 1) begin
        valid_in = 1;
        x_in = i;
        y_in = j;
        z_in = 8'b0;
        rgb_in = (j * 320) + i;
        #10;
      end
    end
    valid_in = 0;
    #10;

    switch_in = 1;
    #10;
    switch_in = 0;
    #10;

    #30000000;

    $finish;
  end

endmodule;

`default_nettype wire
