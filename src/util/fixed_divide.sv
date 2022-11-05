`default_nettype none
`timescale 1ns / 1ps

module fixed_divide (
  input wire clk_in,
  
  input wire [23:0] dividend_in,
  input wire [23:0] divisor_in,

  output logic [25:0] quotient_out
);

  // takes 26 cycles

  logic [23:0] divisors [26];
  logic [25:0] quotients [26];
  logic [24:0] remainders [26];

  always_ff @(posedge clk_in) begin
    if (dividend_in >= divisor_in) begin
      remainders[25] <= (dividend_in - divisor_in) << 1;
      quotients[25] <= {1'b1, 25'b0};
    end else begin
      remainders[25] <= dividend_in << 1;
      quotients[25] <= {26'b0};
    end
    divisors[25] <= divisor_in;
  end

  generate
    for (genvar i = 24; i >= 0; i = i - 1) begin
      logic [25:0] quotient;
      logic [24:0] remainder;
      always_comb begin
        quotient = quotients[i+1];
        remainder = remainders[i+1];

        if (remainder >= divisors[i+1]) begin
          remainder = remainder - divisors[i+1];
          quotient[i] = 1'b1;
        end else begin
          quotient[i] = 1'b0;
        end
      end

      always_ff @(posedge clk_in) begin
        divisors[i] <= divisors[i+1];
        quotients[i] <= quotient;
        remainders[i] <= remainder << 1;
      end
    end
  endgenerate

  assign quotient_out = quotients[0];

endmodule

`default_nettype wire
