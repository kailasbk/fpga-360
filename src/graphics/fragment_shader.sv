`default_nettype none
`timescale 1ns / 1ps

module fragment_shader (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [15:0] triangle_id_in,
  input wire [2:0][16:0] fragment_in,
  input wire [11:0] material_in,

  output logic valid_out,
  output logic [8:0] x_out,
  output logic [7:0] y_out,
  output logic [15:0] z_out,
  output logic [11:0] rgb_out
);

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      valid_out <= 1'b0;
    end else if (valid_in) begin
      valid_out <= 1'b1;
      x_out <= fragment_in[0][16:8];
      y_out <= fragment_in[1][15:8];
      z_out <= fragment_in[2][16:1];
      rgb_out <= material_in;
    end else begin
      valid_out <= 1'b0;
    end
  end

endmodule

`default_nettype wire
