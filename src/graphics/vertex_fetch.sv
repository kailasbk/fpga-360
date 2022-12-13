`default_nettype none
`timescale 1ns / 1ps

module vertex_fetch (
  input wire clk_in,
  input wire rst_in,

  output logic [15:0] index_id_out,
  input wire [2:0][11:0] index_in,
  output logic [11:0] position_id_out,
  input wire [2:0][31:0] position_in,

  output logic valid_out,
  output logic [2:0][31:0] position_out,
  output logic [11:0] debug_position_id_out,
  output logic [11:0] normal_out,
  output logic [11:0] material_out
);

  // index fetch pipeline

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

  logic [15:0] index_id;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      index_id <= 16'd0;
      state <= Reading;
    end else case (state)
      Reading: begin
        index_id <= index_id + 1;
        if (index_valid && index_in[0] == 12'hFFF) begin
          state <= Done;
        end
      end
    endcase
  end

  assign index_id_out = index_id;

  // position fetch pipeline

  logic vertex_valid;
  valid_pipe #(
    .LATENCY(2)
  ) vertex_valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in(state != Done && index_valid && index_in[0] != 12'hFFF),
    .valid_out
  );

  assign position_id_out = index_in[2];

  // outputs to graphics pipeline

  assign position_out = position_in;

  pipe #(
    .LATENCY(2),
    .WIDTH(12)
  ) debug_pos_pipe (
    .clk_in,
    .data_in(index_in[2]),
    .data_out(debug_position_id_out)
  );

  pipe #(
    .LATENCY(2),
    .WIDTH(12)
  ) normal_pipe (
    .clk_in,
    .data_in(index_in[1]),
    .data_out(normal_out)
  );

  pipe #(
    .LATENCY(2),
    .WIDTH(12)
  ) material_pipe (
    .clk_in,
    .data_in(index_in[0]),
    .data_out(material_out)
  );

endmodule

`default_nettype wire
