// When reset is inbetween clock edges the counter will reset but on the next clock edge it will increment
// This will make the counter look like it is starting from start_val_i + 1 when only looking at the positive clock pulses
module increment_then_stop #(
    /// Number of bits in the counter, this can be found using $clog2(N+1) where N is the maximum value of the counter
    parameter unsigned Bits = 8
) (
    /// Clock input
    input logic clk_i,

    /// Run signal, when high the counter will increment, when low the counter will not change but will hold the current value
    input logic en_i,

    /// Reset signal, when low the counter will be reset to the start value. Not tied to the clock
    input logic rst_i,

    /// The value the counter will be set to when rst_i is high
    input logic [Bits-1:0] start_val_i,

    /// The value the counter will stop at
    input logic [Bits-1:0] end_val_i,

    /// The current value of the counter, will start at start_val_i and increment until end_val_i
    output logic [Bits-1:0] count_o,
    input logic assert_on_i
);
  always @(posedge clk_i) begin
    if (assert_on_i) begin
      if (en_i || rst_i)
        assert (end_val_i >= start_val_i)
        else
          $error(
              "End Val %h must be greater than or equal to Start Val %h", end_val_i, start_val_i
          );
    end
  end


  logic [Bits-1:0] next_count;

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) count_o <= start_val_i;
    else if (en_i) count_o <= next_count;
  end

  assign next_count = (count_o == end_val_i) ? end_val_i : count_o + {{Bits - 1{1'b0}}, 1'b1};
endmodule



module tb_increment_then_stop;
  parameter unsigned Bits = 8;

  logic clk;
  logic run;
  logic rst;
  logic [Bits-1:0] start_val;
  logic [Bits-1:0] end_val;
  logic [Bits-1:0] count;

  increment_then_stop #(
      .Bits(Bits)
  ) dut (
      .clk_i(clk),
      .en_i(run),
      .rst_i(rst),
      .start_val_i(start_val),
      .end_val_i(end_val),
      .count_o(count),
      .assert_on_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    // Initialize signals
    clk = 1'b0;
    run = 1'b0;
    rst = 1'b1;
    start_val = 8'h00;
    end_val = 8'h00;


    // Test 1: Extended reset
    $display("Test 1: Extended reset, Time: %0t", $time);
    start_val = 8'h00;
    end_val   = 8'hFF;
    @(negedge clk);
    rst = 1'b1;
    run = 1'b1;

    for (int i = 0; i < 10; i++) begin
      @(posedge clk);
      #1;
      if (i < 5) begin
        assert (count == start_val)
        else $error("Test 1 failed: count changed during reset");
      end else begin
        rst = 1'b0;
        assert (count == start_val + i - 5)
        else $error("Test 1 failed: count = %d, expected %d", count, start_val + i - 5);
      end
    end

    // Test 2: Asynchronous reset
    $display("Test 2: Asynchronous reset, Time: %0t", $time);
    rst = 1'b1;
    start_val = 8'h55;
    end_val = 8'hFF;
    @(negedge clk);
    rst = 1'b0;
    run = 1'b1;

    for (int i = 0; i < 15; i++) begin
      @(posedge clk);
      #1;
      if (i == 10) begin
        #3 rst = 1;
        #1;
        assert (count == 8'h55)  // Reset value
        else $error("Test 2 failed: async reset did not work");
        #1 rst = 0;
      end else if (i > 10) begin
        assert (count == 8'h55 + i - 10)
        else
          $error(
              "Test 2 failed: count = %d, expected %d", count, 8'h55 + i - 10
          );  // Count after reset
      end else begin
        assert (count == 8'h55 + i + 1)
        else
          $error(
              "Test 2 failed: count = %d, expected %d", count, 8'h55 + i + 1
          );  // Normal operation
      end
    end


    // Test 3: Start at zero and count to max
    $display("Test 3: Start at zero and count to max, Time: %0t", $time);
    rst = 1'b1;
    start_val = 8'h00;
    end_val = 8'hFF;
    @(negedge clk);
    rst = 1'b0;
    run = 1'b1;

    for (int i = 1; i <= 258; i++) begin
      @(posedge clk);
      #1;
      if (i < 256) begin
        assert (count == i)
        else $error("Test 3 failed: count = %d, expected %d", count, i);
      end else begin
        assert (count == 8'hFF)
        else $error("Test 3 failed: count did not stop at max value");
      end
    end

    // Test 4: Start at non-zero and count to max
    $display("Test 4: Start at non-zero and count to max, Time: %0t", $time);
    rst = 1'b1;
    start_val = 8'h80;
    end_val = 8'hFF;
    @(negedge clk);
    rst = 1'b0;
    run = 1'b1;

    for (int i = 1; i <= 130; i++) begin
      @(posedge clk);
      #1;
      if (i < 128) begin
        assert (count == 8'h80 + i)
        else $error("Test 4 failed: count = %d, expected %d", count, 8'h80 + i);
      end else begin
        assert (count == 8'hFF)
        else $error("Test 4 failed: count did not stop at max value");
      end
    end

    // Test 5: Start at zero and end below max
    $display("Test 5: Start at zero and end below max, Time: %0t", $time);
    rst = 1'b1;
    start_val = 8'h00;
    end_val = 8'h7F;
    @(negedge clk);
    rst = 1'b0;
    run = 1'b1;

    for (int i = 1; i <= 130; i++) begin
      @(posedge clk);
      #1;
      if (i < 128) begin
        assert (count == i)
        else $error("Test 5 failed: count = %d, expected %d", count, i);
      end else begin
        assert (count == 8'h7F)
        else $error("Test 5 failed: count did not stop at end value");
      end
    end

    // Test 6: Toggle run
    $display("Test 6: Toggle run, Time: %0t", $time);
    rst = 1'b1;
    start_val = 8'd50;
    end_val = 8'd100;
    @(negedge clk);
    rst = 1'b0;

    for (int i = 1; i <= 50; i++) begin
      run = 1'b1;
      @(posedge clk);
      #1;
      assert (count == 50 + i)
      else $error("Test 6 failed: count = %d, expected %d", count, 50 + i);

      run = 1'b0;
      @(posedge clk);
      #1;
      assert (count == 50 + i)
      else $error("Test 6 failed: count changed when run was low");
    end

    // End simulation
    $display("All tests completed");
    #100 $finish;
  end

endmodule
