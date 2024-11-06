// A multiply-accumulate (MAC) module
// Operates on integer values.
module mac_shifter #(
    parameter N = 16
  )(
    input logic clk_i,
    input logic en_i,
    input logic signed [N-1:0] value_i,
    input logic signed [N-1:0] mult_i,
    input logic signed [2*N-1:0] add_i, //already shifted
    input logic [5:0] shift_i,
    output logic signed [2*N-1:0] mac_o
  );

  logic [2*N-1:0] mult, mac_result;
  assign mult = mult_i * value_i;
  assign mac_result = (mult >>> shift_i) + add_i;

  always_ff @(posedge clk_i)
  begin
    if (en_i)
      mac_o <= mac_result;
  end
endmodule
