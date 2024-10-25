module tb_aether_engine_example ();
  // First 4 bits
  localparam INST_NOP = 4'd0; // No Operation
  localparam INST_RST = 4'd1; // Reset
  localparam INST_RDR = 4'd2; // Read Register
  localparam INST_WRR = 4'd3; // Write Register
  localparam INST_LDW = 4'd4; // Load Weights
  localparam INST_CNV = 4'd5; // Run Convolution
  localparam INST_DNS = 4'd6; // Run Dense Layer

  // Instruction reset
  localparam RST_FULL = 4'd0;
  localparam RST_CWGT = 4'd1;
  localparam RST_CONV = 4'd2;
  localparam RST_DWGT = 4'd3;
  localparam RST_DENS = 4'd4;

  // Instruction Load weights
  localparam LDW_CWGT = 4'd1; // Load Convolution Weights
  localparam LDW_DWGT = 4'd2; // Load Dense Weights


  logic clk;
  logic [23:0] cmd;
  logic [15:0] data_output;

  aether_engine #(
                  .DataWidth(8),
                  .MaxMatrixSize(5),
                  .KernelSize(3),
                  .ConvEngineCount(2),
                  .ClkRate(143_000_000)
                ) accelerator_inst (
                  .clk_i(clk),
                  .clk_data_i(), // *(This is a stretch goal)*
                  .cmd_i(cmd),
                  .data_o(data_output),
                  .buffer_full_o(),
                  .sdram_clk_en_o(),
                  .sdram_bank_activate_o(),
                  .sdram_address_o(),
                  .sdram_cs_o(),
                  .sdram_row_addr_strobe_o(),
                  .sdram_column_addr_strobe_o(),
                  .sdram_we_o(),
                  .sdram_dqm_o(),
                  .sdram_dq_io()
                );

  // Clock generation
  always #5 clk = ~clk;

  // Define a task to execute a command on the positive edge of the clock
  task execute_cmd(input [23:0] command);
    @(posedge clk);
    cmd = command;
  endtask

  logic [23:0] commands[] = '{
          {INST_RST, RST_FULL, 16'b0},
          {INST_WRR, 4'h3, 16'd2},
          // TODO: implement something so I can do this {START_TASK, WRITE_TO_MEM, 16'd0},
          {INST_LDW, LDW_CWGT, 16'd8},
          {INST_CNV, 4'b1111, 16'd16}, //TODO: memory address correclty after loading data
          {INST_CNV, 4'b0011, 16'd24}, // (This is continuing the previous task)
          {INST_LDW, LDW_CWGT, 16'd1024},
          {INST_RST, RST_CONV, 16'b0}, // This is needed to clear the accumulator, it takes 1 cycle and should not be much of a problem, maybe load kernel does it?
          {INST_CNV, 4'b1111, 16'd16},
          {INST_CNV, 4'b0011, 16'd24}
        };

  initial
  begin
    clk = 1'b0;
    cmd = 24'b0;

    // Execute all commands in the array
    foreach (commands[i])
    begin
      begin
        execute_cmd(commands[i]);
      end
    end
  end
endmodule
