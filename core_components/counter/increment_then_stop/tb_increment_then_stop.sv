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
