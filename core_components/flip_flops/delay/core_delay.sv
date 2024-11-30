module core_delay #(
    parameter unsigned Bits = 1,
    parameter unsigned Delay  /// Unit: Clock Cycles
) (
    input logic clk_i,
    input logic rst_i,  /// Resets all values in the delay to 0
    input logic en_i,
    input logic [Bits-1:0] data_i,
    output logic [Bits-1:0] data_o,

    input logic assert_on_i  /// Used in simulations to disable asserts statements
);
  /// Data storage for values in the delay
  logic [Bits-1:0] store[Delay-1:0];

  always @(posedge clk_i) begin : assert_valid
    if (assert_on_i) begin
      if (Delay == 0)
        assert (en_i)
        else $error("Can not have a zero delay");  // This should not be hard to add if needed
    end

  end

  generate
    if (Delay == 0) assign data_o = data_i;
    else begin : g_delay_prev_data
      genvar i;
      for (i = 0; i < Delay; i = i + 1) begin : g_delayblock
        always_ff @(posedge clk_i or posedge rst_i) begin
          if (rst_i) store[i] <= {Bits{1'b0}};
          else begin
            if (en_i) begin
              if (i == 0) store[i] <= data_i;
              else store[i] <= store[i-1];
            end
          end
        end
      end
      assign data_o = store[Delay-1];
    end
  endgenerate
endmodule
