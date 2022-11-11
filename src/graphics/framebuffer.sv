`default_nettype none
`timescale 1ns / 1ps

module framebuffer (
  input wire gpu_clk_in,
  input wire vga_clk_in,
  input wire rst_in,
  input wire clear_in,
  input wire switch_in,

  input wire valid_in,
  input wire [8:0] x_in,
  input wire [7:0] y_in,
  input wire [7:0] z_in,
  input wire [11:0] rgb_in,

  output logic hsync_out,
  output logic vsync_out,
  output logic [11:0] rgb_out
);

  logic clear;
  logic clear_buffered;
  logic [7:0] z;
  logic [7:0] z_buffered;
  logic [16:0] write_address;
  logic [16:0] write_address_buffered;
  logic [11:0] rgb;
  logic [11:0] rgb_buffered;
  logic valid_buffered;

  enum {Clear, Write} state;

  logic [8:0] clear_x;
  logic [7:0] clear_y;
  
  logic read_target;
  logic write_target;

  always_ff @(posedge gpu_clk_in) begin
    if (rst_in) begin
      write_target <= 1'b0;
      read_target <= 1'b1;
      state <= Clear;
      clear_x <= 9'd0;
      clear_y <= 8'd0;
    end else case (state)
      Clear: begin
        if (clear_x == 319) begin
          clear_x <= 0;
          if (clear_y == 239) begin
            clear_y <= 0;
            state <= Write;
          end else clear_y <= clear_y + 1;
        end else clear_x <= clear_x + 1;

        clear <= 1'b1;
        z <= 8'hFF;
        write_address <= (clear_y * 9'd320) + clear_x;
        rgb <= 8'h00;
      end
      Write: begin
        if (switch_in) begin
          write_target <= !write_target;
          read_target <= !read_target;
        end

        if (clear_in) begin
          state <= Clear;
        end

        clear <= 1'b0;
        z <= z_in;
        write_address <= (y_in * 9'd320) + x_in;
        rgb <= rgb_in; 
      end
    endcase
  end

  pipe #(
    .LATENCY(2),
    .WIDTH(38)
  ) buffer_pipe (
    .clk_in(gpu_clk_in),
    .data_in({clear, z, write_address, rgb}),
    .data_out({clear_buffered, z_buffered, write_address_buffered, rgb_buffered})
  );

  valid_pipe #(
    .LATENCY(3)
  ) valid_pipe (
    .clk_in(gpu_clk_in),
    .rst_in,
    .valid_in,
    .valid_out(valid_buffered)
  );

  logic write_valid;
  assign write_valid = (valid_buffered && z_buffered < depth) || clear_buffered;

  logic [7:0] depth;
  depth_ram depth_ram (
    .clka(gpu_clk_in),
    .wea(write_valid),
    .addra(write_address_buffered),
    .dina(z_buffered),
    .clkb(gpu_clk_in),
    .addrb(write_address),
    .doutb(depth)
  );

  logic [9:0] hcount;
  logic [9:0] vcount;
  logic hsync;
  logic vsync;
  logic blank;
  vga vga (
    .clk_in(vga_clk_in),
    .rst_in,
    .hcount_out(hcount),
    .vcount_out(vcount),
    .hsync_out(hsync),
    .vsync_out(vsync),
    .blank_out(blank)
  );

  logic [16:0] read_address;
  assign read_address = blank ? 17'b0 : ((vcount >> 1) * 9'd320) + (hcount >> 1);
  logic [1:0][11:0] rgb_outs;

  frame_ram frame0_ram (
    .clka(gpu_clk_in),
    .wea(!write_target && write_valid),
    .addra(write_address_buffered),
    .dina(rgb_buffered),
    .clkb(vga_clk_in),
    .addrb(read_address),
    .doutb(rgb_outs[0])
  );

  frame_ram frame1_ram (
    .clka(gpu_clk_in),
    .wea(write_target && write_valid),
    .addra(write_address_buffered),
    .dina(rgb_buffered),
    .clkb(vga_clk_in),
    .addrb(read_address),
    .doutb(rgb_outs[1])
  );

  logic blank_out;
  pipe #(
    .LATENCY(2),
    .WIDTH(3)
  ) sync_pipe (
    .clk_in(vga_clk_in),
    .data_in({hsync, vsync, blank}),
    .data_out({hsync_out, vsync_out, blank_out})
  );

  assign rgb_out = blank_out ? 12'b0 : (read_target ? rgb_outs[1] : rgb_outs[0]);

endmodule

`default_nettype wire
