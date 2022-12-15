`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module sine_table_7_seg_tb;

    //make logics for inputs and outputs!
    logic clk;
    logic rst;
    logic [31:0] sine_data;

    logic [15:0] btn_count;

    logic btn_pulse;

    logic ca, cb, cc, cd, ce, cf, cg;
    logic [7:0] an;
    logic [15:0] led;

    simple_counter msc( .clk_in(clk),
                        .rst_in(rst),
                        .evt_in(btn_pulse),
                        .count_out(btn_count));

    sine_table #(
      .BRAM_DEPTH(1024), //2^12 total sine table entries for all 4 quadrants
      .BRAM_WIDTH(16),    //32-bit signed fixed-point data output
      .BRAM_FILE(`FPATH(sine_1024e_16b.mem))
      ) uut (
      .rst_in(rst), .clk_in(clk), .id(btn_count[11:0]), .data(sine_data)
      );

    seven_segment_controller mssc(.clk_in(clk),
                                  .rst_in(rst),
                                  .val_in(sine_data),
                                  .cat_out({cg, cf, ce, cd, cc, cb, ca}),
                                  .an_out(an));

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk = !clk;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("sine_table_7_tb.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,sine_table_7_seg_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk = 1; //initialize clk (super important)
        rst = 0; //initialize rst (super important)
        btn_pulse = 0;
        #10  //wait a little bit of time at beginning
        rst = 1; //reset system
        #10; //hold high for a few clock cycles
        rst = 0;
        #10;
        btn_pulse = 1;
        #10
        btn_pulse = 0;
        #300;
        btn_pulse = 1;
        #10
        btn_pulse = 0;
        #100;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //sine_table_7_seg_tb

`default_nettype wire
