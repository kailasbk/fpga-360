`timescale 1ns / 1ps
`default_nettype none

module yaw_pitch_ctrl #(
    parameter ROTATE_BITS=12, //yaw, pitch, roll bit depth
    parameter STEP=1
    )(                  input wire          clk_in,
                        input wire          rst_in,
                        input wire[3:0]     evt_in,
                        output logic[15:0]  count_out,
                        output logic[ROTATE_BITS-1:0] yaw,
                        output logic[ROTATE_BITS-1:0] pitch
                    );

  always_ff @(posedge clk_in) begin
    //If rst_in is asserted, count_out is reset to zero.
    //It should stay set to zero while rst_in is asserted.
    if (rst_in) begin
      yaw <= {ROTATE_BITS{1'b0}};
      pitch <= {ROTATE_BITS{1'b0}};
    //If rst_in is not asserted and evt_in is high on a rising edge,
    //the values should be increased by 1 or -1 based on which button.
    end else begin
      if (evt_in[0]) begin //left button

        yaw <= yaw - {STEP{1'b1}};

      end else if (evt_in[1]) begin //right button

        yaw <= yaw + {STEP{1'b1}};

      end

      if (evt_in[2]) begin //down button

        pitch <= pitch - {STEP{1'b1}};

      end else if (evt_in[3]) begin //up button

        pitch <= pitch + {STEP{1'b1}};

      end
    end
  end
endmodule //btn_ctrl

`default_nettype wire
