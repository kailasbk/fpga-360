`default_nettype none
`timescale 1ns / 1ps

module rasterizer (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  output logic ready_out,
  input wire [3:0][31:0] vertex_in,

  output logic valid_out,
  output logic [3:0][31:0] fragment_out
);

  // FSM SECTION

  enum {Ready, Convert, Store, Assemble, Raster} state;
  assign ready_out = state == Ready;

  logic [1:0][16:0] vertices [3];

  logic [16:0] x_bounds [2];
  logic [16:0] y_bounds [2];
  logic [1:0] next_vertex;

  logic [1:0][23:0] floating_fracs;
  logic [1:0][4:0] conv_shifts;
  logic [1:0][16:0] fixed_vertex;
  logic [1:0][6:0] trailing_bits;

  logic point_valid;
  logic [1:0][16:0] point;
  logic [1:0][16:0] next_point;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= Ready;
      point_valid <= 1'b0;
      x_bounds[0] <= 17'h140_00;
      x_bounds[1] <= 17'h000_00;
      y_bounds[0] <= 17'h0F0_00;
      y_bounds[1] <= 17'h000_00;
      next_vertex <= 2'd0;
    end else case (state)
      Ready: begin
        if (valid_in) begin
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

          state <= Convert;
        end
      end
      Convert: begin
        {fixed_vertex[0], trailing_bits[0]} <= floating_fracs[0] >> conv_shifts[0];
        {fixed_vertex[1], trailing_bits[1]} <= floating_fracs[1] >> conv_shifts[1];
        state <= Store;
      end
      Store: begin
        vertices[next_vertex] <= fixed_vertex;
        // note: don't need to compare all bits
        if (fixed_vertex[0] < x_bounds[0]) begin
          x_bounds[0] <= fixed_vertex;
        end
        if (fixed_vertex[0] > x_bounds[1]) begin
          x_bounds[1] <= fixed_vertex;
        end
        if (fixed_vertex[1] < y_bounds[0]) begin
          y_bounds[0] <= fixed_vertex;
        end
        if (fixed_vertex[1] > y_bounds[1]) begin
          y_bounds[1] <= fixed_vertex;
        end

        if (next_vertex == 2'd2) begin
          state <= Assemble;
        end else begin
          next_vertex <= next_vertex + 1;
          state <= Ready;
        end
      end
      Assemble: begin
        next_point[0] <= {x_bounds[0][16:8], 8'b1000_0000};
        next_point[1] <= {y_bounds[0][16:8], 8'b1000_0000};
        state <= Raster;
      end
      Raster: begin
        if (next_point[1] > next_point[1]) begin
          // past y bound, rasterization is over
          point_valid <= 1'b0;

          // reset state machine
          x_bounds[0] <= 17'h140_00;
          x_bounds[1] <= 17'h000_00;
          y_bounds[0] <= 17'h0F0_00;
          y_bounds[1] <= 17'h000_00;
          next_vertex <= 2'd0;
          state <= Ready;
        end else if (next_point[0] <= x_bounds[1]) begin
          // sample is within the x bounds, continue
          point_valid <= 1'b1;
          next_point[0] <= next_point[0] + 17'b0_0000_0001_0000_0000;
          point <= next_point;
        end else begin
          // sample is past, go to next y line
          point_valid <= 1'b0;
          next_point[0] <= {x_bounds[0][16:8], 8'b1000_0000};
          next_point[1] <= next_point[1] + 17'b0_0000_0001_0000_0000;
        end
      end
    endcase
  end

  // BARYCENTRIC CONVERSION SECTION

  logic full_area_valid;
  logic full_area_negative;
  logic [33:0] full_area;
  triangle_area full_triangle_area (
    .clk_in,
    .rst_in,
    .valid_in(point_valid),
    .vertices_in({vertices[2], vertices[1], vertices[0]}),
    .valid_out(full_area_valid),
    .negative_out(full_area_negative),
    .area_out(full_area)
  );

  logic a_area_valid;
  logic a_area_negative;
  logic [33:0] a_area;
  triangle_area a_triangle_area (
    .clk_in,
    .rst_in,
    .valid_in(point_valid),
    .vertices_in({vertices[1], vertices[0], point}),
    .valid_out(a_area_valid),
    .negative_out(a_area_negative),
    .area_out(a_area)
  );

  logic b_area_valid;
  logic b_area_negative;
  logic [33:0] b_area;
  triangle_area b_triangle_area (
    .clk_in,
    .rst_in,
    .valid_in(point_valid),
    .vertices_in({vertices[2], vertices[1], point}),
    .valid_out(b_area_valid),
    .negative_out(b_area_negative),
    .area_out(b_area)
  );

  logic c_area_valid;
  logic c_area_negative;
  logic [33:0] c_area;
  triangle_area c_triangle_area (
    .clk_in,
    .rst_in,
    .valid_in(point_valid),
    .vertices_in({vertices[0], vertices[2], point}),
    .valid_out(c_area_valid),
    .negative_out(c_area_negative),
    .area_out(c_area)
  );

  logic coeffs_valid;
  valid_pipe #(
    .LATENCY(26)
  ) coeff_valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in(a_area_valid && b_area_valid && c_area_valid),
    .valid_out(coeffs_valid)
  );

  logic [2:0] coeffs_negative;
  pipe #(
    .LATENCY(26),
    .WIDTH(3)
  ) coeff_negative_pipe (
    .clk_in,
    .data_in({a_area_negative, b_area_negative, c_area_negative}),
    .data_out(coeffs_negative)
  );

  logic [25:0] a_coeff;
  logic a_overflow;
  fixed_divide a_divide (
    .clk_in,
    .dividend_in(a_area[33:10]),
    .divisor_in(full_area[33:10]),
    .overflow_out(a_overflow),
    .quotient_out(a_coeff)
  );

  logic [25:0] b_coeff;
  logic b_overflow;
  fixed_divide b_divide (
    .clk_in,
    .dividend_in(b_area[33:10]),
    .divisor_in(full_area[33:10]),
    .overflow_out(b_overflow),
    .quotient_out(b_coeff)
  );

  logic [25:0] c_coeff;
  logic c_overflow;
  fixed_divide c_divide (
    .clk_in,
    .dividend_in(c_area[33:10]),
    .divisor_in(full_area[33:10]),
    .overflow_out(c_overflow),
    .quotient_out(c_coeff)
  );

  // FRAGMENT TESTING SECTION

  logic fragment_inside;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      fragment_inside <= 1'b0;
    end else if (coeffs_valid && !(|coeffs_negative)) begin
      fragment_inside <= 1'b1;
      // send stuff down the interpolation pipeline as needed
      // also need to emit the floating point version of the number
    end
  end

  assign valid_out = fragment_inside; // change to output of interpolation

endmodule

`default_nettype wire
