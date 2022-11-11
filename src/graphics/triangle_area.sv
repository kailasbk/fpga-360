`default_nettype none
`timescale 1ns / 1ps

module triangle_area (
  input wire clk_in,

  input wire [2:0][1:0][16:0] vertices_in,

  output logic negative_out,
  output logic [33:0] area_out
);

  logic [33:0] products [6];
  logic signed [34:0] differences [3];
  logic signed [34:0] signed_area;

  logic [16:0] x0, x1, x2;
  logic [16:0] y0, y1, y2;
  assign x0 = vertices_in[0][0];
  assign y0 = vertices_in[0][1];
  assign x1 = vertices_in[1][0];
  assign y1 = vertices_in[1][1];
  assign x2 = vertices_in[2][0];
  assign y2 = vertices_in[2][1];

  // formula for the area taken from OpenGL 4.6 Chapter 14.6.1.
  // (0, 0) is the top left, counter-clockwise yields positive area

  always_ff @(posedge clk_in) begin
    products[0] <= x0 * y1;
    products[1] <= x1 * y0;
    products[2] <= x1 * y2;
    products[3] <= x2 * y1;
    products[4] <= x2 * y0;
    products[5] <= x0 * y2;

    differences[0] <= $signed({1'b0, products[1]}) - $signed({1'b0, products[0]});
    differences[1] <= $signed({1'b0, products[3]}) - $signed({1'b0, products[2]});
    differences[2] <= $signed({1'b0, products[5]}) - $signed({1'b0, products[4]});

    signed_area <= differences[0] + differences[1] + differences[2];

    if (signed_area[34]) begin
      negative_out <= 1'b1;
      area_out <= (~signed_area[33:0]) + 1;
    end else begin
      negative_out <= 1'b0;
      area_out <= signed_area[33:0];
    end
  end

endmodule

`default_nettype wire
