`default_nettype none
`timescale 1ns / 1ps

module uart (
  input wire clk_in,
  input wire rst_in,
  input wire rx_in,
  output logic tx_out,
  input wire valid_in,
  input wire [7:0] byte_in,
  output logic valid_out,
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

  logic rx_clk, tx_clk;
  logic [9:0] rx_clk_counter, tx_clk_counter;
  logic rx_clk_last, tx_clk_last;
  logic rx_idle, tx_idle;
  logic [3:0] rx_bit_count, tx_bit_count;
  logic [8:0] rx_data;
  logic [7:0] tx_byte;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      valid_out <= 1'b0;
      rx_idle <= 1'b1;
      tx_idle <= 1'b1;
      tx_out <= 1'b1;
    end else if (rx_idle) begin
      valid_out <= 1'b0;
      if (!rx) begin
        // start the uart clock
        rx_clk_last <= 1'b0;
        rx_clk <= 1'b0;
        rx_clk_counter <= 10'd0;

        rx_data <= 9'd0;
        rx_bit_count <= 4'd0;
        rx_idle <= 1'b0;
      end
    end else begin
      // on the rising edge of the uart clock, in the middle of the bit
      if (rx_clk && !rx_clk_last) begin
        rx_bit_count <= rx_bit_count + 1;
        if (rx_bit_count == 4'd9) begin
          valid_out <= 1'b1;
          byte_out <= rx_data[8:1];
          rx_idle <= 1'b1;
        end else begin
          rx_data <= {rx, rx_data[8:1]};
        end
      end

      // update the uart clock
      rx_clk_last <= rx_clk;
      if (rx_clk_counter == 10'd433) begin
        rx_clk_counter <= 10'd0;
        rx_clk <= !rx_clk;
      end else rx_clk_counter <= rx_clk_counter + 1;
    end

    // echo the byte received back to client
    if (tx_idle) begin
      if (valid_in) begin
        tx_byte <= byte_in;
        tx_bit_count <= 4'd0;
        tx_idle <= 1'b0;
        tx_out <= 1'b0;

        tx_clk_last <= 1'b1;
        tx_clk <= 1'b1;
        tx_clk_counter <= 10'd0;
      end
    end else begin
      // on the rising edge of the uart clock, in the middle of the bit
      if (tx_clk && !tx_clk_last) begin
        tx_bit_count <= tx_bit_count + 1;
        if (tx_bit_count == 4'd8) begin
          tx_idle <= 1'b1;
          tx_out <= 1'b1;
        end else begin
          tx_out <= tx_byte[0];
          tx_byte <= tx_byte >> 1;
        end
      end

      // update the uart clock
      tx_clk_last <= tx_clk;
      if (tx_clk_counter == 10'd433) begin
        tx_clk_counter <= 10'd0;
        tx_clk <= !tx_clk;
      end else tx_clk_counter <= tx_clk_counter + 1;
    end
  end

endmodule

`default_nettype wire
