`default_nettype none
`timescale 1ns / 1ps

module vertex_fetch (
  input wire clk_in,
  input wire rst_in,

  output logic valid_out,
  output logic [11:0] index_id_out,
  output logic [2:0][31:0] position_out,
  output logic [2:0][31:0] normal_out,
  output logic [11:0] material_out
);

  enum {Reading, Done} state;

  logic index_valid;
  valid_pipe #(
    .LATENCY(2)
  ) index_valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in(state == Reading),
    .valid_out(index_valid)
  );

  logic [11:0] index_id;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      index_id <= 10'b0;
      state <= Reading;
    end else case (state)
      Reading: begin
        index_id <= index_id + 1;
        if (index_valid && position_id == 12'hFFF) begin
          state <= Done;
        end
      end
    endcase
  end

  logic vertex_valid;
  valid_pipe #(
    .LATENCY(2)
  ) vertex_valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in(state != Done && index_valid && position_id != 12'hFFF),
    .valid_out
  );

  logic [11:0] position_id;
  logic [11:0] normal_id;
  logic [11:0] material_id;
  xilinx_single_port_ram #(
    .RAM_WIDTH(36),
    .RAM_DEPTH(4096),
    .INIT_FILE("./data/indices.mem")
  ) index_brom (
    .addra(index_id),
    .dina(36'b0),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta({position_id, normal_id, material_id})
  );

  pipe #(
    .LATENCY(4),
    .WIDTH(12)
  ) id_pipe (
    .clk_in,
    .data_in(index_id),
    .data_out(index_id_out)
  );

  xilinx_single_port_ram #(
    .RAM_WIDTH(96),
    .RAM_DEPTH(1024),
    .INIT_FILE("./data/positions.mem")
  ) position_brom (
    .addra(position_id[9:0]),
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
    .addra(normal_id[9:0]),
    .dina(96'b0),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(normal_out)
  );

  pipe #(
    .LATENCY(2),
    .WIDTH(12)
  ) material_pipe (
    .clk_in,
    .data_in(material_id),
    .data_out(material_out)
  );

endmodule

`default_nettype wire
