module de10_lite_sdram #(
    parameter SdramClkRate = 143_000_000, // Speed of your sdram clock in Hz
    parameter SdramReadBurstLength = 1, // 1, 2, 4, 8. All other values are reserved.
    parameter SdramWriteBurst = 1 // OFF = Single write mode, ON = Burst write mode (same length as read burst)
  ) (
    input logic clk_i,

    // 0 = Idle
    // 1 = Write (with Auto Precharge)
    // 2 = Read (with Auto Precharge)
    input logic [1:0] command_i,
    input logic [2+13+10-1:0] data_address_i, // BANK_ADDRESS_WIDTH + ROW_ADDRESS_WIDTH + COLUMN_ADDRESS_WIDTH
    input logic [16-1:0] data_write_i,
    output logic [16-1:0] data_read_o,
    output logic data_read_valid_o, // goes high when a burst-read is ready
    output logic data_write_done_o, // goes high once the first write of a burst-write / single-write is done

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

  // Chip: IS42S16320D
  sdram_controller #(
                     .CLK_RATE(SdramClkRate), // Speed of your sdram clock in Hz
                     .READ_BURST_LENGTH(SdramReadBurstLength), // 1, 2, 4, 8, or 256 (full page). All other values are reserved.
                     .WRITE_BURST(SdramWriteBurst), // OFF = Single write mode, ON = Burst write mode (same length as read burst)
                     .BANK_ADDRESS_WIDTH(2),
                     .ROW_ADDRESS_WIDTH(13),
                     .COLUMN_ADDRESS_WIDTH(10),
                     .DATA_WIDTH(16),
                     .DQM_WIDTH(2),
                     .CAS_LATENCY(3),
                     // All parameters below are measured in floating point seconds (i.e. 1ns = 1E-9).
                     // They should be obtained from the datasheet for your chip.
                     .ROW_CYCLE_TIME(60E-9),
                     .RAS_TO_CAS_DELAY(15E-9),
                     .PRECHARGE_TO_REFRESH_OR_ROW_ACTIVATE_SAME_BANK_TIME(15E-9),
                     .ROW_ACTIVATE_TO_ROW_ACTIVATE_DIFFERENT_BANK_TIME(14E-9),
                     .ROW_ACTIVATE_TO_PRECHARGE_SAME_BANK_TIME(37E-9),
                     // Some SDRAM chips require a minimum clock stability time prior to initialization. If it's not in the datasheet, you can try setting it to 0.
                     .MINIMUM_STABLE_CONDITION_TIME(1E-4),
                     .MODE_REGISTER_SET_CYCLE_TIME(14E-9),
                     .WRITE_RECOVERY_TIME(14E-9),
                     .AVERAGE_REFRESH_INTERVAL_TIME(64E-3)
                   ) de_10_lite_sdram_inst (
                     .clk(clk_i),

                     // 0 = Idle
                     // 1 = Write (with Auto Precharge)
                     // 2 = Read (with Auto Precharge)
                     // 3 = Self Refresh (TODO)
                     .command(command_i),
                     .data_address(data_address_i),
                     .data_write(data_write_i),
                     .data_read(data_read_o),
                     .data_read_valid(data_read_valid_o), // goes high when a burst-read is ready
                     .data_write_done(data_write_done_o), // goes high once the first write of a burst-write / single-write is done

                     // These ports should be connected directly to the SDRAM chip
                     .clock_enable(sdram_clk_en_o),
                     .bank_activate(sdram_bank_activate_o),
                     .address(sdram_address_o),
                     .chip_select(sdram_cs_o),
                     .row_address_strobe(sdram_row_addr_strobe_o),
                     .column_address_strobe(sdram_column_addr_strobe_o),
                     .write_enable(sdram_we_o),
                     .dqm(sdram_dqm_o),
                     .dq(sdram_dq_io)
                   );
endmodule
