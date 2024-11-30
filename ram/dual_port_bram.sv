// TODO: Add test cases
// TODO: Add asserts to check for read/write conflicts
module dual_port_bram #(
    parameter unsigned DataWidth,
    parameter unsigned Depth
) (
    input logic clk_i,
    // Port A
    input logic a_write_en_i,
    input logic [$clog2(Depth+1)-1:0] a_addr_i,
    input logic [DataWidth-1:0] a_data_i,
    output logic [DataWidth-1:0] a_data_o,
    // Port B
    input logic b_write_en_i,
    input logic [$clog2(Depth+1)-1:0] b_addr_i,
    input logic [DataWidth-1:0] b_data_i,
    output logic [DataWidth-1:0] b_data_o,

    input logic assert_on_i
);
  always @(posedge clk_i) begin
    if (assert_on_i) begin
      assert (a_addr_i < Depth)
      else $error("Address A out of bounds: %h, Depth: %h", a_addr_i, Depth);
      assert (b_addr_i < Depth)
      else $error("Address B out of bounds: %h, Depth: %h", b_addr_i, Depth);
    end
  end

  logic [DataWidth-1:0] memory[0:Depth-1];

  // Port A
  always @(posedge clk_i) begin
    a_data_o <= memory[a_addr_i];
    if (a_write_en_i) begin
      a_data_o <= a_data_i;
      memory[a_addr_i] <= a_data_i;
    end
  end

  // Port B
  always @(posedge clk_i) begin
    b_data_o <= memory[b_addr_i];
    if (b_write_en_i) begin
      b_data_o <= b_data_i;
      memory[b_addr_i] <= b_data_i;
    end
  end
endmodule

// TODO: Add test cases
// TODO: Add asserts to check for read/write conflicts
// TODO: Verify this compiles to only a bram
module dual_port_bram2 #(
    parameter unsigned ADataWidth,
    parameter unsigned BDataWidth,
    parameter unsigned BitDepth,

    parameter unsigned AAddrSize = $clog2((BitDepth / ADataWidth) + 1),
    parameter unsigned BAddrSize = $clog2((BitDepth / BDataWidth) + 1)
) (
    // Port A
    input logic a_clk_i,
    input logic a_write_en_i,
    input logic [AAddrSize-1:0] a_addr_i,
    input logic [ADataWidth-1:0] a_data_i,
    output logic [ADataWidth-1:0] a_data_o,
    // Port B
    input logic b_clk_i,
    input logic b_write_en_i,
    input logic [BAddrSize-1:0] b_addr_i,
    input logic [BDataWidth-1:0] b_data_i,
    output logic [BDataWidth-1:0] b_data_o,

    input logic assert_on_i
);
  always @(posedge a_clk_i) begin
    if (assert_on_i) begin
      assert (a_addr_i < BitDepth / ADataWidth)
      else $error("Address A out of bounds");
    end
  end

  always @(posedge b_clk_i) begin
    if (assert_on_i) begin
      assert (b_addr_i < BitDepth / BDataWidth)
      else $error("Address B out of bounds");
    end
  end

  logic [BitDepth-1:0] memory;

  // Port A
  always_ff @(posedge a_clk_i) begin
    a_data_o <= memory[a_addr_i*ADataWidth+:ADataWidth];
    if (a_write_en_i) begin
      a_data_o <= a_data_i;
      memory[a_addr_i*ADataWidth+:ADataWidth] <= a_data_i;
    end
  end

  // Port B
  always_ff @(posedge b_clk_i) begin
    b_data_o <= memory[b_addr_i*BDataWidth+:BDataWidth];
    if (b_write_en_i) begin
      b_data_o <= b_data_i;
      memory[b_addr_i*BDataWidth+:BDataWidth] <= b_data_i;
    end
  end
endmodule

