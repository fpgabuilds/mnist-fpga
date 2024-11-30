// D flip-flop with synchronous reset and enable
module core_d_ff_srst #(
    /// Bit width of the data, leave off for 1 bit
    parameter unsigned Bits = 1
) (
    input  logic clk_i,
    input  logic srst_i,
    input  logic en_i,
    input  logic data_i,
    output logic data_o
);
  always_ff @(posedge clk_i) begin
    if (srst_i) begin
      data_o <= {Bits{1'b0}};
    end else if (en_i) begin
      data_o <= data_i;
    end
  end
endmodule
