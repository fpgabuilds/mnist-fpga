// TODO: Add test cases
// TODO: Add asserts to ensure reading withing bounds
module core_bram_single_port #(
    parameter unsigned DataWidth,
    parameter unsigned Depth
) (
    input logic clk_i,
    input logic write_en_i,
    input logic [$clog2(Depth+1)-1:0] addr_i,
    input logic [DataWidth-1:0] data_i,
    output logic [DataWidth-1:0] data_o
);

  reg [DataWidth-1:0] memory[0:Depth-1];

  always @(posedge clk_i) begin
    if (write_en_i) begin
      memory[addr_i] <= data_i;
    end
    data_o <= memory[addr_i];
  end
endmodule
