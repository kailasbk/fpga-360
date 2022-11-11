`default_nettype none
`timescale 1ns / 1ps

module rasterizer (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  output logic ready_out,
  input wire [3:0][31:0] vertex_in,

  output logic valid_out,
  output logic [15:0] triangle_id_out,
  output logic [2:0][16:0] fragment_out
);

  logic next_triangle_id;
  enum {Ready, Convert, Store, Assemble, Raster} state;
  assign ready_out = state == Ready;

  logic [1:0] next_vertex;
  logic [2:0][16:0] vertices [3];

  logic [16:0] x_lower_bound;
  logic [16:0] x_upper_bound;
  logic [16:0] y_lower_bound;
  logic [16:0] y_upper_bound;

  logic [2:0][23:0] floating_fracs;
  logic [2:0][4:0] conv_shifts;
  logic [2:0][16:0] fixed_vertex;
  logic [2:0][6:0] trailing_bits;

  logic point_valid;
  logic [1:0][16:0] point;
  logic [1:0][16:0] next_point;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      next_triangle_id <= 16'd0;
      state <= Ready;
      next_vertex <= 2'd0;
      x_lower_bound <= 17'h140_00;
      x_upper_bound <= 17'h000_00;
      y_lower_bound <= 17'h0F0_00;
      y_upper_bound <= 17'h000_00;
      point_valid <= 1'b0;
    end else case (state)
      Ready: begin
        if (valid_in) begin
          // x and y are fixed point [0, 512)
          if (vertex_in[0][30:23] <= 8'd135) begin
            floating_fracs[0] <= {1'(vertex_in[0][30:23] != 8'b0), vertex_in[0][22:0]};
            conv_shifts[0] <= 5'(8'd135 - vertex_in[0][30:23]);
          end else begin
            floating_fracs[0] <= 24'hFFFFFF;
            conv_shifts[0] <= 5'd0;
          end

          if (vertex_in[1][30:23] <= 8'd135) begin
            floating_fracs[1] <= {1'(vertex_in[1][30:23] != 8'b0), vertex_in[1][22:0]};
            conv_shifts[1] <= 5'(8'd135 - vertex_in[1][30:23]);
          end else begin
            floating_fracs[1] <= 24'hFFFFFF;
            conv_shifts[1] <= 5'd0;
          end

          // z is fixed point [0, 1)
          if (vertex_in[2][30:23] <= 8'd126) begin
            floating_fracs[2] <= {1'(vertex_in[2][30:23] != 8'b0), vertex_in[2][22:0]};
            conv_shifts[2] <= 5'(8'd126 - vertex_in[2][30:23]);
          end else begin
            floating_fracs[2] <= 24'hFFFFFF;
            conv_shifts[2] <= 5'd0;
          end

          state <= Convert;
        end
      end
      Convert: begin
        {fixed_vertex[0], trailing_bits[0]} <= floating_fracs[0] >> conv_shifts[0];
        {fixed_vertex[1], trailing_bits[1]} <= floating_fracs[1] >> conv_shifts[1];
        {fixed_vertex[2], trailing_bits[2]} <= floating_fracs[2] >> conv_shifts[2];
        state <= Store;
      end
      Store: begin
        vertices[next_vertex] <= fixed_vertex;
        // note: don't need to compare all bits
        if (fixed_vertex[0] < x_lower_bound) begin
          x_lower_bound <= fixed_vertex[0];
        end
        if (fixed_vertex[0] > x_upper_bound) begin
          x_upper_bound <= fixed_vertex[0];
        end
        if (fixed_vertex[1] < y_lower_bound) begin
          y_lower_bound <= fixed_vertex[1];
        end
        if (fixed_vertex[1] > y_upper_bound) begin
          y_upper_bound <= fixed_vertex[1];
        end

        if (next_vertex == 2'd2) begin
          state <= Assemble;
        end else begin
          next_vertex <= next_vertex + 1;
          state <= Ready;
        end
      end
      Assemble: begin
        next_point[0] <= {x_lower_bound[16:8], 8'b1000_0000};
        next_point[1] <= {y_lower_bound[16:8], 8'b1000_0000};
        next_triangle_id <= next_triangle_id + 1;
        triangle_id_out <= next_triangle_id;
        state <= Raster;
      end
      Raster: begin
        if (next_point[1] > y_upper_bound) begin
          // past y bound, rasterization is over
          point_valid <= 1'b0;

          // reset state machine
          x_lower_bound <= 17'h140_00;
          x_upper_bound <= 17'h000_00;
          y_lower_bound <= 17'h0F0_00;
          y_upper_bound <= 17'h000_00;
          next_vertex <= 2'd0;
          state <= Ready;
        end else if (next_point[0] <= x_upper_bound) begin
          // sample is within the x bounds, continue
          point_valid <= 1'b1;
          next_point[0] <= next_point[0] + 17'b0_0000_0001_0000_0000;
          point <= next_point;
        end else begin
          // sample is past, go to next y line
          point_valid <= 1'b0;
          next_point[0] <= {x_lower_bound[16:8], 8'b1000_0000};
          next_point[1] <= next_point[1] + 17'b0_0000_0001_0000_0000;
        end
      end
    endcase
  end

  // BARYCENTRIC CONVERSION SECTION

  logic coeffs_valid;
  logic [2:0] coeffs_negative;
  logic [25:0] a_coeff, b_coeff, c_coeff;
  barycentric barycentric (
    .clk_in,
    .rst_in,
    .valid_in(point_valid),
    .point_in(point),
    .vertices_in({vertices[2][1:0], vertices[1][1:0], vertices[0][1:0]}),
    .valid_out(coeffs_valid),
    .coeffs_negative_out(coeffs_negative),
    .coeffs_out({c_coeff, b_coeff, a_coeff})
  );

  logic [33:0] point_buffered;
  pipe #(
    .LATENCY(31),
    .WIDTH(34)
  ) point_pipe (
    .clk_in,
    .data_in(point),
    .data_out(point_buffered)
  );

  logic [16:0] z_buffered;
  pipe #(
    .LATENCY(31),
    .WIDTH(17)
  ) z_pipe (
    .clk_in,
    .data_in(vertices[0][2]),
    .data_out(z_buffered)
  );

  logic fragment_valid;
  assign fragment_valid = coeffs_valid && !(|coeffs_negative);

  assign valid_out = fragment_valid;
  assign fragment_out = {z_buffered, point_buffered};

endmodule

`default_nettype wire
