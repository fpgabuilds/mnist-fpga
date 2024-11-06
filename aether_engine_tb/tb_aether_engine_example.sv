module tb_aether_engine_example ();
`include "../aether_constants.sv";

  logic clk;
  logic [23:0] cmd;
  logic [15:0] data_output;
  logic interrupt;
  logic assert_on;

  aether_engine #(
                  .DataWidth(8),
                  .MaxMatrixSize(28),
                  .ConvEngineCount(2),
                  .DenseEngineCount(4),
                  .ClkRate(143_000_000)
                ) accelerator_inst (
                  .clk_i(clk),
                  .clk_data_i(clk),
                  .instruction_i(cmd[23:20]),
                  .param_1_i(cmd[19:16]),
                  .param_2_i(cmd[15:0]),
                  .data_o(data_output),
                  .interrupt_o(interrupt),

                  .sdram_clk_en_o(),
                  .sdram_bank_activate_o(),
                  .sdram_address_o(),
                  .sdram_cs_o(),
                  .sdram_row_addr_strobe_o(),
                  .sdram_column_addr_strobe_o(),
                  .sdram_we_o(),
                  .sdram_dqm_o(),
                  .sdram_dq_io(),
                  .assert_on_i(assert_on)
                );

  // Clock generation
  always #5 clk = ~clk;

  // Define a task to execute a command on the positive edge of the clock
  task execute_cmd(input [23:0] command);
    @(posedge clk);
    cmd = command;
  endtask

  initial
  begin
    clk = 1'b0;
    cmd = 24'b0;
    assert_on = 1'b0;

    execute_cmd({RST, RST_FULL, 16'b0});
    execute_cmd({NOP, 20'h00000});
    assert_on = 1'b1; // I would like the reset to be able to be assert error free

    execute_cmd({WRR, REG_MSTRT, 16'h0000});
    execute_cmd({WRR, REG_MENDD, 16'h0011});
    execute_cmd({LDW, LDW_STRT, 16'h0000});
    execute_cmd({LDW, LDW_CONT, 16'h6261});
    execute_cmd({LDW, LDW_CONT, 16'h2A63});
    execute_cmd({LDW, LDW_MOVE, 16'h0000});
    execute_cmd({LDW, LDW_CONT, 16'h4023});
    execute_cmd({LDW, LDW_CONT, 16'h797A});
    execute_cmd({LDW, LDW_CONT, 16'h7078});
    execute_cmd({LDW, LDW_CONT, 16'h7271});
    execute_cmd({LDW, LDW_CONT, 16'h232A});
    execute_cmd({LDW, LDW_CONT, 16'h6D40});
    execute_cmd({LDW, LDW_CONT, 16'h6B6C});
    execute_cmd({LDW, LDW_CONT, 16'h6577});
    execute_cmd({LDW, LDW_CONT, 16'h2A72});
    execute_cmd({LDW, LDW_CONT, 16'h4023});
    execute_cmd({LDW, LDW_CONT, 16'h6A6E});
    execute_cmd({LDW, LDW_CONT, 16'h7569});
    execute_cmd({LDW, LDW_CONT, 16'h7776});
    execute_cmd({LDW, LDW_CONT, 16'h232A});
    execute_cmd({LDW, LDW_CONT, 16'h7440});
    execute_cmd({LDW, LDW_CONT, 16'h7273});
    execute_cmd({LIP, LIP_STRT, 16'h0000});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});



    // Load Weights
    //execute_cmd({WRR, REG_MSTRT, 16'd0});
    //execute_cmd({WRR, REG_MENDD, 16'd0});
    $error("Nothing Else Implemented");
    $stop;
    execute_cmd({LDW, LDW_CWGT, 16'hXXXX}); // Make this similar to the load input data with a start and cont
    //...
    execute_cmd({LDW, LDW_CWGT, 16'hXXXX}); // Actually moves from memory to the hardware

    execute_cmd({LIP, LIP_STRT, 16'hXXXX});
    execute_cmd({LIP, LIP_CONT, 16'hXXXX}); //Repeat for all image data
    // ...

    execute_cmd({CNV, 20'h00000}); // Start Conv, Don't save to ram  //First Conv
    execute_cmd({NOP, 20'h00000});

    @(posedge interrupt); //wait till its finished (it would be nice if we did not have to wait for the memory load task)
    execute_cmd({RDR, REG_STATS, 16'h0000}); // clear interrupts and can be used to see status
    execute_cmd({LDW, LDW_CWGT, 16'hXXXX}); // Actually moves from memory to the hardware
    execute_cmd({NOP, 20'h00000});
    @(posedge interrupt); //wait till its finished loading mem
    execute_cmd({RDR, REG_STATS, 16'h0000}); // clear interrupts and can be used to see status
    execute_cmd({WRR, REG_CPRM1, 16'h0044}); //Accumulate
    execute_cmd({CNV, 20'h00000}); // Start Conv, Don't save to ram  //Second Conv
    execute_cmd({NOP, 20'h00000});

    @(posedge interrupt); //wait till its finished (it would be nice if we did not have to wait for the memory load task)
    execute_cmd({RDR, REG_STATS, 16'h0000}); // clear interrupts and can be used to see status
    execute_cmd({LDW, LDW_CWGT, 16'hXXXX}); // Actually moves from memory to the hardware
    execute_cmd({NOP, 20'h00000});
    @(posedge interrupt); //wait till its finished loading mem
    execute_cmd({RDR, REG_STATS, 16'h0000}); // clear interrupts and can be used to see status

    execute_cmd({WRR, REG_CPRM1, 16'h0045}); //Accumulate and save to buffer
    execute_cmd({CNV, 20'hXXXX}); // Start Conv, Don't save to ram  //final
    execute_cmd({NOP, 20'h00000});
    @(posedge interrupt);
    execute_cmd({RDR, REG_STATS, 16'h0000}); // clear interrupts and can be used to see status

    execute_cmd({ROP, ROP_STRT, 16'h0000});
    execute_cmd({ROP, ROP_CONT, 16'h0000});
    //...

    $stop;

  end
endmodule
