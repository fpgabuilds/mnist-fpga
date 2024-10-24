// A multiply-accumulate (MAC) module
// Operates on integer values.
module mac_shifter #(
    parameter N = 16
  )(
    input logic clk_i,
    input logic rst_i,
    input logic en_i,
    input logic signed [N-1:0] value_i,
    input logic signed [N-1:0] mult_i,
    input logic signed [2*N-1:0] add_i,
    output logic signed [2*N-1:0] mac_o,
    output logic shifted_o
  );

  logic [2*N-1:0] mult;
  logic [2*N:0] mac_result;
  logic [2*N-1:0] mac_shifted;
  assign mult = mult_i * value_i;
  assign mac_result = {{mult[2*N-1]},{mult}} + {{add_i[2*N-1]},{add_i}};

  always_comb
  begin
    if (mac_result[2*N:2*N-1] == 2'b00 || mac_result[2*N:2*N-1] == 2'b11)
    begin
      mac_shifted = mac_result[2*N-1:0];
      shifted_o = 1'b0;
    end
    else
    begin
      mac_shifted = mac_result[2*N:1];
      shifted_o = 1'b1;
    end
  end

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
      mac_o <= 0;
    else if (en_i)
      mac_o <= mac_shifted;
  end
endmodule
