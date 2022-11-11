`default_nettype none
`timescale 1ns / 1ps

module top_level (
  input wire clk_in,

  input wire [15:0] sw,
  // other inputs go here
  output logic [15:0] led,

  output logic hsync_out,
  output logic vsync_out,
  output logic [11:0] rgb_out
);

  logic gpu_clk;
  logic vga_clk;
  clk_wiz clk_wiz (
    .clk_in1(clk_in),
    .clk_out1(gpu_clk),
    .clk_out2(vga_clk)
  );

  logic rst_in;
  assign rst_in = sw[15];

  logic clear_in;
  logic switch_in;
  logic valid_in;
  logic [8:0] x_in;
  logic [7:0] y_in;
  logic [7:0] z_in;
  logic [11:0] rgb_in;
  logic [21:0] counter;
  always_ff @(posedge gpu_clk) begin
    if (rst_in) begin
      valid_in <= 1'b0;
      x_in <= 9'd0;
      y_in <= 8'd0;
      z_in <= 8'd0;
      rgb_in <= 12'h000;
      counter <= 22'd0;
    end else begin
      if (x_in == 9'd319) begin
        x_in <= 9'd0;
      end else x_in <= x_in + 1;

      if (y_in == 8'd239) begin
        y_in <= 8'd0;
      end else y_in <= y_in + 1;

      valid_in <= sw[0];
      z_in <= 8'b0;
      rgb_in <= {sw[12], 3'b0, sw[11], 3'b0, sw[10], 3'b0};

      if (counter == 22'd3333333) begin
        counter <= 22'd0;
        switch_in <= 1'b1;
        clear_in <= 1'b1;
      end else begin
        counter <= counter + 1;
        switch_in <= 1'b0;
        clear_in <= 1'b0;
      end
    end
  end

  assign led[15] = rst_in;
  assign led[14] = clear_in;
  assign led[13] = switch_in;
  assign led[12:1] = rgb_in;
  assign led[0] = valid_in;

  framebuffer framebuffer (
    .gpu_clk_in(gpu_clk),
    .vga_clk_in(vga_clk),
    .rst_in,
    .clear_in,
    .switch_in,

    .valid_in,
    .x_in,
    .y_in,
    .z_in,
    .rgb_in,

    .hsync_out,
    .vsync_out,
    .rgb_out
  );

endmodule

`default_nettype wire
