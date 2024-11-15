// When reset is inbetween clock edges the counter will reset but on the next clock edge it will increment
// This will make the counter look like it is starting from start_val_i + 1 when only looking at the positive clock pulses
module increment_then_stop_srts #(
    parameter Bits = 8 // Number of bits in the counter, this can be found using $clog2(N+1) where N is the maximum value of the counter
  ) (
    input logic clk_i, // Clock input
    input logic en_i, // Run signal, when high the counter will increment, when low the counter will not change but will hold the current value
    input logic srst_i, // Reset signal, when low the counter will be reset to the start value. tied to the clock
    input logic [Bits-1:0] start_val_i, // The value the counter will be set to when rst_i is high
    input logic [Bits-1:0] end_val_i, // The value the counter will stop at
    output logic [Bits-1:0] count_o, // The current value of the counter, will start at start_val_i and increment until end_val_i
    input logic assert_on_i
  );
  always @(posedge clk_i)
  begin
    if (assert_on_i)
    begin
      if (en_i || srst_i)
        assert (end_val_i >= start_val_i) else
                 $error("end_val_i %h must be greater than or equal to start_val_i %h", end_val_i, start_val_i);
    end
  end


  logic [Bits-1:0] next_count;

  always_ff @ (posedge clk_i)
  begin
    if (srst_i)
      count_o <= start_val_i;
    else if (en_i)
      count_o <= next_count;
  end

  assign next_count = (count_o==end_val_i) ? end_val_i : count_o + {{Bits-1{1'b0}}, 1'b1};
endmodule
