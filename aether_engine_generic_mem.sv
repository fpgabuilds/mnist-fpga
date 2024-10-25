module aether_engine_generic_mem #(
    parameter ClkRate = 143_000_000
  ) (
    input logic clk_i,
    input logic [1:0] command_i,
    input logic [31:0] start_address_i,
    input logic [31:0] count_total_i,
    input logic [15:0] data_write_i,
    output logic [15:0] data_read_o,
    output logic data_read_valid_o,
    output logic data_write_done_o,
    output logic task_finished_o,

    // These ports should be connected directly to the SDRAM chip
    output logic sdram_clk_en_o,
    output logic [2-1:0] sdram_bank_activate_o,
    output logic [13-1:0] sdram_address_o,
    output logic sdram_cs_o,
    output logic sdram_row_addr_strobe_o,
    output logic sdram_column_addr_strobe_o,
    output logic sdram_we_o,
    output logic [2-1:0] sdram_dqm_o,
    inout wire [16-1:0] sdram_dq_io
  );

  localparam IDLE = 2'b00;
  localparam WRITE = 2'b01;
  localparam READ = 2'b10;

  always @(posedge clk_i)
  begin
    assert (command_i == IDLE || command_i == WRITE || command_i == READ) else
             $error("command_i must be 0, 1, or 2");
    assert (addr_count < {25{1'b1}}) else
             $error("addr_count must be less than 2^25");
  end



  logic [31:0] addr_count; // Total count
  logic [24:0] data_address; // Address sent to sdram taken from addr_count

  logic [1:0] command_buffer; // buffered command, keeps value for whole task
  logic [1:0] mem_command; // command to be sent to the sdram
  logic busy; // memory is busy


  increment_then_stop #(
                        .Bits(32)
                      ) addr_counter (
                        .clk_i,
                        .run_i(!busy),
                        .rst_i(command_i != IDLE),
                        .start_val_i(start_address_i),
                        .end_val_i(start_address_i + count_total_i),
                        .count_o(addr_count)
                      );


  sr_ff  #( // Store the command for the whole task
           .Width(2)
         ) cmd_buffer (
           .clk_i,
           .rst_i(1'b0),
           .en_i(1'b1),
           .s(command_i),
           .r(task_finished_o),
           .data_o(command_buffer)
         );

  sr_ff  #(
           .Width(1)
         ) busy_inst (
           .clk_i,
           .rst_i(command_i != IDLE),
           .en_i(1'b1),
           .s(mem_command == READ || mem_command == WRITE),
           .r(data_read_valid_o || data_write_done_o),
           .data_o(busy)
         );


  assign data_address = addr_count[24:0];
  assign task_finished_o = (addr_count == start_address_i + count_total_i) && !busy;

  assign mem_command = (~busy) ? command_buffer : IDLE;

  de10_lite_sdram #(
                    .SdramClkRate(ClkRate), // Speed of your sdram clock in Hz
                    .SdramReadBurstLength(1), // 1, 2, 4, 8. All other values are reserved.
                    .SdramWriteBurst(1) // OFF = Single write mode, ON = Burst write mode (same length as read burst)
                  ) de10_ram_inst (
                    .clk_i,

                    // 0 = Idle
                    // 1 = Write (with Auto Precharge)
                    // 2 = Read (with Auto Precharge)
                    .command_i(mem_command),
                    .data_address_i(data_address), // BANK_ADDRESS_WIDTH + ROW_ADDRESS_WIDTH + COLUMN_ADDRESS_WIDTH
                    .data_write_i,
                    .data_read_o,
                    .data_read_valid_o, // goes high when a burst-read is ready
                    .data_write_done_o, // goes high once the first write of a burst-write / single-write is done

                    // These ports should be connected directly to the SDRAM chip
                    .sdram_clk_en_o,
                    .sdram_bank_activate_o,
                    .sdram_address_o,
                    .sdram_cs_o,
                    .sdram_row_addr_strobe_o,
                    .sdram_column_addr_strobe_o,
                    .sdram_we_o,
                    .sdram_dqm_o,
                    .sdram_dq_io
                  );

endmodule
