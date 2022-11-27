`default_nettype none
`timescale 1ns / 1ps

module triangle_clip (
  input wire clk_in,
  input wire rst_in,

  input wire valid_in,
  input wire [3:0][31:0] vertex_in,
  input wire [11:0] material_in,

  output logic valid_out,
  output logic [3:0][31:0] vertex_out,
  output logic [11:0] material_out
);

  // represents whether each x,y,z clip coord is within [-w, w]
  logic [2:0] clip_inbounds, clip_bound_valids;
  generate
    for (genvar i = 0; i < 3; i = i + 1) begin
      fp32_bound bound (
        .clk_in,
        .rst_in,
        .valid_in,
        .a_in(vertex_in[i]),
        .b_in(vertex_in[3]),
        .valid_out(clip_bound_valids[i]),
        .c_out(clip_inbounds[i])
      );
    end
  endgenerate

  // the 4-component clip vertex
  logic [3:0][31:0] clip_vertex;
  logic [7:0] clip_material;
  always_ff @(posedge clk_in) begin
    clip_vertex <= vertex_in;
    clip_material <= material_in;
  end

  logic triangle_inbounds;
  logic [1:0] vertex_index;
  logic [1:0] next_vertex;
  logic [3:0][31:0] triangle_vertices [3];
  logic [7:0] triangle_materials [3];
  logic new_triangle;
  assign new_triangle = (&clip_bound_valids) && triangle_inbounds && vertex_index == 2'd2 && (&clip_inbounds); 

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      vertex_index <= 2'b00;
      next_vertex <= 2'b11;
      triangle_inbounds <= 1'b1;
      valid_out <= 1'b0;
    end else begin
      if (&clip_bound_valids) begin
        // store clip space vertex
        triangle_vertices[vertex_index] <= clip_vertex;
        triangle_materials[vertex_index] <= clip_material;

        // determine next vertex index
        if (vertex_index == 2'd2) begin
          // start a new triangle
          vertex_index <= 2'd0;
          triangle_inbounds <= 1'b1;

          if (triangle_inbounds && (&clip_inbounds)) begin
            // set output if have a valid set of 3 inbounds vertices
            vertex_out <= triangle_vertices[0];
            material_out <= triangle_materials[0];
            valid_out <= 1'b1;
            next_vertex <= 2'b01; // send vertex 1 after vertex 0
          end
        end else begin
          // move to next vertex in triangle
          vertex_index <= vertex_index + 1;
          triangle_inbounds <= triangle_inbounds && (&clip_inbounds);
        end
      end

      // handle outputing vertices
      if (next_vertex != 2'b11) begin
        vertex_out <= triangle_vertices[next_vertex];
        material_out <= triangle_materials[next_vertex];
        valid_out <= 1'b1;
        next_vertex <= next_vertex + 1;
      end else if (!new_triangle) valid_out <= 1'b0;
    end
  end

endmodule

`default_nettype wire
