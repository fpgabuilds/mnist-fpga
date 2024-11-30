module activation_relu #(
    parameter unsigned N
) (
    input logic clk_i,
    input logic en_i,
    input logic signed [N-1:0] value_i,
    output logic signed [N-1:0] value_o
);

  always_comb begin
    value_o = (value_i > 0) ? value_i : 0;
  end
endmodule
