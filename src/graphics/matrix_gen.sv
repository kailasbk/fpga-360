`default_nettype none
`timescale 1ns / 1ps

module matrix_gen (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [2:0][31:0] right_in,
  input wire [2:0][31:0] up_in,
  input wire [2:0][31:0] direction_in,
  input wire [2:0][31:0] pos_in,

  output logic valid_out,
  output logic [3:0][31:0] col_out
);

  logic [3:0][31:0] a_rows [4];
  logic [3:0][31:0] b_cols [4];

  logic [3:0][31:0] proj_rows[4];
  /* orthographic projection matrix
  assign proj_rows[0] = {32'h00000000, 32'h00000000, 32'h00000000, 32'h3F000000};
  assign proj_rows[1] = {32'h00000000, 32'h00000000, 32'h3F2AAAAA, 32'h00000000};
  assign proj_rows[2] = {32'hBF800000, 32'hBE800000, 32'h00000000, 32'h00000000};
  assign proj_rows[3] = {32'h3F800000, 32'h00000000, 32'h00000000, 32'h00000000};
  */
  assign proj_rows[0] = {32'h00000000, 32'h00000000, 32'h00000000, 32'h3F800000};
  assign proj_rows[1] = {32'h00000000, 32'h00000000, 32'h3F800000, 32'h00000000};
  assign proj_rows[2] = {32'hBE4DD443, 32'hBF814954, 32'h00000000, 32'h00000000};
  assign proj_rows[3] = {32'h00000000, 32'hBF800000, 32'h00000000, 32'h00000000};

  logic dot_valid_in;
  logic [3:0][31:0] dot_a;
  logic [3:0][31:0] dot_b;
  logic dot_valid_out;
  logic [31:0] dot_c;
  fp32_dot d (
    .clk_in,
    .rst_in,
    .valid_in(dot_valid_in),
    .a_in(dot_a),
    .b_in(dot_b),
    .valid_out(dot_valid_out),
    .c_out(dot_c)
  );

  enum {Wait, SetupView, CalculateView, SetupProj, CalculateProj, Output} state;
  logic [1:0] i, j;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      dot_valid_in = 1'b0;
      i <= 2'd0;
      j <= 2'd0;
      state <= Wait;
      valid_out <= 1'b0;
    end else case (state)
      Wait: begin
        valid_out <= 1'b0;
        if (valid_in) begin
          // create the change of basis matrix for view
          a_rows[0] <= {32'h00000000, right_in};
          a_rows[1] <= {32'h00000000, up_in};
          a_rows[2] <= {32'h00000000, direction_in};
          a_rows[3] <= {32'h3F800000, 32'h00000000, 32'h00000000, 32'h00000000};

          // create the translation for the view
          b_cols[0] <= {32'h00000000, 32'h00000000, 32'h00000000, 32'h3F800000};
          b_cols[1] <= {32'h00000000, 32'h00000000, 32'h3F800000, 32'h00000000};
          b_cols[2] <= {32'h00000000, 32'h3F800000, 32'h00000000, 32'h00000000};
          b_cols[3] <= {32'h3F800000, ~pos_in[2][31], pos_in[2][30:0], ~pos_in[1][31], pos_in[1][30:0], ~pos_in[0][31], pos_in[0][30:0]};

          state <= SetupView;
        end
      end
      SetupView: begin
        dot_valid_in <= 1'b1;
        dot_a <= a_rows[i];
        dot_b <= b_cols[j];
        i <= i + 1;
        if (i == 2'd3) begin
          j <= j + 1;
          if (j == 2'd3) begin
            state <= CalculateView;
          end
        end
      end
      CalculateView: begin
        dot_valid_in <= 1'b0;
        if (dot_valid_out) begin
          b_cols[j][i] <= dot_c;
          i <= i + 1;
          if (i == 2'd3) begin
            j <= j + 1;
            if (j == 2'd3) begin
              state <= SetupProj;
            end
          end
        end
      end
      SetupProj: begin
        dot_valid_in <= 1'b1;
        dot_a <= proj_rows[i];
        dot_b <= b_cols[j];
        i <= i + 1;
        if (i == 2'd3) begin
          j <= j + 1;
          if (j == 2'd3) begin
            state <= CalculateProj;
          end
        end
      end
      CalculateProj: begin
        dot_valid_in <= 1'b0;
        if (dot_valid_out) begin
          b_cols[j][i] <= dot_c;
          i <= i + 1;
          if (i == 2'd3) begin
            j <= j + 1;
            if (j == 2'd3) begin
              state <= Output;
            end
          end
        end
      end
      Output: begin
        valid_out <= 1'b1;
        col_out <= b_cols[j];
        j <= j + 1;
        if (j == 2'd3) begin
          state <= Wait;
        end
      end
    endcase
  end

endmodule

`default_nettype wire
