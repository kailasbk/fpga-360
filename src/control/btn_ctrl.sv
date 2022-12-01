`timescale 1ns / 1ps
`default_nettype none

module btn_ctrl #(
    parameter ROTATE_B=12, //yaw, pitch, roll bit depth
    parameter VECTOR_B=32, //x, y, z bit depth
    parameter S=5 //Step for how big the increments are for changing yaw and pitch
    )(                  input wire          clk,
                        input wire          rst,
                        input wire btnd, btnu, btnl, btnr,
                        output logic [2:0][VECTOR_B-1:0] x_vec,
                        output logic [2:0][VECTOR_B-1:0] y_vec,
                        output logic [2:0][VECTOR_B-1:0] z_vec
                );

  logic btnl_pulse;
  logic btnr_pulse;
  logic btnd_pulse;
  logic btnu_pulse;
  logic [3:0] btn_pulse;
  assign btn_pulse = {btnu_pulse, btnd_pulse, btnr_pulse, btnl_pulse};

  logic deb_btnl_out;
  debouncer btnl_db(.clk_in(clk),
                  .rst_in(rst),
                  .dirty_in(btnl),
                  .clean_out(deb_btnl_out));

  logic deb_btnr_out;
  debouncer btnr_db(.clk_in(clk),
                  .rst_in(rst),
                  .dirty_in(btnr),
                  .clean_out(deb_btnr_out));

  logic deb_btnd_out;
  debouncer btnd_db(.clk_in(clk),
                  .rst_in(rst),
                  .dirty_in(btnd),
                  .clean_out(deb_btnd_out));

  logic deb_btnu_out;
  debouncer btnu_db(.clk_in(clk),
                  .rst_in(rst),
                  .dirty_in(btnu),
                  .clean_out(deb_btnu_out));

   logic prev_btnl_out;
   logic prev_btnr_out;
   logic prev_btnd_out;
   logic prev_btnu_out;

    always_ff @(posedge clk) begin : EDGE_DETECTOR
        prev_btnl_out <= deb_btnl_out;
        btnl_pulse <= (deb_btnl_out == 1 && prev_btnl_out == 0) ? 1 : 0;
        prev_btnr_out <= deb_btnr_out;
        btnr_pulse <= (deb_btnr_out == 1 && prev_btnr_out == 0) ? 1 : 0;
        prev_btnd_out <= deb_btnd_out;
        btnd_pulse <= (deb_btnd_out == 1 && prev_btnd_out == 0) ? 1 : 0;
        prev_btnu_out <= deb_btnu_out;
        btnu_pulse <= (deb_btnu_out == 1 && prev_btnu_out == 0) ? 1 : 0;
    end

  logic [11:0] y;
  logic [11:0] p;
  yaw_pitch_ctrl #(
      .ROTATE_BITS(ROTATE_B), //yaw, pitch, roll bit depth
      .STEP(S)
      ) mbc( .clk_in(clk),
                .rst_in(rst),
                .evt_in(btn_pulse),
                .yaw(y),
                .pitch(p));

  dir_vector vector(
      .rst(rst),
      .clk(clk),
      .yaw(y),
      .pitch(p),
      .x(x_vec),
      .y(y_vec),
      .z(z_vec)
      );

endmodule

`default_nettype none
