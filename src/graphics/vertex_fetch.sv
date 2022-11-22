`default_nettype none
`timescale 1ns / 1ps

module vertex_fetch (
  input wire clk_in,
  input wire rst_in,

  output logic valid_out,
  output logic [15:0] vertex_id_out,
  output logic [2:0][31:0] vertex_out,
  output logic [11:0] color_out
);

  localparam LAST_INDEX = 8;
  enum {Reading, Done} state;

  valid_pipe #(
    .LATENCY(4)
  ) valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in(state == Reading),
    .valid_out
  );

  logic [11:0] index_id;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      index_id <= 10'b0;
      state <= Reading;
    end else case (state)
      Reading: begin
        index_id <= index_id + 1;
        if (index_id == LAST_INDEX) begin
          state <= Done;
        end
      end
    endcase
  end

  logic [11:0] vertex_id;
  xilinx_single_port_ram #(
    .RAM_WIDTH(12),
    .RAM_DEPTH(1024),
    .INIT_FILE("./data/indices.mem")
  ) index_brom (
    .addra(index_id[9:0]),
    .dina(12'b0),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(vertex_id)
  );

  pipe #(
    .LATENCY(2),
    .WIDTH(16)
  ) id_pipe (
    .clk_in,
    .data_in({4'b0, vertex_id}),
    .data_out(vertex_id_out)
  );

  xilinx_single_port_ram #(
    .RAM_WIDTH(96),
    .RAM_DEPTH(1024),
    .INIT_FILE("./data/vertices.mem")
  ) vertex_brom (
    .addra(vertex_id[9:0]),
    .dina(96'b0),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(vertex_out)
  );

  xilinx_single_port_ram #(
    .RAM_WIDTH(12),
    .RAM_DEPTH(1024),
    .INIT_FILE("./data/colors.mem")
  ) color_brom (
    .addra(vertex_id[9:0]),
    .dina(12'b0),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(color_out)
  );

endmodule

`default_nettype wire
