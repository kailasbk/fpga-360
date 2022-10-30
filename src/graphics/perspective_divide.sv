`default_nettype none
`timescale 1ns / 1ps

module perspective_divide (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [3:0][31:0] vertex_in,

  output logic valid_out,
  output logic [3:0][31:0] vertex_out
);

  valid_pipe #(
    .LATENCY(1)
  ) valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in,
    .valid_out
  );

  // placeholder
  always_ff @(posedge clk_in) begin
    vertex_out <= vertex_in;
  end

endmodule

`default_nettype wire
