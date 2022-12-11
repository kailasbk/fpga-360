`default_nettype none
`timescale 1ns / 1ps

module fragment_shader (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [2:0][31:0] light_direction,
  input wire [15:0] triangle_id_in,
  input wire [2:0][16:0] fragment_in,
  input wire [11:0] normal_id_in,
  input wire [11:0] material_in,

  output logic [11:0] normal_id_out,
  input wire [2:0][31:0] normal_in,

  output logic valid_out,
  output logic [8:0] x_out,
  output logic [7:0] y_out,
  output logic [15:0] z_out,
  output logic [11:0] rgb_out
);

  // note: while techinally normal_in is technically late by 2 cycles, this doesn't cause major issues
  assign normal_id_out = normal_id_in;

  logic [31:0] ambient_intensity;
  assign ambient_intensity = 32'h3DCCCCCD; // 0.1 ambient level

  logic [2:0][31:0] materials [8];
  assign materials[0] = {32'h00000000, 32'h00000000, 32'h00000000};
  assign materials[1] = {32'h3F800000, 32'h00000000, 32'h00000000};
  assign materials[2] = {32'h00000000, 32'h3F800000, 32'h00000000};
  assign materials[3] = {32'h00000000, 32'h00000000, 32'h3F800000};
  assign materials[4] = {32'h3F800000, 32'h3F800000, 32'h00000000};
  assign materials[5] = {32'h00000000, 32'h3F800000, 32'h3F800000};
  assign materials[6] = {32'h3F800000, 32'h00000000, 32'h3F800000};
  assign materials[7] = {32'h3F800000, 32'h3F800000, 32'h3F800000};

  logic [2:0][31:0] albedo;
  logic [8:0] x;
  logic [7:0] y;
  logic [15:0] z;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      // nothing
    end else if (valid_in) begin
      x <= fragment_in[0][16:8];
      y <= fragment_in[1][15:8];
      z <= fragment_in[2][16:1];
      albedo <= materials[material_in[2:0]];
    end
  end

  pipe #(
    .LATENCY(42), // 25 (dot) + 9 (add) + 7 (scale) + 2 = 43 - 1 = 42
    .WIDTH(33) // 9 (x) + 8 (y) + 16 (z)
  ) xyz_pipe (
    .clk_in,
    .data_in({x, y, z}),
    .data_out({x_out, y_out, z_out})
  );

  logic [2:0][31:0] albedo_buffered;
  pipe #(
    .LATENCY(33), // 25 (dot) + 9 (add) = 34 - 1 = 33
    .WIDTH(96)
  ) albedo_pipe (
    .clk_in,
    .data_in(albedo),
    .data_out(albedo_buffered)
  );

  logic dot_valid;
  logic [31:0] diffuse_intensity;
  fp32_dot dot (
    .clk_in,
    .rst_in,
    .valid_in,
    .a_in({32'h00000000, normal_in}),
    .b_in({32'h00000000, light_direction}),
    .valid_out(dot_valid),
    .c_out(diffuse_intensity)
  );

  logic intensity_valid;
  logic [31:0] light_intensity;
  fp32_add add (
    .clk_in,
    .rst_in,
    .valid_in(dot_valid),
    .a_in(diffuse_intensity[31] ? 32'h00000000 : diffuse_intensity),
    .b_in(ambient_intensity),
    .valid_out(intensity_valid),
    .c_out(light_intensity)
  );

  logic rgb_valid;
  logic [2:0][31:0] rgb;
  fp32_scale scale (
    .clk_in,
    .rst_in,
    .valid_in(intensity_valid),
    .a_in(albedo),
    .b_in(light_intensity > 32'h3F800000 ? 32'h3F800000 : light_intensity),
    .valid_out(rgb_valid),
    .c_out(rgb)
  );

  valid_pipe #(
    .LATENCY(2)
  ) valid_pipe (
    .clk_in,
    .rst_in,
    .valid_in(rgb_valid),
    .valid_out
  );

  // convert to fixed point here
  logic [2:0][23:0] floating_fracs;
  logic [2:0][4:0] conv_shifts;
  logic [2:0][19:0] trailing_bits;
  always_ff @(posedge clk_in) begin
    // r is fixed point [0, 1)
    if (rgb[2][30:23] <= 8'd126) begin
      floating_fracs[2] <= {1'(rgb[2][30:23] != 8'b0), rgb[2][22:0]};
      conv_shifts[2] <= 5'(8'd126 - rgb[2][30:23]);
    end else begin
      floating_fracs[2] <= 24'hFFFFFF;
      conv_shifts[2] <= 5'd0;
    end

    if (rgb[1][30:23] <= 8'd126) begin
      floating_fracs[1] <= {1'(rgb[1][30:23] != 8'b0), rgb[1][22:0]};
      conv_shifts[1] <= 5'(8'd126 - rgb[1][30:23]);
    end else begin
      floating_fracs[1] <= 24'hFFFFFF;
      conv_shifts[1] <= 5'd0;
    end

    if (rgb[0][30:23] <= 8'd126) begin
      floating_fracs[0] <= {1'(rgb[0][30:23] != 8'b0), rgb[0][22:0]};
      conv_shifts[0] <= 5'(8'd126 - rgb[0][30:23]);
    end else begin
      floating_fracs[0] <= 24'hFFFFFF;
      conv_shifts[0] <= 5'd0;
    end

    {rgb_out[11:8], trailing_bits[2]} <= floating_fracs[2] >> conv_shifts[2];
    {rgb_out[7:4], trailing_bits[1]} <= floating_fracs[1] >> conv_shifts[1];
    {rgb_out[3:0], trailing_bits[0]} <= floating_fracs[0] >> conv_shifts[0];
  end

endmodule

`default_nettype wire
