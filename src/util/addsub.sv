// iverilog friendly definition of addsub

module addsub (
  input wire [46:0] A,
  input wire [46:0] B,
  input wire CLK,
  input wire ADD,
  output logic C_OUT,
  output logic [46:0] S
);

  logic [47:0] a, b;
  logic add, carry_in;
  always_ff @(posedge CLK) begin
    a <= A;
    b <= B;
    add <= ADD;
  end

  always_ff @(posedge CLK) begin
    if (add) begin
      {C_OUT, S} <= a + b;
    end else begin
      {C_OUT, S} <= a - b;
    end
  end

endmodule
