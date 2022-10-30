`default_nettype none
`timescale 1ns / 1ps

module rasterizer (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  output logic ready_out,
  input wire [3:0][31:0] vertex_in,

  output logic valid_out,
  output logic [3:0][31:0] fragment_out
);

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      valid_out <= 1'b0;
      ready_out <= 1'b1;
    end else begin
      // rasterizer logic here
    end
  end

endmodule

`default_nettype wire
