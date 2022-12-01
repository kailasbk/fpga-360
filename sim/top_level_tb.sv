`default_nettype none
`timescale 1ns / 1ps

`include "sim/testing.svh"
`include "sim/ip/blk_mem_gen_v8_4.v"
`include "sim/ip/frame_ram.v"
`include "sim/ip/depth_ram.v"
`include "sim/ip/clk_wiz.v"
`include "src/ip/xilinx_single_port_ram.v"
`include "src/ip/xilinx_dual_port_ram.v"
`include "src/ip/debouncer.sv"

`include "src/util/pipe.sv"
`include "src/util/valid_pipe.sv"
`include "src/util/fixed_divide.sv"
`include "src/util/addsub.sv"
`include "src/util/seven_segment_controller.sv"

`include "src/fp/fp32_bound.sv"
`include "src/fp/fp32_round.sv"
`include "src/fp/fp32_add.sv"
`include "src/fp/fp32_mul.sv"
`include "src/fp/fp32_dot.sv"
`include "src/fp/fp32_scale.sv"
`include "src/fp/fp32_div.sv"

`include "src/control/btn_ctrl.sv"
`include "src/control/direction_vector.sv"
`include "src/control/sine_table.sv"
`include "src/control/yaw_pitch_ctrl.sv"

`include "src/graphics/triangle_area.sv"
`include "src/graphics/barycentric.sv"
`include "src/graphics/rasterizer.sv"
`include "src/graphics/vga.sv"
`include "src/graphics/framebuffer.sv"
`include "src/graphics/fragment_shader.sv"
`include "src/graphics/perspective_divide.sv"
`include "src/graphics/triangle_clip.sv"
`include "src/graphics/triangle_fifo.sv"
`include "src/graphics/vertex_fetch.sv"
`include "src/graphics/matrix_gen.sv"
`include "src/graphics/vertex_shader.sv"
`include "src/graphics/viewport_transform.sv"

`include "src/top_level.sv"

module top_level_tb;

  logic clk_in;
  logic rst_in;

  logic [15:0] sw;
  assign sw[15] = rst_in;
  assign sw[14:0] = 15'b0;
  logic [15:0] led;

  logic hsync_out;
  logic vsync_out;
  logic [11:0] rgb_out;

  top_level uut (
    .clk_in,
    .sw({rst_in, 15'b0}),
    .btnc(1'b0), .btnu(1'b0), .btnl(1'b0), .btnr(1'b0), .btnd(1'b0),
    .led,
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
