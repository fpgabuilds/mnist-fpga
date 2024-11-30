module counter #(
    parameter unsigned Bits
) (
    input logic clk_i,
    input logic en_i,
    input logic rst_i,
    input logic [Bits-1:0] start_val_i,
    input logic [Bits-1:0] end_val_i,
    input logic [Bits-1:0] count_by_i,
    output logic [Bits-1:0] count_o,
    input logic assert_on_i
);
  always @(posedge clk_i) begin
    if (assert_on_i) begin
      assert (end_val_i >= start_val_i)
      else $error("end_val_i must be greater than or equal to start_val_i");
    end
  end

  logic [Bits-1:0] next_count;

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) count_o <= start_val_i;
    else if (en_i) count_o <= next_count;
  end
  assign next_count = (count_o == end_val_i) ? start_val_i : count_o + count_by_i;
endmodule
