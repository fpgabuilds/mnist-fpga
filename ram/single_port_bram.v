// TODO: Add test cases
// TODO: Add asserts to ensure reading withing bounds
module single_port_bram #(
    parameter DataWidth = 8,
    parameter Depth = 1024
  ) (
    input wire clk_i,
    input wire write_en_i,
    input wire [$clog2(Depth):0] addr_i,
    input wire [DataWidth-1:0] data_i,
    output reg [DataWidth-1:0] data_o
  );

  reg [DataWidth-1:0] memory [0:Depth-1];

  always @(posedge clk_i)
  begin
    if (write_en_i)
    begin
      memory[addr_i] <= data_i;
    end
    data_o <= memory[addr_i];
  end
endmodule
