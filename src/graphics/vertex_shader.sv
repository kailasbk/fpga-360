`default_nettype none
`timescale 1ns / 1ps

module vertex_shader (
  input wire clk_in,
  input wire rst_in,

  input wire col_set_in,
  input wire [3:0][31:0] col_in,
  
  input wire valid_in,
  input wire [2:0][31:0] vertex_in,
  input wire [11:0] material_in,

  output logic valid_out,
  output logic [3:0][31:0] vertex_out,
  output logic [11:0] material_out
);

  logic [1:0] col_index;
  logic [3:0][31:0] cols [4];

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      col_index <= 2'b0;
      // start with the identity matrix
      cols[0] <= {32'h00000000, 32'h00000000, 32'h00000000, 32'h3F800000};
      cols[1] <= {32'h00000000, 32'h00000000, 32'h3F800000, 32'h00000000};
      cols[2] <= {32'h00000000, 32'h3F800000, 32'h00000000, 32'h00000000};
      cols[3] <= {32'h3F800000, 32'h00000000, 32'h00000000, 32'h00000000};
    end else begin
      if (col_set_in) begin
        cols[col_index] <= col_in;
        col_index <= col_index + 1;
      end
    end
  end

  logic [31:0] x, y, z, w;
  assign x = vertex_in[0];
  assign y = vertex_in[1];
  assign z = vertex_in[2];
  assign w = 32'h3F800000; // w = 1.0

  logic [3:0] valids;

  generate
    for (genvar i = 0; i < 4; i = i + 1) begin
      // stage 1: multiply component-wise
      logic prod_valid;
      logic [31:0] x_prod;
      fp32_mul x_mul (
        .clk_in,
        .rst_in,
        .valid_in,
        .a_in(x),
        .b_in(cols[0][i]),
        .valid_out(prod_valid),
        .c_out(x_prod)
      );

      logic [31:0] y_prod;
      fp32_mul y_mul (
        .clk_in,
        .rst_in,
        .valid_in,
        .a_in(y),
        .b_in(cols[1][i]),
        .valid_out(),
        .c_out(y_prod)
      );

      logic [31:0] z_prod;
      fp32_mul z_mul (
        .clk_in,
        .rst_in,
        .valid_in,
        .a_in(z),
        .b_in(cols[2][i]),
        .valid_out(),
        .c_out(z_prod)
      );

      logic [31:0] w_prod;
      fp32_mul w_mul (
        .clk_in,
        .rst_in,
        .valid_in,
        .a_in(w),
        .b_in(cols[3][i]),
        .valid_out(),
        .c_out(w_prod)
      );

      // stage 2: merge from 4 products to 2 sums
      logic add_valid;
      logic [31:0] left_sum;
      fp32_add left_add (
        .clk_in,
        .rst_in,
        .valid_in(prod_valid),
        .a_in(x_prod),
        .b_in(y_prod),
        .valid_out(add_valid),
        .c_out(left_sum)
      );

      logic [31:0] right_sum;
      fp32_add right_add (
        .clk_in,
        .rst_in,
        .valid_in(prod_valid),
        .a_in(z_prod),
        .b_in(w_prod),
        .valid_out(),
        .c_out(right_sum)
      );

      // stage 3: merge from 2 sums to 1 sum
      logic final_valid;
      fp32_add add (
        .clk_in,
        .rst_in,
        .valid_in(add_valid),
        .a_in(left_sum),
        .b_in(right_sum),
        .valid_out(valids[i]),
        .c_out(vertex_out[i])
      );
    end
  endgenerate

  pipe #(
    .LATENCY(25),
    .WIDTH(12)
  ) material_pipe (
    .clk_in,
    .data_in(material_in),
    .data_out(material_out)
  );

  assign valid_out = &valids;

endmodule

`default_nettype wire
