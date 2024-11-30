module core_d_ff #(
    /// Bit width of the data, leave off for 1 bit
    parameter unsigned Bits = 1
) (
    input logic clk_i,
    input logic rst_i,
    input logic en_i,
    input logic [Bits-1:0] data_i,
    output logic [Bits-1:0] data_o
);

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      data_o <= {Bits{1'b0}};
    end else if (en_i) begin
      data_o <= data_i;
    end
  end
endmodule
