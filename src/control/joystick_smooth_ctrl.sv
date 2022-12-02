`timescale 1ns / 1ps
`default_nettype none

module joystick_smooth_ctrl #(
    parameter ROTATE_B=12, //yaw, pitch, roll bit depth
    parameter VECTOR_B=32 //x, y, z bit depth
    )(                  input wire          clk,
                        input wire          rst,
                        input wire vjoyp3, vjoyn3, vjoyp11, vjoyn11,
                        output logic [1:0][11:0] debug_joystick_data,
                        output logic [2:0][VECTOR_B-1:0] x_vec,
                        output logic [2:0][VECTOR_B-1:0] y_vec,
                        output logic [2:0][VECTOR_B-1:0] z_vec
                );

  logic [15:0] adc_data;
  logic adc_ready;
  logic [7:0] adc_chan_addr; //13h for VAUX3 (channel 3) and 1Bh for VAUX11 (channel 11)
  logic [11:0] chan3_data; //VRX (orange and yellow wires on breadboard)
  logic [11:0] chan11_data; //VRY (blue and green wires on breadboard)
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

   logic [11:0] y;
   logic [11:0] p;

   always_ff @(posedge clk) begin

     if (rst) begin
       adc_chan_addr <= 8'h13;
       counter <= 21'b0;
       y <= 12'b0;
       p <= 12'b0;
       debug_joystick_data <= 24'b0;
     end else begin

       if (adc_chan_addr == 8'h13) begin //channel 3 data is ready (for VRX)
         chan3_data <= adc_data[15:4];
         adc_chan_addr <= 8'h1B;
       end else begin //channel 11 data is ready (for VRY)
         chan11_data <= adc_data[15:4];
         adc_chan_addr <= 8'h13;
       end

       if (counter == 21'b0) begin
         debug_joystick_data <= {chan3_data, chan11_data};

         if (chan3_data < 12'h100) begin
           p <= p - 6'd48;
         end else if (chan3_data < 12'h200) begin
           p <= p - 6'd32;
         end else if (chan3_data < 12'h300) begin
           p <= p - 6'd16;
         end else if (chan3_data > 12'h700) begin
           p <= p + 6'd48;
         end else if (chan3_data > 12'h600) begin
           p <= p + 6'd32;
         end else if (chan3_data > 12'h500) begin
           p <= p + 6'd16;
         end

	 if (chan11_data < 12'h100) begin
           y <= y + 6'd48;
         end else if (chan11_data < 12'h200) begin
           y <= y + 6'd32;
         end else if (chan11_data < 12'h300) begin
           y <= y + 6'd16;
         end else if (chan11_data > 12'h700) begin
           y <= y - 6'd48;
         end else if (chan11_data > 12'h600) begin
           y <= y - 6'd32;
         end else if (chan11_data > 12'h500) begin
           y <= y - 6'd16;
         end
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

endmodule

`default_nettype none
