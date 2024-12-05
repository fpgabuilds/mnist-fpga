module aether_top (
    input logic clk_i,
    input logic [23:0] cmd_i,
    output logic [15:0] data_o,
    output logic interrupt_o,

    output logic sdram_clk_en_o,
    output logic sdram_bank_activate_o,
    output logic [12:0] sdram_address_o,
    output logic sdram_cs_o,
    output logic sdram_row_addr_strobe_o,
    output logic sdram_column_addr_strobe_o,
    output logic sdram_we_o,
    output logic [3:0] sdram_dqm_o,
    inout logic [15:0] sdram_dq_io,

    //debugging
    output logic [15:0] dense_out_o
);

  logic assert_on;
  assign assert_on = 1'b0;

  aether_engine #(
      .DataWidth(8),
      .MaxMatrixSize(28),
      .ConvEngineCount(2),
      .DenseEngineCount(4),
      .ClkRate(143_000_000)
  ) accelerator_inst (
      .clk_i,
      .clk_data_i(clk_i),
      .instruction_i(cmd_i[23:20]),
      .param_1_i(cmd_i[19:16]),
      .param_2_i(cmd_i[15:0]),
      .data_o,
      .interrupt_o,

      .sdram_clk_en_o,
      .sdram_bank_activate_o,
      .sdram_address_o,
      .sdram_cs_o,
      .sdram_row_addr_strobe_o,
      .sdram_column_addr_strobe_o,
      .sdram_we_o,
      .sdram_dqm_o,
      .sdram_dq_io,
      .assert_on_i(assert_o),

      .dense_out_o
  );

endmodule
