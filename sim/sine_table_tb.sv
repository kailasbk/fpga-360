`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module sine_table_tb;

    //make logics for inputs and outputs!
    logic clk;
    logic rst;
    logic [11:0] index;
    logic [31:0] sine_data;

    logic [31:0] total;
    logic [15:0] x;
    logic [15:0] y;

    sine_table #(
      .BRAM_DEPTH(1024), //2^12 total sine table entries for all 4 quadrants
      .BRAM_WIDTH(32),    //16-bit signed fixed-point data output
      .BRAM_FILE(`FPATH(sine_1024e_32b.mem))
      ) uut (
      .rst_in(rst), .clk_in(clk), .id(index), .data(sine_data)
      );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk = !clk;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("sine_table_tb.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,sine_table_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk = 1; //initialize clk (super important)
        rst = 0; //initialize rst (super important)
        index = 0;
        #10  //wait a little bit of time at beginning
        rst = 1; //reset system
        #10; //hold high for a few clock cycles
        rst = 0;
        #10;
        for (index = 0; index<4095; index = index + 1)begin
          #10;
          $display("index=%4d sine_data=%32h", index, sine_data); //print nice message with index and sine value
        end
        // index = 1024;
        // #10
        // index = 2048;
        // #10
        // index = 3072;
        // #10
        // index = 4095;

        //x = 16'b1010_0000_1010_0000; //32 bit multiplation testcase (no latency, hmmmmm)
        //y = 16'b1010_0000_1010_0000;
        //#300;
        $display("Finishing Sim"); //print nice message
        $finish;

    end

    //assign total = x * y;
endmodule //sine_table_tb

`default_nettype wire
