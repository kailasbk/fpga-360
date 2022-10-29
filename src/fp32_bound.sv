`default_nettype none
`timescale 1ns / 1ps

module fp32_bound (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [31:0] a_in,
  input wire [31:0] b_in,

  output logic valid_out,
  output logic c_out
);

  valid_pipe #(
    .LATENCY(1)
  ) valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in,
    .valid_out
  );

  always_ff @(posedge clk_in) begin
    c_out <= a_in[30:0] <= b_in[30:0];
  end

endmodule

`default_nettype wire
