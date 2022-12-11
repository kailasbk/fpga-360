`default_nettype none
`timescale 1ns / 1ps

module triangle_fifo (
  input wire clk_in,
  input wire rst_in,

  input wire position_valid_in,
  input wire [3:0][31:0] position_in,
  input wire normal_valid_in,
  input wire [11:0] normal_in,
  input wire material_valid_in,
  input wire [11:0] material_in,

  output logic valid_out,
  input wire ready_in,
  output logic [3:0][31:0] position_out,
  output logic [11:0] normal_out,
  output logic [11:0] material_out
);

  logic [11:0] position_write_ptr;
  logic [11:0] normal_write_ptr;
  logic [11:0] material_write_ptr;
  logic [11:0] read_ptr;

  logic non_empty;
  assign non_empty = (position_write_ptr != read_ptr) && (normal_write_ptr != read_ptr) && (material_write_ptr != read_ptr);
  logic read_valid;
  logic lock;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      position_write_ptr <= 12'd0;
      normal_write_ptr <= 12'd0;
      material_write_ptr <= 12'd0;
      read_ptr <= 12'd0;
      lock <= 1'b0;
      read_valid <= 1'b0;
      valid_out <= 1'b0;
    end else begin
      if (position_valid_in) begin
        // TODO: add overflow logic
        position_write_ptr <= position_write_ptr + 1;
      end

      if (normal_valid_in) begin
        // TODO: add overflow logic
        normal_write_ptr <= normal_write_ptr + 1;
      end

      if (material_valid_in) begin
        // TODO: add overflow logic
        material_write_ptr <= material_write_ptr + 1;
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
    .RAM_DEPTH(4096)
  ) vertex_ram (
    .addra(position_write_ptr),
    .addrb(read_ptr),
    .dina(position_in),
    .dinb(),
    .clka(clk_in),
    .wea(position_valid_in),
    .web(1'b0),
    .ena(1'b1),
    .enb(1'b1),
    .rsta(1'b0),
    .rstb(1'b0),
    .regcea(1'b1),
    .regceb(1'b1),
    .douta(),
    .doutb(position_out)
  );

  xilinx_dual_port_ram #(
    .RAM_WIDTH(12),
    .RAM_DEPTH(4096)
  ) normal_ram (
    .addra(normal_write_ptr),
    .addrb(read_ptr),
    .dina(normal_in),
    .dinb(),
    .clka(clk_in),
    .wea(normal_valid_in),
    .web(1'b0),
    .ena(1'b1),
    .enb(1'b1),
    .rsta(1'b0),
    .rstb(1'b0),
    .regcea(1'b1),
    .regceb(1'b1),
    .douta(),
    .doutb(normal_out)
  );

  xilinx_dual_port_ram #(
    .RAM_WIDTH(12),
    .RAM_DEPTH(4096)
  ) material_ram (
    .addra(material_write_ptr),
    .addrb(read_ptr),
    .dina(material_in),
    .dinb(),
    .clka(clk_in),
    .wea(material_valid_in),
    .web(1'b0),
    .ena(1'b1),
    .enb(1'b1),
    .rsta(1'b0),
    .rstb(1'b0),
    .regcea(1'b1),
    .regceb(1'b1),
    .douta(),
    .doutb(material_out)
  );

endmodule

`default_nettype wire
