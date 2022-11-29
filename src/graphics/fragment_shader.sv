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

  logic [11:0] materials [8];
  assign materials[0] = 12'h000;
  assign materials[1] = 12'hF00;
  assign materials[2] = 12'h0F0;
  assign materials[3] = 12'h00F;
  assign materials[4] = 12'hFF0;
  assign materials[5] = 12'h0FF;
  assign materials[6] = 12'hF0F;
  assign materials[7] = 12'hFFF;

  valid_pipe #(
    .LATENCY(1)
  ) valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in,
    .valid_out
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      // nothing
    end else if (valid_in) begin
      x_out <= fragment_in[0][16:8];
      y_out <= fragment_in[1][15:8];
      z_out <= fragment_in[2][16:1];
      rgb_out <= materials[material_in[2:0]];
    end
  end

endmodule

`default_nettype wire
