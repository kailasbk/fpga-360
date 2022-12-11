`default_nettype none
`timescale 1ns / 1ps

module model_memory (
  input wire clk_in,
  input wire rst_in,

  // inputs to write from uart

  input wire [11:0] index_id_in,
  output logic [2:0][11:0] index_out,

  input wire [11:0] position_id_in,
  output logic [2:0][31:0] position_out,

  input wire [11:0] normal_id_in,
  output logic [2:0][31:0] normal_out,

  input wire [11:0] material_id_in,
  output logic [2:0][31:0] material_out
);

  xilinx_single_port_ram #(
    .RAM_WIDTH(36),
    .RAM_DEPTH(4096),
    .INIT_FILE("./data/indices.mem")
  ) index_brom (
    .addra(index_id_in),
    .dina(36'b0),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(index_out)
  );

  xilinx_single_port_ram #(
    .RAM_WIDTH(96),
    .RAM_DEPTH(1024),
    .INIT_FILE("./data/positions.mem")
  ) position_brom (
    .addra(position_id_in[9:0]),
    .dina(96'b0),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(position_out)
  );

  xilinx_single_port_ram #(
    .RAM_WIDTH(96),
    .RAM_DEPTH(1024),
    .INIT_FILE("./data/normals.mem")
  ) normal_brom (
    .addra(normal_id_in[9:0]),
    .dina(96'b0),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(normal_out)
  );

  logic [2:0][31:0] materials [8];
  /*
  assign materials[0] = {32'h00000000, 32'h00000000, 32'h00000000};
  assign materials[1] = {32'h3F800000, 32'h00000000, 32'h00000000};
  assign materials[2] = {32'h00000000, 32'h3F800000, 32'h00000000};
  assign materials[3] = {32'h00000000, 32'h00000000, 32'h3F800000};
  assign materials[4] = {32'h3F800000, 32'h3F800000, 32'h00000000};
  assign materials[5] = {32'h00000000, 32'h3F800000, 32'h3F800000};
  assign materials[6] = {32'h3F800000, 32'h00000000, 32'h3F800000};
  assign materials[7] = {32'h3F800000, 32'h3F800000, 32'h3F800000};
  */
  assign materials[0] = {32'h3F400000, 32'h3F400000, 32'h3F400000};
  assign materials[1] = {32'h3F400000, 32'h3F400000, 32'h3F400000};
  assign materials[2] = {32'h3F400000, 32'h3F400000, 32'h3F400000};
  assign materials[3] = {32'h3F400000, 32'h3F400000, 32'h3F400000};
  assign materials[4] = {32'h3F400000, 32'h3F400000, 32'h3F400000};
  assign materials[5] = {32'h3F400000, 32'h3F400000, 32'h3F400000};
  assign materials[6] = {32'h3F400000, 32'h3F400000, 32'h3F400000};
  assign materials[7] = {32'h3F400000, 32'h3F400000, 32'h3F400000};
  /*
  initial begin
    $readmemh("./data/materials.mem", materials);
  end
  */

  assign material_out = materials[material_id_in[2:0]];

endmodule

`default_nettype wire
