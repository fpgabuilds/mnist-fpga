/// A multiply-accumulate (MAC) module
/// Operates on integer values.
module mac_int #(
    parameter unsigned Bits
) (
    input logic clk_i,
    input logic en_i,
    input logic signed [Bits-1:0] value_i,
    input logic signed [Bits-1:0] mult_i,
    input logic signed [2*Bits-1:0] add_i,
    output logic signed [2*Bits-1:0] mac_o
);

  logic [2*Bits-1:0] mult, mac_result;
  assign mult = mult_i * value_i;
  assign mac_result = mult + add_i;

  always_ff @(posedge clk_i) begin
    if (en_i) mac_o <= mac_result;
  end
endmodule
