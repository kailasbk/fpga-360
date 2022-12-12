`default_nettype none
`timescale 1ns / 1ps

module uart_receiver (
  input wire clk_in,
  input wire rst_in,
  input wire rx_in,
  output logic valid_out,
  output logic [15:0] debug_data_out,
  output logic [7:0] byte_out
);

  logic rx, rx1;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      rx1 <= 1'b1;
      rx <= 1'b1;
    end else begin
      rx1 <= rx_in;
      rx <= rx1;
    end
  end

  logic uart_clk;
  logic [9:0] uart_clk_counter;
  logic uart_clk_last;
  logic idle;
  logic [3:0] bit_count;
  logic [9:0] data;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      valid_out <= 1'b0;
      idle <= 1'b1;
      debug_data_out <= 16'b0;
    end else if (idle) begin
      valid_out <= 1'b0;
      if (!rx) begin
        // start the uart clock
        uart_clk_last <= 1'b0;
        uart_clk <= 1'b0;
        uart_clk_counter <= 10'd0;

        bit_count <= 0;
        idle <= 1'b0;
      end
    end else begin
      // on the rising edge of the uart clock, in the middle of the bit
      if (uart_clk && !uart_clk_last) begin
        bit_count <= bit_count + 1;
        data <= {rx, data[9:1]};
        debug_data_out <= {debug_data_out, rx};
        if (bit_count == 4'd9) begin
          valid_out <= 1'b1;
          idle <= 1'b1;
        end
      end

      // update the uart clock
      uart_clk_last <= uart_clk;
      if (uart_clk_counter == 10'd433) begin
        uart_clk_counter <= 10'd0;
        uart_clk <= !uart_clk;
      end else uart_clk_counter <= uart_clk_counter + 1;
    end
  end

  assign byte_out = data[8:1];

endmodule

`default_nettype wire
