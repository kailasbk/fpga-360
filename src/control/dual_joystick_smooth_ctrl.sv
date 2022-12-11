`timescale 1ns / 1ps
`default_nettype none

module dual_joystick_smooth_ctrl #(
    parameter ROTATE_B=12, //yaw, pitch, roll bit depth
    parameter VECTOR_B=32 //x, y, z bit depth
    )(                  input wire          clk,
                        input wire          rst,
                        input wire btnr,
                        input wire vjoyp3, vjoyn3, vjoyp11, vjoyn11,
                        output logic joy_s,
                        output logic [1:0][1:0][11:0] debug_joystick_data,
                        output logic [2:0][VECTOR_B-1:0] x_vec,
                        output logic [2:0][VECTOR_B-1:0] y_vec,
                        output logic [2:0][VECTOR_B-1:0] z_vec,
                        output logic [2:0][VECTOR_B-1:0] pos
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
   logic [31:0] pos_z;
   logic [31:0] prev_pos_x;
   logic [31:0] prev_pos_y;
   logic [31:0] prev_pos_z;
   logic [31:0] left_a_scalar;
   logic [31:0] left_b_scalar;

   logic recalc_position;

   //2-state FSM for btnr to control gimble lock mode versus free camera mode
   logic camera_state;
   logic deb_btnr;
   logic prev_btnr;
   debouncer btnr_db(.clk_in(clk),
                   .rst_in(rst),
                   .dirty_in(btnr),
                   .clean_out(deb_btnr));

    always_comb begin
      if (camera_state) begin //free camera mode
        pos = {pos_z, pos_y, pos_x};
      end else begin //gimble lock mode
        pos = gimble_lock_position;
      end
    end

    logic [31:0] scale;
    logic [31:0] prev_scale;

    //adder for gimble lock mode scale
    logic [31:0] scale_add;
    fp32_add scale_adder ( //adder for x components in scaled directional vectors
      .clk_in(clk),
      .rst_in(rst),
      .valid_in(recalc_position),
      .a_in(prev_scale),
      .b_in(scale_add),
      .valid_out(),
      .c_out(scale)
    );

    //scaling for gimble lock mode
    logic [2:0][31:0] gimble_lock_position;
    fp32_scale direction_scale (
      .clk_in(clk),
      .rst_in(rst),
      .valid_in(1'b1),
      .a_in(z_vec),
      .b_in(scale),
      .valid_out(),
      .c_out(gimble_lock_position)
    );

   //dual joystick control
   always_ff @(posedge clk) begin

     if (rst) begin
       adc_chan_addr <= 8'h13; //VRX
       counter <= 21'b0;
       switch_counter <= 10'b0;
       y <= 12'b0;
       p <= 12'b0;
       debug_joystick_data <= 48'b0;
       joy_s <= 1'b0;
       recalc_position <= 1'b0;
       camera_state <= 0; //gimble lock mode
       prev_scale <= 32'h41100000;
       scale_add <= 32'h00000000;
     end else begin
        prev_btnr <= deb_btnr;
        if (deb_btnr == 1 && prev_btnr == 0) begin //switch between camera states on button press
         camera_state <= ~camera_state;
         counter <= 21'b0;
         if (!camera_state) begin
           prev_pos_x <= gimble_lock_position[0];
           prev_pos_y <= gimble_lock_position[1];
           prev_pos_z <= gimble_lock_position[2];
         end
        end

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

        switch_counter <= switch_counter + 1; //multiplexer switch every 1.5ms

       if (counter == 21'b0) begin
         debug_joystick_data <= {left_vrx_data, left_vry_data, right_vrx_data, right_vry_data};

         if (right_vry_data < 12'h100) begin //right joystick y
           p <= p - 6'd15;
         end else if (right_vry_data < 12'h200) begin
           p <= p - 6'd10;
         end else if (right_vry_data < 12'h300) begin
           p <= p - 6'd5;
         end else if (right_vry_data > 12'h700) begin
           p <= p + 6'd15;
         end else if (right_vry_data > 12'h600) begin
           p <= p + 6'd10;
         end else if (right_vry_data > 12'h500) begin
           p <= p + 6'd5;
         end

	       if (right_vrx_data < 12'h100) begin //right joystick x
           y <= y + 6'd15;
         end else if (right_vrx_data < 12'h200) begin
           y <= y + 6'd10;
         end else if (right_vrx_data < 12'h300) begin
           y <= y + 6'd5;
         end else if (right_vrx_data > 12'h700) begin
           y <= y - 6'd15;
         end else if (right_vrx_data > 12'h600) begin
           y <= y - 6'd10;
         end else if (right_vrx_data > 12'h500) begin
           y <= y - 6'd5;
         end

         if (camera_state) begin //free camera mode allows for 2D position updates
           if (left_vrx_data < 12'h100) begin //left joystick x moves left and right
             left_a_scalar <= 32'h3DB851EC;
           end else if (left_vrx_data < 12'h200) begin
             left_a_scalar <= 32'h3D75C28F;
           end else if (left_vrx_data < 12'h300) begin
             left_a_scalar <= 32'h3CF5C28F;
           end else if (left_vrx_data > 12'h700) begin
             left_a_scalar <= 32'hBDB851EC;
           end else if (left_vrx_data > 12'h600) begin
             left_a_scalar <= 32'hBD75C28F;
           end else if (left_vrx_data > 12'h500) begin
             left_a_scalar <= 32'hBCF5C28F;
           end else begin
             left_a_scalar <= 32'h00000000;
           end

           if (left_vry_data < 12'h100) begin //left joystick y moves forward and back
             left_b_scalar <= 32'h3DB851EC;
           end else if (left_vry_data < 12'h200) begin
             left_b_scalar <= 32'h3D75C28F;
           end else if (left_vry_data < 12'h300) begin
             left_b_scalar <= 32'h3CF5C28F;
           end else if (left_vry_data > 12'h700) begin
             left_b_scalar <= 32'hBDB851EC;
           end else if (left_vry_data > 12'h600) begin
             left_b_scalar <= 32'hBD75C28F;
           end else if (left_vry_data > 12'h500) begin
             left_b_scalar <= 32'hBCF5C28F;
           end else begin
             left_b_scalar <= 32'h00000000;
           end

         end else begin //gimble lock mode allows for scaling of the 3D view
           if (left_vry_data < 12'h100) begin //left joystick y scales the view up and down
             scale_add <= 32'h3E19999A;
           end else if (left_vry_data < 12'h200) begin
             scale_add <= 32'h3DCCCCCD;
           end else if (left_vry_data < 12'h300) begin
             scale_add <= 32'h3D4CCCCD;
           end else if (left_vry_data > 12'h700) begin
             scale_add <= 32'hBE19999A;
           end else if (left_vry_data > 12'h600) begin
             scale_add <= 32'hBDCCCCCD;
           end else if (left_vry_data > 12'h500) begin
             scale_add <= 32'hBD4CCCCD;
           end else begin
             scale_add <= 32'h00000000;
           end
         end

         recalc_position <= 1'b1;

       end else if (counter == 21'd100) begin
         prev_pos_x <= pos_x;
         prev_pos_y <= pos_y;
         prev_pos_z <= pos_z;

         prev_scale <= scale;

         recalc_position <= 1'b0;
       end

       counter <= counter + 21'b1; //update camera position and directional vectors every 50ms
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

  logic scale_valid;
  logic [2:0][31:0] scaled_X_vec;
  fp32_scale scale_X_vec (//scale X directional vector using joystick left scalar
    .clk_in(clk),
    .rst_in(rst),
    .valid_in(recalc_position),
    .a_in(x_vec),
    .b_in(left_a_scalar),
    .valid_out(scale_valid),
    .c_out(scaled_X_vec)
  );

  logic [2:0][31:0] scaled_Z_vec;
  fp32_scale scale_Z_vec (//scale Z directional vector using joystick left scalar
    .clk_in(clk),
    .rst_in(rst),
    .valid_in(recalc_position),
    .a_in(z_vec),
    .b_in(left_b_scalar),
    .valid_out(),
    .c_out(scaled_Z_vec)
  );

  logic [31:0] sum_x_comp;
  logic sum_x_comp_out;
  fp32_add add_x_comp ( //adder for x components in scaled directional vectors
    .clk_in(clk),
    .rst_in(rst),
    .valid_in(scale_valid),
    .a_in(scaled_X_vec[0]),
    .b_in(scaled_Z_vec[0]),
    .valid_out(sum_x_comp_out),
    .c_out(sum_x_comp)
  );

  logic [31:0] sum_y_comp;
  logic sum_y_comp_out;
  fp32_add add_y_comp ( //adder for y components in scaled directional vectors
    .clk_in(clk),
    .rst_in(rst),
    .valid_in(scale_valid),
    .a_in(scaled_X_vec[1]),
    .b_in(scaled_Z_vec[1]),
    .valid_out(sum_y_comp_out),
    .c_out(sum_y_comp)
  );

  logic [31:0] sum_z_comp;
  logic sum_z_comp_out;
  fp32_add add_z_comp ( //adder for z components in scaled directional vectors
    .clk_in(clk),
    .rst_in(rst),
    .valid_in(scale_valid),
    .a_in(scaled_X_vec[2]),
    .b_in(scaled_Z_vec[2]),
    .valid_out(sum_z_comp_out),
    .c_out(sum_z_comp)
  );

  logic pos_x_out;
  fp32_add add_x_pos ( //adder for new x position based on previous position and scaled x components
    .clk_in(clk),
    .rst_in(rst),
    .valid_in(sum_x_comp_out),
    .a_in(sum_x_comp),
    .b_in(prev_pos_x),
    .valid_out(pos_x_out),
    .c_out(pos_x)
  );

  logic pos_y_out;
  fp32_add add_y_pos ( //adder for new y position based on previous position and scaled y components
    .clk_in(clk),
    .rst_in(rst),
    .valid_in(sum_y_comp_out),
    .a_in(sum_y_comp),
    .b_in(prev_pos_y),
    .valid_out(pos_y_out),
    .c_out(pos_y)
  );

  logic pos_z_out;
  fp32_add add_z_pos ( //adder for new z position based on previous position and scaled z components
    .clk_in(clk),
    .rst_in(rst),
    .valid_in(sum_z_comp_out),
    .a_in(sum_z_comp),
    .b_in(prev_pos_z),
    .valid_out(pos_z_out),
    .c_out(pos_z)
  );

endmodule

`default_nettype none
