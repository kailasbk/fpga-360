`default_nettype none
`timescale 1ns / 1ps

module model_memory (
  input wire clk_in,
  input wire rst_in,

  input wire rx_in,
  output logic tx_out,

  input wire [15:0] index_id_in,
  output logic [2:0][11:0] index_out,

  input wire [11:0] position_id_in,
  output logic [2:0][31:0] position_out,

  input wire [11:0] normal_id_in,
  output logic [2:0][31:0] normal_out,

  input wire [11:0] material_id_in,
  output logic [2:0][31:0] material_out
);

  parameter INDICES_WIDTH=36;
  parameter BRAM_WIDTH=96;

  logic [2:0] write_enable;
  logic [15:0] write_addr;
  logic [15:0] next_write_addr;
  logic [35:0] indices_data_in;
  logic [95:0] bram_data_in;

  xilinx_single_port_ram #(
    .RAM_WIDTH(INDICES_WIDTH),
    .RAM_DEPTH(8192),
    .INIT_FILE("./data/indices.mem")
  ) index_brom (
    .addra(!write_enable[0] ? index_id_in[12:0] : write_addr[12:0]),
    .dina(indices_data_in),
    .clka(clk_in),
    .wea(write_enable[0]),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(index_out)
  );

  xilinx_single_port_ram #(
    .RAM_WIDTH(BRAM_WIDTH),
    .RAM_DEPTH(2048),
    .INIT_FILE("./data/positions.mem")
  ) position_brom (
    .addra(!write_enable[1] ? position_id_in[10:0] : write_addr[10:0]),
    .dina(bram_data_in),
    .clka(clk_in),
    .wea(write_enable[1]),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(position_out)
  );

  xilinx_single_port_ram #(
    .RAM_WIDTH(BRAM_WIDTH),
    .RAM_DEPTH(2048),
    .INIT_FILE("./data/normals.mem")
  ) normal_brom (
    .addra(!write_enable[2] ? normal_id_in[10:0] : write_addr[10:0]),
    .dina(bram_data_in),
    .clka(clk_in),
    .wea(write_enable[2]),
    .ena(1'b1),
    .rsta(1'b0),
    .regcea(1'b1),
    .douta(normal_out)
  );

  logic [95:0] materials [32];
  initial begin
    $readmemh("./data/materials.mem", materials, 0, 31);
  end
  assign material_out = materials[material_id_in[4:0]];

  logic uart_valid;
  logic [7:0] uart_byte;
  uart uart (
    .clk_in,
    .rst_in,
    .rx_in,
    .tx_out,
    .valid_in(uart_valid), // echo rx back over tx
    .byte_in(uart_byte),
    .valid_out(uart_valid),
    .byte_out(uart_byte)
  );

  logic [1:0] mem_state;
  logic [3:0] byte_counter;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      mem_state <= 2'b00; //indices
      write_addr <= 16'd0;
      next_write_addr <= 16'd0;
      write_enable <= 3'b000;
      byte_counter <= 4'b0000;
      indices_data_in <= 36'b0;
      bram_data_in <= 96'b0;
    end else begin
      if (mem_state == 2'b00) begin //write to 36-bit indices BRAM
        if (uart_valid) begin
          if (byte_counter == 4'd4) begin //final bits
            byte_counter <= 4'd0;
            indices_data_in <= {indices_data_in[31:0], uart_byte[7:4]};
            write_addr <= next_write_addr;
            write_enable <= 3'b001;
            if ({indices_data_in[31:0], uart_byte[7:4]} == {INDICES_WIDTH{1'b1}}) begin //stop word, move to positions bram
              mem_state <= mem_state + 2'b1;
              next_write_addr <= 16'd0;
            end else begin
              next_write_addr <= next_write_addr + 16'd1;
            end
          end else begin
            indices_data_in <= {indices_data_in[27:0], uart_byte};
            write_enable <= 3'b000;
            byte_counter <= byte_counter + 4'b1;
          end
        end else begin
          write_enable <= 3'b000;
        end
      end else if (mem_state == 2'b01 || mem_state == 2'b10) begin //write to positions and normals BRAMs
        if (uart_valid) begin
          bram_data_in <= {bram_data_in[87:0], uart_byte};
          if (byte_counter == 4'd11) begin //final bits
            byte_counter <= 4'd0;
            case (mem_state) //set bram write bit
              2'b01: write_enable <= 3'b010; //positions
              2'b10: write_enable <= 3'b100; //normals
            endcase
            write_addr <= next_write_addr;
            if ({bram_data_in[87:0], uart_byte} == {BRAM_WIDTH{1'b1}}) begin //stop word, move to next bram
              mem_state <= mem_state + 2'b1;
              next_write_addr <= 16'b0;
            end else begin
              next_write_addr <= next_write_addr + 16'd1;
            end
          end else begin
            write_enable <= 3'b000;
            byte_counter <= byte_counter + 4'b1;
          end
        end else begin
          write_enable <= 3'b000;
        end
      end else begin //write to materials array
        write_enable <= 3'b000;
        if (uart_valid) begin
          bram_data_in <= {bram_data_in[87:0], uart_byte};
          if (byte_counter == 4'd11) begin //final bits
            byte_counter <= 4'd0;
            materials[next_write_addr[4:0]] <= {bram_data_in[87:0], uart_byte};
            if ({bram_data_in[87:0], uart_byte} == {BRAM_WIDTH{1'b1}}) begin //stop word, move to next bram
              mem_state <= mem_state + 2'b1; //loop back to indicies bram write state
              next_write_addr <= 16'b0;
            end else begin
              next_write_addr <= next_write_addr + 16'd1;
            end
          end else begin
            byte_counter <= byte_counter + 4'b1;
          end
        end
      end
    end
  end

endmodule

`default_nettype wire
