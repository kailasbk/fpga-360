`default_nettype none
`timescale 1ns / 1ps

module vga (
  input wire clk_in,
  input wire rst_in,
  output logic [9:0] hcount_out,
  output logic [9:0] vcount_out,
  output logic vsync_out,
  output logic hsync_out,
  output logic blank_out
);

  parameter H_SIZE = 640;
  parameter H_FP = 16;
  parameter H_SYNC_PULSE = 96;
  parameter H_BP = 48;

  parameter V_SIZE = 480;
  parameter V_FP = 10;
  parameter V_SYNC_PULSE = 2;
  parameter V_BP = 33;

  logic hblank;
  logic vblank;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      hcount_out <= 10'd0;
      vcount_out <= 10'd0;
      hblank <= 1'b0;
      vblank <= 1'b0;
      hsync_out <= 1'b1;
      vsync_out <= 1'b1;
    end else begin
      case (hcount_out)
        H_SIZE - 1: begin
          hblank <= 1'b1;
          hcount_out <= hcount_out + 1;
        end
        H_SIZE + H_FP - 1: begin
          hsync_out <= 1'b0;
          hcount_out <= hcount_out + 1;
        end
        H_SIZE + H_FP + H_SYNC_PULSE - 1: begin
          hsync_out <= 1'b1;
          hcount_out <= hcount_out + 1;
        end
        H_SIZE + H_FP + H_SYNC_PULSE + H_BP - 1: begin
          hblank <= 1'b0;
          hcount_out <= 10'd0;
        end
        default: begin
          hcount_out <= hcount_out + 1;
        end
      endcase
      if (hcount_out == H_SIZE + H_FP + H_SYNC_PULSE + H_BP - 1) case (vcount_out)
        V_SIZE - 1: begin
          vblank <= 1'b1;
          vcount_out <= vcount_out + 1;
        end
        V_SIZE + V_FP - 1: begin
          vsync_out <= 1'b0;
          vcount_out <= vcount_out + 1;
        end
        V_SIZE + V_FP + V_SYNC_PULSE - 1: begin
          vsync_out <= 1'b1;
          vcount_out <= vcount_out + 1;
        end
        V_SIZE + V_FP + V_SYNC_PULSE + V_BP - 1: begin
          vblank <= 1'b0;
          vcount_out <= 10'd0;
        end
        default: begin
          vcount_out <= vcount_out + 1;
        end
      endcase
    end
  end

  assign blank_out = hblank || vblank;

endmodule

`default_nettype wire
