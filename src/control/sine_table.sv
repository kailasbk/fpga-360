module sine_table #(
    parameter BRAM_DEPTH=1024,  // number of entries in sine BRAM for 0° to 90°
    parameter BRAM_WIDTH=32,   // width of sine BRAM data in bits
    parameter BRAM_FILE="",   // sine table file to populate BRAM
    parameter ADDRW=$clog2(4*BRAM_DEPTH)  // full circle is 0° to 360°
    ) (
    input wire rst_in,
    input wire clk_in,
    input wire [ADDRW-1:0] id,  // table ID to lookup
    output logic [BRAM_WIDTH-1:0] data  // signed fixed-point sine value
    );

    // SINE 0-90° BRAM
    logic [$clog2(BRAM_DEPTH)-1:0] tab_id;
    logic [BRAM_WIDTH-1:0] tab_data;
    xilinx_single_port_ram #(
      .RAM_WIDTH(BRAM_WIDTH),                       // Specify RAM data width
      .RAM_DEPTH(BRAM_DEPTH),                     // Specify RAM depth (number of entries)
      .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
      .INIT_FILE(BRAM_FILE)          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) sineBRAM (
      .addra(tab_id),     // Address bus, width determined from BRAM_DEPTH
      .dina(32'b0),       // RAM input data, width determined from BRAM_WIDTH
      .clka(clk_in),       // Clock
      .wea(1'b0),         // Write enable
      .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
      .rsta(rst_in),       // Output reset (does not affect memory contents)
      .regcea(1'b1),   // Output register enable
      .douta(tab_data)      // RAM output data, width determined from BRAM_WIDTH
    );

    logic [1:0] quad;  // quadrant we're in: I, II, III, IV
    always_comb begin

        quad = id[ADDRW-1:ADDRW-2];

        case (quad)

            2'b00: tab_id = id[ADDRW-3:0];                 //  I:    0° to  90°

            2'b01: tab_id = 2*BRAM_DEPTH - id[ADDRW-3:0];  // II:   90° to 180°

            2'b10: tab_id = id[ADDRW-3:0] - 2*BRAM_DEPTH;  // III: 180° to 270°

            2'b11: tab_id = 4*BRAM_DEPTH - id[ADDRW-3:0];  // IV:  270° to 360°

        endcase
    end

    always_comb begin

        if (id == BRAM_DEPTH || id == BRAM_DEPTH+1) begin  // sin(90°) = +1.0 and next index after - weird edge case
            //data = {{BRAM_WIDTH-1{1'b0}}, 1'b1, {BRAM_WIDTH{1'b0}}};
            data = {32'b00111111100000000000000000000000}; //constant value for floating point 32-bit

        end else if (id == 2*BRAM_DEPTH || id == 2*BRAM_DEPTH+1) begin  // sin(90°) = +1.0 and next index after - weird edge case
            //data = {{BRAM_WIDTH-1{1'b0}}, 1'b1, {BRAM_WIDTH{1'b0}}};
            data = {32'b00000000000000000000000000000000}; //constant value for floating point 32-bit

        end else if (id == 3*BRAM_DEPTH || id == 3*BRAM_DEPTH+1) begin  // sin(270°) = -1.0 and next index after
            //data = {{BRAM_WIDTH{1'b1}}, {BRAM_WIDTH{1'b0}}};
            data = {32'b10111111100000000000000000000000}; //constant value for floating point 32-bit

        end else begin
            if (quad[1] == 0) begin  // positive in quadrant I and II
                //data = {{BRAM_WIDTH{1'b0}}, tab_data};
                data = tab_data; //floating point 32-bit

            end else begin           // negative in quadrant III and IV
                //data = {2*BRAM_WIDTH{1'b0}} - {{BRAM_WIDTH{1'b0}}, tab_data};
                data = {~tab_data[31], tab_data[30:0]}; //floating point 32-bit

            end
        end
    end
endmodule
