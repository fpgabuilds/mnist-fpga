// TODO: Add test cases
// TODO: Allow for different port a and port b data widths
// TODO: Add asserts to check for read/write conflicts
// TODO: Add asserts to ensure reading withing bounds
module dual_port_bram #(
    parameter DataWidth = 8,
    parameter Depth = 1024
  ) (
    input wire clk_i,
    // Port A
    input wire a_write_en_i,
    input wire [$clog2(Depth):0] a_addr_i,
    input wire [DataWidth-1:0] a_data_i,
    output reg [DataWidth-1:0] a_data_o,
    // Port B
    input wire b_write_en_i,
    input wire [$clog2(Depth):0] b_addr_i,
    input wire [DataWidth-1:0] b_data_i,
    output reg [DataWidth-1:0] b_data_o
  );

  reg [DataWidth-1:0] memory [0:Depth-1];

  // Port A
  always @(posedge clk_i)
  begin
    a_data_o <= memory[a_addr_i];
    if (a_write_en_i)
    begin
      a_data_o <= a_data_i;
      memory[a_addr_i] <= a_data_i;
    end
  end

  // Port B
  always @(posedge clk_i)
  begin
    b_data_o <= memory[b_addr_i];
    if (b_write_en_i)
    begin
      b_data_o <= b_data_i;
      memory[b_addr_i] <= b_data_i;
    end
  end
endmodule

