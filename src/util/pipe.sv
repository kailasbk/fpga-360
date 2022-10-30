`timescale 1ns / 1ps
`default_nettype none

module pipe #(
  parameter LATENCY = 1,
  parameter WIDTH = 1
) (
  input wire clk_in,
  input wire [WIDTH-1:0] data_in,
  output logic [WIDTH-1:0] data_out
);

  logic [WIDTH-1:0] buffer [LATENCY];

  always_ff @(posedge clk_in) begin
    buffer[0] <= data_in;
    for (int i = 1; i < LATENCY; i = i + 1) begin
      buffer[i] <= buffer[i-1];
    end
  end

  assign data_out = buffer[LATENCY-1];

endmodule

`default_nettype wire
