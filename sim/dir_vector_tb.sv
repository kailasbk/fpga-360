`timescale 1ns / 1ps
`default_nettype none

module dir_vector_tb;

    //make logics for inputs and outputs!
    logic clk;
    logic rst;

    logic [11:0] yaw;
    logic [11:0] pitch;

    logic [2:0][31:0] x;
    logic [2:0][31:0] y;
    logic [2:0][31:0] z;

    dir_vector vector (
        .rst(rst), .clk(clk), .yaw(yaw), .pitch(pitch), .x(x), .y(y), .z(z)
        );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk = !clk;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("dir_vector_tb.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,dir_vector_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk = 1; //initialize clk (super important)
        rst = 0; //initialize rst (super important)
        #10  //wait a little bit of time at beginning
        rst = 1; //reset system
        #10; //hold high for a few clock cycles
        rst = 0;
        #10;
        yaw = 12'b0010_1100_0101;
        pitch = 12'b1111_0101_0111;
        #10;
        yaw = 12'b0000_0000_0000;
        pitch = 12'b0011_0101_0111;
        #10;
        yaw = 12'b0010_1100_0101;
        pitch = 12'b0000_0101_0111;
        #100;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //sine_table_tb

`default_nettype wire
