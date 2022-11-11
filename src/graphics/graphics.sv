`default_nettype none
`timescale 1ns / 1ps

module graphics (
  input wire gpu_clk_in,
  input wire vga_clk_in,
  input wire rst_in,

  // positional inputs go here

  output logic hsync_out,
  output logic vsync_out,
  output logic [11:0] rgb_out
);

  logic fetch_valid_in;
  logic fetch_restart;

  logic framebuffer_clear;
  logic framebuffer_switch;

  always_ff @(posedge gpu_clk_in) begin
    if (rst_in) begin
      fetch_valid_in <= 1'b0;
      fetch_restart <= 1'b0;
      framebuffer_clear <= 1'b0;
      framebuffer_switch <= 1'b0;
    end else begin
      // state machine logic here
    end
  end

  // vertex fetch stage
  logic fetch_valid_out;
  logic [2:0][31:0] fetch_vertex;
  vertex_fetch vertex_fetch (
    .clk_in(gpu_clk_in),
    .rst_in,
    .valid_in(fetch_valid_in),
    .restart_in(fetch_restart),
    .valid_out(fetch_valid_out),
    .vertex_out(fetch_vertex)
  );

  // vertex shader stage
  logic shader_valid;
  logic [3:0][31:0] shader_vertex;
  vertex_shader vertex_shader (
    .clk_in(gpu_clk_in),
    .rst_in,
    .col_set_in(1'b0), // TODO: route this
    .col_in(128'b0), // TODO: route this
    .valid_in(fetch_valid_out),
    .vertex_in(fetch_vertex),
    .valid_out(shader_valid),
    .vertex_out(shader_vertex)
  );

  // triangle clipping stage
  logic clip_valid;
  logic [3:0][31:0] clip_vertex;
  triangle_clip triangle_clip (
    .clk_in(gpu_clk_in),
    .rst_in,
    .valid_in(shader_valid),
    .vertex_in(shader_vertex),
    .valid_out(clip_valid),
    .vertex_out(clip_vertex)
  );

  // perspective divide stage
  logic ndc_valid;
  logic [3:0][31:0] ndc_vertex;
  perspective_divide perspective_divide (
    .clk_in(gpu_clk_in),
    .rst_in,
    .valid_in(clip_valid),
    .vertex_in(clip_vertex),
    .valid_out(ndc_valid),
    .vertex_out(ndc_vertex)
  );

  // viewport transform stage
  logic viewport_valid;
  logic [3:0][31:0] viewport_vertex;
  viewport_transform viewport_transform (
    .clk_in(gpu_clk_in),
    .rst_in,
    .valid_in(ndc_valid),
    .vertex_in(ndc_vertex),
    .valid_out(viewport_valid),
    .vertex_out(viewport_vertex)
  );

  // primitive fifo
  logic rasterizer_ready;
  logic fifo_valid;
  logic fifo_vertex;
  // TODO: fifo module here

  // rasterizer
  logic fragment_valid;
  logic triangle_id;
  logic [2:0][16:0] fragment;
  rasterizer rasterizer (
    .clk_in(gpu_clk_in),
    .rst_in,
    .valid_in(fifo_valid),
    .ready_out(rasterizer_ready),
    .vertex_in(fifo_vertex),
    .valid_out(fragment_valid),
    .triangle_id_out(triangle_id),
    .fragment_out(fragment)
  );

  // fragment shader stage
  logic pixel_valid;
  logic [8:0] pixel_x;
  logic [7:0] pixel_y;
  logic [7:0] pixel_z;
  logic [11:0] pixel_rgb;
  fragment_shader fragment_shader (
    .clk_in(gpu_clk_in),
    .rst_in,
    .valid_in(fragment_valid),
    .triangle_id_in(triangle_id),
    .fragment_in(fragment),
    .valid_out(pixel_valid),
    .x_out(pixel_x),
    .y_out(pixel_y),
    .z_out(pixel_z),
    .rgb_out(pixel_rgb)
  );

  // framebuffer stage
  framebuffer framebuffer (
    .gpu_clk_in,
    .vga_clk_in,
    .rst_in,
    .clear_in(framebuffer_clear),
    .switch_in(framebuffer_switch),
    .valid_in(pixel_valid),
    .x_in(pixel_x),
    .y_in(pixel_y),
    .z_in(pixel_z),
    .rgb_in(pixel_rgb),
    .hsync_out,
    .vsync_out,
    .rgb_out
  );

endmodule

`default_nettype wire
