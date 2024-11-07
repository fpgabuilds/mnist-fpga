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

    execute_cmd({RST, RST_FULL, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    assert_on = 1'b1;
    // Loading weights
    execute_cmd({WRR, REG_MSTRT, 16'h0000});
    execute_cmd({WRR, REG_MENDD, 16'h0011});
    execute_cmd({LDW, LDW_STRT, 16'h0000});
    // Conv3x3 Layer: conv1
    execute_cmd({LDW, LDW_CONT, 16'h6261});
    execute_cmd({LDW, LDW_CONT, 16'h2A63});
    execute_cmd({LDW, LDW_CONT, 16'h4023});
    execute_cmd({LDW, LDW_CONT, 16'h797A});
    execute_cmd({LDW, LDW_CONT, 16'h7078});
    execute_cmd({LDW, LDW_MOVE, 16'h0000});
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
    // Weight loading complete
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
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hA1FF});
    execute_cmd({LIP, LIP_CONT, 16'hB800});
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
    execute_cmd({LIP, LIP_CONT, 16'h2BE7});
    execute_cmd({LIP, LIP_CONT, 16'hC208});
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
    execute_cmd({LIP, LIP_CONT, 16'h0264});
    execute_cmd({LIP, LIP_CONT, 16'hFF80});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hDDFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'h89FF});
    execute_cmd({LIP, LIP_CONT, 16'h1803});
    execute_cmd({LIP, LIP_CONT, 16'hFFE8});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hDFFF});
    execute_cmd({LIP, LIP_CONT, 16'h7F3D});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'h18FF});
    execute_cmd({LIP, LIP_CONT, 16'h4902});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'h2AE1});
    execute_cmd({LIP, LIP_CONT, 16'hEB2F});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'h0479});
    execute_cmd({LIP, LIP_CONT, 16'hF30C});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'h02B5});
    execute_cmd({LIP, LIP_CONT, 16'hFFDD});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hD9FF});
    execute_cmd({LIP, LIP_CONT, 16'h0216});
    execute_cmd({LIP, LIP_CONT, 16'hFF7F});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'h0242});
    execute_cmd({LIP, LIP_CONT, 16'hFFE2});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hA6FF});
    execute_cmd({LIP, LIP_CONT, 16'h0202});
    execute_cmd({LIP, LIP_CONT, 16'hFF8E});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'h028C});
    execute_cmd({LIP, LIP_CONT, 16'hFD86});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'h17D9});
    execute_cmd({LIP, LIP_CONT, 16'h4902});
    execute_cmd({LIP, LIP_CONT, 16'hFFFD});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'h0CC8});
    execute_cmd({LIP, LIP_CONT, 16'h8402});
    execute_cmd({LIP, LIP_CONT, 16'hFFE4});
    execute_cmd({LIP, LIP_CONT, 16'h0271});
    execute_cmd({LIP, LIP_CONT, 16'h5802});
    execute_cmd({LIP, LIP_CONT, 16'h6286});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hA5FF});
    execute_cmd({LIP, LIP_CONT, 16'h020A});
    execute_cmd({LIP, LIP_CONT, 16'h3C22});
    execute_cmd({LIP, LIP_CONT, 16'h0213});
    execute_cmd({LIP, LIP_CONT, 16'h0202});
    execute_cmd({LIP, LIP_CONT, 16'hCB53});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'h63DB});
    execute_cmd({LIP, LIP_CONT, 16'h0202});
    execute_cmd({LIP, LIP_CONT, 16'h1F02});
    execute_cmd({LIP, LIP_CONT, 16'hCC61});
    execute_cmd({LIP, LIP_CONT, 16'hFFFE});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFEFF});
    execute_cmd({LIP, LIP_CONT, 16'h57E8});
    execute_cmd({LIP, LIP_CONT, 16'h4F02});
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
    execute_cmd({LIP, LIP_CONT, 16'h03E7});
    execute_cmd({LIP, LIP_CONT, 16'hE020});
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
    execute_cmd({LIP, LIP_CONT, 16'h02D9});
    execute_cmd({LIP, LIP_CONT, 16'hFF81});
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
    execute_cmd({LIP, LIP_CONT, 16'hFBFF});
    execute_cmd({LIP, LIP_CONT, 16'h0228});
    execute_cmd({LIP, LIP_CONT, 16'hFFB3});
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
    execute_cmd({LIP, LIP_CONT, 16'hF9FF});
    execute_cmd({LIP, LIP_CONT, 16'h0C02});
    execute_cmd({LIP, LIP_CONT, 16'hFFC6});
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
    execute_cmd({LIP, LIP_CONT, 16'h9AFF});
    execute_cmd({LIP, LIP_CONT, 16'h2B02});
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
    execute_cmd({LIP, LIP_CONT, 16'h82FF});
    execute_cmd({LIP, LIP_CONT, 16'hB60B});
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
    execute_cmd({LIP, LIP_CONT, 16'h85FF});
    execute_cmd({LIP, LIP_CONT, 16'hFFBB});
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
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    execute_cmd({LIP, LIP_CONT, 16'hFFFF});
    // Conv3x3 Layer: conv1
    execute_cmd({WRR, REG_BCFG1, 16'h8002});
    execute_cmd({WRR, REG_BCFG2, 16'h001C});
    execute_cmd({WRR, REG_BCFG3, 16'h0000});
    // Conv3x3 Layer: conv1, chunk 0
    execute_cmd({WRR, REG_MENDD, 16'h0008});
    execute_cmd({WRR, REG_MSTRT, 16'h0000});
    execute_cmd({LDW, LDW_CWGT, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    execute_cmd({NOP, 4'h0, 16'h0000});
    $error("Nothing Else Implemented");
    $stop;
    execute_cmd({WRR, REG_CPRM1, 16'h0048});
    execute_cmd({CNV, 4'h0, 16'h0000});


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
