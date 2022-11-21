`timescale 1ns / 1ps
`default_nettype none

module seven_segment_controller #(
  parameter COUNT_TO = 'd100_000
) (
  input wire         clk_in,
  input wire         rst_in,
  input wire [31:0]  val_in,
  output logic [6:0] cat_out,
  output logic [7:0] an_out
);

  logic [7:0]	segment_state;
  logic [31:0]	segment_counter;
  logic [3:0]	routed_vals;
  logic [6:0]	led_out;
  logic [4:0] shift;

  assign routed_vals = val_in >> shift;

  bto7s mbto7s (.x_in(routed_vals), .s_out(led_out));
  assign cat_out = ~led_out;
  assign an_out = ~segment_state;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      shift <= 5'b0;
      segment_state <= 8'b0000_0001;
      segment_counter <= 32'b0;
    end else begin
      if (segment_counter == COUNT_TO) begin
        segment_counter <= 32'd0;
        segment_state <= {segment_state[6:0], segment_state[7]};
        shift <= shift + 4;
      end else begin
        segment_counter <= segment_counter + 1;
      end
    end
  end

endmodule // seven_segment_controller

module bto7s (
  input wire [3:0]   x_in,
  output logic [6:0] s_out
);

  // array of bits that are "one hot" with numbers 0 through 15
  // num[i] = x_in == 4'di
  logic [15:0] num;
  generate
    for (genvar i = 0; i < 16; i = i + 1) begin
      assign num[i] = x_in == 4'(i);
    end
  endgenerate
  
  // a is 0 ... g is 6
  assign s_out[0] = !(num[1] || num[4] || num[11] || num[13]);
  assign s_out[1] = !(num[5] || num[6] || num[11] || num[12] || num[14] || num[15]);
  assign s_out[2] = !(num[2] || num[12] || num[14] || num[15]);
  assign s_out[3] = !(num[1] || num[4] || num[7] || num[10] || num[15]);
  assign s_out[4] = (num[0] || num[2] || num[6] || num[8] || num[10] || num[11] || num[12] || num[13] || num[14] || num[15]);
  assign s_out[5] = !(num[1] || num[2] || num[3] || num[7] || num[13]);
  assign s_out[6] = !(num[0] || num[1] || num[7] || num[12]);

endmodule // bto7s

`default_nettype wire
