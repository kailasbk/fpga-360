`default_nettype none
`timescale 1ns / 1ps

`include "src/util/uart_receiver.sv"

module uart_receiver_tb;

  logic clk_in;
  logic rst_in;

  logic rx_in;
  logic valid_out;
  logic [7:0] byte_out;

  uart_receiver uut (
    .clk_in,
    .rst_in,
    .rx_in,
    .valid_out,
    .byte_out
  );

  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("waveform.lxt");
    $dumpvars(3, uart_receiver_tb);
    clk_in = 0;
    rst_in = 0;
    rx_in = 1;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10;

    rx_in = 0;
    #8680;
    // first hex
    rx_in = 1;
    #8680;
    rx_in = 0;
    #8680;
    rx_in = 0;
    #8680;
    rx_in = 0;
    #8680;
    // second hex
    rx_in = 0;
    #8680;
    rx_in = 0;
    #8680;
    rx_in = 1;
    #8680;
    rx_in = 0;
    #8680;
    rx_in = 1;
    #8680;

    #100000;

    $finish;
  end

endmodule;

`default_nettype wire
