`default_nettype none
`timescale 1ns / 1ps

module triangle_fifo (
  input wire clk_in,
  input wire rst_in,

  input wire vertex_valid_in,
  input wire [3:0][31:0] vertex_in,
  input wire color_valid_in,
  input wire [11:0] color_in,

  output logic valid_out,
  input wire ready_in,
  output logic [3:0][31:0] vertex_out,
  output logic [11:0] color_out
);

  logic [9:0] vertex_write_ptr;
  logic [9:0] color_write_ptr;
  logic [9:0] read_ptr;

  logic non_empty;
  assign non_empty = (vertex_write_ptr != read_ptr) && (color_write_ptr != read_ptr);
  logic read_valid;
  logic lock;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      vertex_write_ptr <= 10'd0;
      color_write_ptr <= 10'd0;
      read_ptr <= 10'd0;
      lock <= 1'b0;
      read_valid <= 1'b0;
      valid_out <= 1'b0;
    end else begin
      if (vertex_valid_in) begin
        // TODO: add overflow logic
        vertex_write_ptr <= vertex_write_ptr + 1;
      end

      if (color_valid_in) begin
        // TODO: add overflow logic
        color_write_ptr <= color_write_ptr + 1;
      end

      if (lock) begin
	      if (valid_out && ready_in) begin
          // read from next ifo value
	        read_ptr <= read_ptr + 1;
	        lock <= 1'b0;
          valid_out <= 1'b0;
	      end else begin
	        valid_out <= 1'b1;
	      end
      end else if (non_empty && !lock) begin
        // lock until value consumed
        lock <= 1'b1;
      end
    end
  end

  xilinx_dual_port_ram #(
    .RAM_WIDTH(128),
    .RAM_DEPTH(1024)
  ) vertex_ram (
    .addra(vertex_write_ptr),
    .addrb(read_ptr),
    .dina(vertex_in),
    .dinb(),
    .clka(clk_in),
    .wea(vertex_valid_in),
    .web(1'b0),
    .ena(1'b1),
    .enb(1'b1),
    .rsta(1'b0),
    .rstb(1'b0),
    .regcea(1'b1),
    .regceb(1'b1),
    .douta(),
    .doutb(vertex_out)
  );

  xilinx_dual_port_ram #(
    .RAM_WIDTH(12),
    .RAM_DEPTH(1024)
  ) color_ram (
    .addra(color_write_ptr),
    .addrb(read_ptr),
    .dina(color_in),
    .dinb(),
    .clka(clk_in),
    .wea(color_valid_in),
    .web(1'b0),
    .ena(1'b1),
    .enb(1'b1),
    .rsta(1'b0),
    .rstb(1'b0),
    .regcea(1'b1),
    .regceb(1'b1),
    .douta(),
    .doutb(color_out)
  );

endmodule

`default_nettype wire
