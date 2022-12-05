`timescale 1ns / 1ps
`default_nettype none

module dual_joystick_smooth_ctrl #(
    parameter ROTATE_B=12, //yaw, pitch, roll bit depth
    parameter VECTOR_B=32 //x, y, z bit depth
    )(                  input wire          clk,
                        input wire          rst,
                        input wire vjoyp3, vjoyn3, vjoyp11, vjoyn11,
                        output logic joy_s,
                        output logic [1:0][1:0][11:0] debug_joystick_data,
                        output logic [2:0][VECTOR_B-1:0] x_vec,
                        output logic [2:0][VECTOR_B-1:0] y_vec,
                        output logic [2:0][VECTOR_B-1:0] z_vec,
                        output logic [1:0][VECTOR_B-1:0] pos // [x, y]
                );

  logic [15:0] adc_data;
  logic adc_ready;
  logic [7:0] adc_chan_addr; //13h for VAUX3 (channel 3) and 1Bh for VAUX11 (channel 11)
  logic [11:0] left_vrx_data; //VRX (orange and yellow wires on breadboard)
  logic [11:0] left_vry_data; //VRY (blue and green wires on breadboard)
  logic [11:0] right_vrx_data; //VRX (orange and yellow wires on breadboard)
  logic [11:0] right_vry_data; //VRY (blue and green wires on breadboard)
  logic prev_adc_ready;

  xadc_fpga360 adc(.daddr_in(adc_chan_addr),            // Address bus for the dynamic reconfiguration port - Q: Do I have to change this address every cycle to read the two different ADC channels or can I read them simulatenously?
                  .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
                  .den_in(1'b1),              // Enable Signal for the dynamic reconfiguration port
                  .di_in(16'b0),               // Input data bus for the dynamic reconfiguration port
                  .dwe_in(0),              // Write Enable for the dynamic reconfiguration port
                  .vauxp3(vjoyp3),              // Auxiliary channel 3 (for VRX)
                  .vauxn3(vjoyn3),
                  .vauxp11(vjoyp11),             // Auxiliary channel 11 (for VRY)
                  .vauxn11(vjoyn11),
                  .do_out(adc_data),   // Output data bus for dynamic reconfiguration port
                  .drdy_out(adc_ready)            // Data ready signal for the dynamic reconfiguration port
                  );

   logic [20:0] counter;
   logic [15:0] switch_counter;

   logic [11:0] y;
   logic [11:0] p;
   logic [31:0] pos_x;
   logic [31:0] pos_y;
   logic [31:0] prev_pos_x;
   logic [31:0] prev_pos_y;
   logic [31:0] delta_x;
   logic [31:0] delta_y;

   assign pos[0] = pos_x;
   assign pos[1] = pos_y;

   always_ff @(posedge clk) begin

     if (rst) begin
       adc_chan_addr <= 8'h13; //VRX
       counter <= 21'b0;
       switch_counter <= 10'b0;
       y <= 12'b0;
       p <= 12'b0;
       debug_joystick_data <= 48'b0;
       joy_s <= 1'b0;
     end else begin

        if (switch_counter == 16'b0) begin
          if (adc_chan_addr == 8'h13 && joy_s == 1'b0) begin //channel 3 data is ready (for VRX)
            left_vrx_data <= adc_data[15:4];
            adc_chan_addr <= 8'h1B; //vry
          end else if (adc_chan_addr == 8'h1B && joy_s == 1'b0) begin //channel 11 data is ready (for VRY)
            left_vry_data <= adc_data[15:4];
            adc_chan_addr <= 8'h13; //vrx
            joy_s <= 1'b1;
          end else if (adc_chan_addr == 8'h13 && joy_s == 1'b1) begin //channel 3 data is ready (for VRX)
            right_vrx_data <= adc_data[15:4];
            adc_chan_addr <= 8'h1B; //vry
          end else if (adc_chan_addr == 8'h1B && joy_s == 1'b1) begin //channel 11 data is ready (for VRY)
            right_vry_data <= adc_data[15:4];
            adc_chan_addr <= 8'h13; //vrx
            joy_s <= 1'b0;
          end
        end

        switch_counter <= switch_counter + 1;

       if (counter == 21'b0) begin
         debug_joystick_data <= {left_vrx_data, left_vry_data, right_vrx_data, right_vry_data};

         if (right_vry_data < 12'h100) begin //right joystick y
           p <= p - 6'd48;
         end else if (right_vry_data < 12'h200) begin
           p <= p - 6'd32;
         end else if (right_vry_data < 12'h300) begin
           p <= p - 6'd16;
         end else if (right_vry_data > 12'h700) begin
           p <= p + 6'd48;
         end else if (right_vry_data > 12'h600) begin
           p <= p + 6'd32;
         end else if (right_vry_data > 12'h500) begin
           p <= p + 6'd16;
         end

	       if (right_vrx_data < 12'h100) begin //right joystick x
           y <= y + 6'd48;
         end else if (right_vrx_data < 12'h200) begin
           y <= y + 6'd32;
         end else if (right_vrx_data < 12'h300) begin
           y <= y + 6'd16;
         end else if (right_vrx_data > 12'h700) begin
           y <= y - 6'd48;
         end else if (right_vrx_data > 12'h600) begin
           y <= y - 6'd32;
         end else if (right_vrx_data > 12'h500) begin
           y <= y - 6'd16;
         end

         if (left_vrx_data < 12'h100) begin //left joystick x (upside down orientation on breadboard)
           xpos_vin <= 1;
           prev_pos_x <= pos_x;
           delta_x <= 32'h3C23D70A;
         end else if (left_vrx_data < 12'h200) begin
           xpos_vin <= 1;
           prev_pos_x <= pos_x;
           delta_x <= 32'h3C23D70A;
         end else if (left_vrx_data < 12'h300) begin
           xpos_vin <= 1;
           prev_pos_x <= pos_x;
           delta_x <= 32'h3C23D70A;
         end else if (left_vrx_data > 12'h700) begin
           xpos_vin <= 1;
           prev_pos_x <= pos_x;
           delta_x <= 32'hBC23D70A;
         end else if (left_vrx_data > 12'h600) begin
           xpos_vin <= 1;
           prev_pos_x <= pos_x;
           delta_x <= 32'hBC23D70A;
         end else if (left_vrx_data > 12'h500) begin
           xpos_vin <= 1;
           prev_pos_x <= pos_x;
           delta_x <= 32'hBC23D70A;
         end

	       if (left_vry_data < 12'h100) begin //left joystick y (upside down orientation on breadboard)
           ypos_vin <= 1;
           prev_pos_y <= pos_y;
           delta_y <= 32'hBC23D70A;
         end else if (left_vry_data < 12'h200) begin
           ypos_vin <= 1;
           prev_pos_y <= pos_y;
           delta_y <= 32'hBC23D70A;
         end else if (left_vry_data < 12'h300) begin
           ypos_vin <= 1;
           prev_pos_y <= pos_y;
           delta_y <= 32'hBC23D70A;
         end else if (left_vry_data > 12'h700) begin
           ypos_vin <= 1;
           prev_pos_y <= pos_y;
           delta_y <= 32'h3C23D70A;
         end else if (left_vry_data > 12'h600) begin
           ypos_vin <= 1;
           prev_pos_y <= pos_y;
           delta_y <= 32'h3C23D70A;
         end else if (left_vry_data > 12'h500) begin
           ypos_vin <= 1;
           prev_pos_y <= pos_y;
           delta_y <= 32'h3C23D70A;
         end

       end else begin
         xpos_vin <= 0;
         ypos_vin <= 0;
       end

       counter <= counter + 21'b1; //update every 50ms
     end
   end

  dir_vector vector(
      .rst(rst),
      .clk(clk),
      .yaw(y),
      .pitch(p),
      .x(x_vec),
      .y(y_vec),
      .z(z_vec)
      );

  logic xpos_vin, ypos_vin, xpos_vout, ypos_vout;

  fp32_add xpos_adder( //adder for x position from joystick left
    .clk_in(clk),
    .rst_in(rst),
    .valid_in(xpos_vin),
    .a_in(prev_pos_x),
    .b_in(delta_x),
    .valid_out(xpos_vout),
    .c_out(pos_x)
  );

  fp32_add ypos_adder( //adder for x position from joystick right
    .clk_in(clk),
    .rst_in(rst),
    .valid_in(ypos_vin),
    .a_in(prev_pos_y),
    .b_in(delta_y),
    .valid_out(ypos_vout),
    .c_out(pos_y)
  );

endmodule

`default_nettype none
