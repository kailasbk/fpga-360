`default_nettype none
`timescale 1ns / 1ps

`include "src/ip/xilinx_single_port_ram.v"
`include "src/graphics/model_memory.sv"

module uart (
  input wire clk_in,
  input wire rst_in,
  input wire rx_in,
  output logic tx_out,
  input wire valid_in,
  input wire [7:0] byte_in,
  output logic valid_out,
  output logic [7:0] byte_out
);

  initial begin
    #100;

    byte_out <= 8'hAB;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'hCD;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'hEF;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'h01;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'h23;
    valid_out <= 1'b1;
    #10;
    valid_out <= 1'b0;
    #10;

    byte_out <= 8'hFF;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'hFF;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'hFF;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'hFF;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'hFF;
    valid_out <= 1'b1;
    #10;
    valid_out <= 1'b0;
    #10;

    byte_out <= 8'h3F;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'h13;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'hCD;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'h3A;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'h3F;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'h13;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'hCD;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'h4D;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'h3F;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'h13;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'hCD;
    valid_out <= 1'b1;
    #10;
    byte_out <= 8'h5E;
    valid_out <= 1'b1;
    #10;
    valid_out <= 1'b0;
    #10;
  end

endmodule

module model_memory_tb;

  logic clk_in;
  logic rst_in;

  logic rx_in;

  model_memory uut (
    .clk_in,
    .rst_in,
    .rx_in
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.lxt");
    $dumpvars(3, model_memory_tb);
    clk_in = 0;
    rst_in = 0;
    rx_in = 1;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10;

    #100000;

    $finish;
  end

endmodule;

`default_nettype wire
