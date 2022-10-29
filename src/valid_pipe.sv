`timescale 1ns / 1ps
`default_nettype none

module valid_pipe #(
  parameter LATENCY = 1
) (
  input wire clk_in,
  input wire rst_in,
  input wire valid_in,
  output logic valid_out
);

  logic buffer [LATENCY];

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      for (int i = 0; i < LATENCY; i = i + 1) begin
        buffer[i] <= 1'b0;
      end
    end else begin
      buffer[0] <= valid_in;
      for (int i = 1; i < LATENCY; i = i + 1) begin
        buffer[i] <= buffer[i-1];
      end
    end
  end

  assign valid_out = buffer[LATENCY-1];

endmodule

`default_nettype wire
