module dir_vector #(
    parameter ROTATE_BITS=12, //yaw, pitch, roll bit depth
    parameter VECTOR_BITS=32 //x, y, z bit depth
    ) (
    input wire rst,
    input wire clk,
    input wire [ROTATE_BITS-1:0] yaw,
    input wire [ROTATE_BITS-1:0] pitch,
    output logic [2:0][VECTOR_BITS-1:0] x,
    output logic [2:0][VECTOR_BITS-1:0] y,
    output logic [2:0][VECTOR_BITS-1:0] z
    );

    logic [VECTOR_BITS-1:0] sin_yaw;
    logic [VECTOR_BITS-1:0] sin_pitch;
    logic [VECTOR_BITS-1:0] cos_yaw;
    logic [VECTOR_BITS-1:0] cos_pitch;

    //sine table for 32-bit sin(yaw)
    sine_table #(
      .BRAM_DEPTH(1024), //2^12 (4096) total sine table entries for all 4 quadrants
      .BRAM_WIDTH(32),    //32-bit signed fixed-point data output
      .BRAM_FILE("./data/sine_1024e_32b.mem")
      ) sin32b_yaw (
      .rst_in(rst), .clk_in(clk), .id(yaw), .data(sin_yaw)
      );

    //sine table for 32-bit sin(pitch)
    sine_table #(
      .BRAM_DEPTH(1024), //2^12 (4096) total sine table entries for all 4 quadrants
      .BRAM_WIDTH(32),   //32-bit signed fixed-point data output
      .BRAM_FILE("./data/sine_1024e_32b.mem")
      ) sin32b_pitch (
      .rst_in(rst), .clk_in(clk), .id(pitch), .data(sin_pitch)
      );

    //sine table for 32-bit cos(yaw)
    sine_table #(
      .BRAM_DEPTH(1024), //2^12 (4096) total sine table entries for all 4 quadrants
      .BRAM_WIDTH(32),    //32-bit signed fixed-point data output
      .BRAM_FILE("./data/sine_1024e_32b.mem")
      ) cos32b_yaw (
      .rst_in(rst), .clk_in(clk), .id(12'b0100_0000_0000 - yaw), .data(cos_yaw)
      );

    //sine table for 32-bit cos(pitch)
    sine_table #(
      .BRAM_DEPTH(1024), //2^12 (4096) total sine table entries for all 4 quadrants
      .BRAM_WIDTH(32),    //32-bit signed fixed-point data output
      .BRAM_FILE("./data/sine_1024e_32b.mem")
      ) cos32b_pitch (
      .rst_in(rst), .clk_in(clk), .id(12'b0100_0000_0000 - pitch), .data(cos_pitch)
      );

    logic [31:0] Z_x;
    fp32_mul cos_pitch_x_sin_yaw(
      .clk_in(clk),
      .rst_in(rst),
      .valid_in(1'b1),
      .a_in(cos_pitch),
      .b_in(sin_yaw),
      .valid_out(),
      .c_out(Z_x)
    );

    logic [31:0] Z_y;
    pipe #(
      .LATENCY(7),
      .WIDTH(32)
    ) z_pipe (
      .clk_in(clk),
      .data_in(sin_pitch),
      .data_out(Z_y)
    );

    logic [31:0] Z_z;
    fp32_mul cos_pitch_x_cos_yaw(
      .clk_in(clk),
      .rst_in(rst),
      .valid_in(1'b1),
      .a_in(cos_pitch),
      .b_in(cos_yaw),
      .valid_out(),
      .c_out(Z_z)
    );
    
    logic [31:0] X_x;
    logic [31:0] X_z;
    pipe #(
      .LATENCY(7),
      .WIDTH(64)
    ) x_pipe (
      .clk_in(clk),
      .data_in({cos_yaw, ~sin_yaw[VECTOR_BITS-1], sin_yaw[VECTOR_BITS-2:0]}),
      .data_out({X_x, X_z})
    );

    logic [31:0] neg_sin_pitch;
    assign neg_sin_pitch = {~sin_pitch[31], sin_pitch[30:0]};

    logic [31:0] Y_x;
    fp32_mul neg_sin_pitch_x_sin_yaw(
      .clk_in(clk),
      .rst_in(rst),
      .valid_in(1'b1),
      .a_in(neg_sin_pitch),
      .b_in(sin_yaw),
      .valid_out(),
      .c_out(Y_x)
    );

    logic [31:0] Y_y;
    pipe #(
      .LATENCY(7),
      .WIDTH(32)
    ) y_pipe (
      .clk_in(clk),
      .data_in(cos_pitch),
      .data_out(Y_y)
    );

    logic [31:0] Y_z;
    fp32_mul neg_sin_pitch_x_cos_yaw(
      .clk_in(clk),
      .rst_in(rst),
      .valid_in(1'b1),
      .a_in(neg_sin_pitch),
      .b_in(cos_yaw),
      .valid_out(),
      .c_out(Y_z)
    );

    always_ff @ (posedge clk) begin

      if (rst) begin

        x[0] <= {VECTOR_BITS{1'b0}}; //X_x
        x[1] <= {VECTOR_BITS{1'b0}}; //X_y
        x[2] <= {VECTOR_BITS{1'b0}}; //X_z
        y[0] <= {VECTOR_BITS{1'b0}}; //Y_x
        y[1] <= {VECTOR_BITS{1'b0}}; //Y_y
        y[2] <= {VECTOR_BITS{1'b0}}; //Y_z
        z[0] <= {VECTOR_BITS{1'b0}}; //Z_x
        z[1] <= {VECTOR_BITS{1'b0}}; //Z_y
        z[2] <= {VECTOR_BITS{1'b0}}; //Z_z

      end else begin

        x[0] <= X_x;
        x[1] <= 32'h00000000;
        x[2] <= X_z;
        y[0] <= Y_x;
        y[1] <= Y_y;
        y[2] <= Y_z;
        z[0] <= Z_x;
        z[1] <= Z_y;
        z[2] <= Z_z;

      end

    end

endmodule
