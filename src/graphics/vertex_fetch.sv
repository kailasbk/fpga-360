`default_nettype none
`timescale 1ns / 1ps

module vertex_fetch (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire restart_in,

  output logic valid_out,
  output logic [2:0][31:0] vertex_out
);

  valid_pipe #(
    .LATENCY(4)
  ) valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in(valid_in && !restart_in),
    .valid_out
  );

  logic [9:0] index_id;
  always_ff @(posedge clk_in) begin
    if (rst_in || restart_in) begin
      index_id <= 10'b0;
    end else begin
      if (valid_in) begin
        index_id <= index_id + 1;
      end
    end
  end

  logic [9:0] vertex_id;
  // assign to output of first bram

  // feed vertex_id into second bram
  // assign vertex_out to output of second bram

endmodule

`default_nettype wire
