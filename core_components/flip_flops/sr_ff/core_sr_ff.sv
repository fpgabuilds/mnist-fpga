/// Typically Set and Reset are not active at the same time, and if it is then the defualt behavior would be undefined.
/// This is not the "typical" implementation, but instead defines the behavior when both are active as setting the value.
/// This is useful when having a running register, that is set at the start but cleared at the end.

module core_sr_ff (
    input  logic clk_i,
    input  logic rst_i,
    input  logic set_i,
    input  logic srst_i,
    output logic data_o,
    input  logic assert_on_i  /// No affect on the functionality, only for simulation validation
);
  always @(posedge clk_i) begin
    if (assert_on_i)
      assert (!(set_i && rst_i))
      else $error("Set and reset can not be active at the same time, defaulting to set");
  end

  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i) data_o <= 1'b0;
    else if (set_i) data_o <= 1'b1;
    else if (srst_i) data_o <= 1'b0;
endmodule

