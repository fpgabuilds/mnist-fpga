module tb_counter;
  parameter unsigned Bits = 8;

  logic clk;
  logic en;
  logic rst;
  logic [Bits-1:0] start_val;
  logic [Bits-1:0] end_val;
  logic [Bits-1:0] count_by;
  logic [Bits-1:0] count;

  counter #(
      .Bits(Bits)
  ) dut (
      .clk_i(clk),
      .en_i(en),
      .rst_i(rst),
      .start_val_i(start_val),
      .end_val_i(end_val),
      .count_by_i(count_by),
      .count_o(count),
      .assert_on_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    // Initialize inputs
    clk = 1'b0;
    en = 1'b0;
    rst = 1'b1;
    start_val = 8'h00;
    end_val = 8'h00;
    count_by = 8'h01;

    // Test 1: Reset behavior
    $display("Test 1: Reset behavior, Time: %0t", $time);
    start_val = 8'h55;
    end_val = 8'hFF;
    rst = 1'b1;
    @(negedge clk);
    rst = 1'b0;
    en  = 1'b1;
    #1;
    assert (count == 8'h55)
    else $error("Test 1 failed: count = %h, expected 55", count);

    // Test 2: Counting up by 1
    $display("Test 2: Counting up by 1, Time: %0t", $time);
    rst = 1'b1;
    start_val = 8'h00;
    end_val = 8'h0A;
    count_by = 8'h01;
    @(negedge clk);
    rst = 1'b0;
    en  = 1'b1;

    for (int i = 1; i <= 16; i++) begin
      @(posedge clk);
      #1;
      if (i <= 10)
        assert (count == i)
        else $error("Test 2 failed: count = %h, expected %h", count, i);
      else
        assert (count == i - 10)
        else $error("Test 2 failed: count = %h, expected %h", count, i - 10);
    end

    // Test 3: Counting up by 3
    $display("Test 3: Counting up by 3, Time: %0t", $time);
    rst = 1'b1;
    start_val = 8'h02;
    end_val = 8'h0E;
    count_by = 8'h03;
    @(negedge clk);
    rst = 1'b0;
    en  = 1'b1;

    for (int i = 1; i <= 6; i++) begin
      @(posedge clk);
      #1;
      assert (count == 8'h02 + (i * 3))
      else $error("Test 3 failed: count = %h, expected %h", count, 8'h02 + (i * 3));
    end
    @(posedge clk);
    #1;
    assert (count == 8'h02)
    else $error("Test 3 failed: count didn't wrap around to start_val");

    // Test 4: Enable/Disable counting
    $display("Test 4: Enable/Disable counting, Time: %0t", $time);
    rst = 1'b1;
    start_val = 8'h00;
    end_val = 8'hFF;
    count_by = 8'h01;
    @(negedge clk);
    rst = 1'b0;
    en  = 1'b1;
    repeat (5) @(posedge clk);
    en = 1'b0;
    repeat (5) @(posedge clk);
    en = 1'b1;
    #1;
    assert (count == 8'h05)
    else $error("Test 4 failed: count = %h, expected 05", count);

    // End simulation
    $display("All tests completed");
    #100 $finish;
  end

endmodule
