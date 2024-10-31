module de10_lite_sdram #(
    parameter SdramClkRate = 143_000_000, // Speed of your SDRAM clock in Hz
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

  localparam IDLE = 2'b00;
  localparam WRITE = 2'b01;
  localparam READ = 2'b10;

  localparam CAS_LATENCY = 3;

  logic [15:0] bram_output;
  logic [15:0] bram_input;

  logic [5:0] burst_read_counter = 0;
  logic [5:0] burst_write_counter = 0;

  logic read_started;
  logic write_started;

  logic [1:0] command_buffer;

  shift_reg #(
              .N(2),
              .Length(1) // Add some write latency
            ) command_shift_inst (
              .clk_i,
              .en_i(1'b1),
              .rst_i(1'b0),
              .rst_val_i(2'b00),
              .data_i(command_i),
              .data_o(command_buffer)
            );

  always_ff @(posedge clk_i)
  begin
    if (command_buffer == WRITE)
      write_started <= 1'b1;
    else if (command_buffer == READ)
      read_started <= 1'b1;
    else if (burst_read_counter == SdramReadBurstLength)
      read_started <= 1'b0;
    else if (burst_write_counter == SdramWriteBurst ? SdramReadBurstLength : 6'b1)
      write_started <= 1'b0;
  end

  increment_then_stop #(
                        .Bits(6) // Number of bits in the counter, this can be found using $clog2(N+1) where N is the maximum value of the counter
                      ) burst_read_counter_inst (
                        .clk_i, // Clock input
                        .run_i(read_started), // Run signal, when high the counter will increment, when low the counter will not change but will hold the current value
                        .rst_i(rst_i || (command_buffer == IDLE && !read_started)), // Reset signal, when low the counter will be reset to the start value. Not tied to the clock
                        .start_val_i(6'b0), // The value the counter will be set to when rst_i is high
                        .end_val_i(SdramReadBurstLength+1), // The value the counter will stop at
                        .count_o(burst_read_counter) // The current value of the counter, will start at start_val_i and increment until end_val_i
                      );

  increment_then_stop #(
                        .Bits(6)
                      ) burst_write_counter_inst (
                        .clk_i,
                        .run_i(write_started),
                        .rst_i(rst_i || (command_buffer == IDLE && !write_started)),
                        .start_val_i(6'd0),
                        .end_val_i(SdramWriteBurst ? SdramReadBurstLength : 6'b1),
                        .count_o(burst_write_counter)
                      );

  single_port_bram #(
                     .DataWidth(16),
                     .Depth(33_554_432)
                   ) memory_store_inst (
                     .clk_i,
                     .write_en_i(write_started),
                     .addr_i({{1'b0}, {write_started? data_address_i + burst_write_counter : data_address_i + burst_read_counter}}),
                     .data_i(data_write_i),
                     .data_o(bram_output)
                   );



  shift_reg #(
              .N(17),
              .Length(CAS_LATENCY - 1)
            ) read_shift_reg_inst (
              .clk_i,
              .en_i(1'b1),
              .rst_i(1'b0),
              .rst_val_i(17'h0),
              .data_i((read_started) ? {{1'b1},{bram_output}} : 17'h0),
              .data_o({data_read_valid_o, data_read_o})
            );

  assign data_write_done_o = command_buffer == WRITE;


  // Output control signals
  assign sdram_clk_en_o = 1'b1;
  assign sdram_bank_activate_o = 1'b0;
  assign sdram_address_o = 12'b0;
  assign sdram_cs_o = 1'b0;
  assign sdram_row_addr_strobe_o = 1'b0;
  assign sdram_column_addr_strobe_o = 1'b0;
  assign sdram_we_o = (command_i == 2'b01);
  assign sdram_dqm_o = 2'b00;
  assign sdram_dq_io = 16'b0;

endmodule


module tb_sim_de10_lite_sdram;

  // Parameters
  parameter SdramClkRate = 143_000_000;
  parameter SdramReadBurstLength = 8;
  parameter SdramWriteBurst = 1;

  // Signals
  logic clk_i;
  logic rst;
  logic [1:0] command_i;
  logic [24:0] data_address_i; // Adjusted width to match the parameterized address width
  logic [15:0] data_write_i;
  logic [15:0] data_read_o;
  logic data_read_valid_o;
  logic data_write_done_o;

  // Instantiate the DUT
  de10_lite_sdram #(
                    .SdramClkRate(SdramClkRate),
                    .SdramReadBurstLength(SdramReadBurstLength),
                    .SdramWriteBurst(SdramWriteBurst)
                  ) uut (
                    .clk_i(clk_i),
                    .rst_i(rst),
                    .command_i(command_i),
                    .data_address_i(data_address_i),
                    .data_write_i(data_write_i),
                    .data_read_o(data_read_o),
                    .data_read_valid_o(data_read_valid_o),
                    .data_write_done_o(data_write_done_o),

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
  initial
  begin
    clk_i = 0;
    forever
      #3.5 clk_i = ~clk_i; // 143 MHz clock
  end

  // Testbench logic
  initial
  begin
    integer i, j;
    reg [24:0] random_address;
    reg [15:0] write_data_buffer [0:SdramReadBurstLength-1];
    reg [15:0] read_data_buffer [0:SdramReadBurstLength-1];

    // Initialize inputs
    command_i = 2'b00;
    data_address_i = 0;
    data_write_i = 0;
    rst = 1;
    @(posedge clk_i);
    @(posedge clk_i);
    rst = 0;

    // Wait for a few clock cycles
    #10;

    // Loop 1000 times
    for (i = 0; i < 1000; i = i + 1)
    begin
      // Generate random address
      random_address = $random;

      // Prepare write data
      for (j = 0; j < SdramReadBurstLength; j = j + 1)
      begin
        write_data_buffer[j] = $random;
      end

      // Write operation
      @(posedge clk_i);
      command_i = 2'b01; // Write command
      data_address_i = random_address;
      data_write_i = write_data_buffer[0];
      @(posedge clk_i);
      command_i = 2'b00; // Idle command

      // Wait for write burst to start
      wait(data_write_done_o);

      // Write burst
      for (j = 1; j < SdramReadBurstLength; j = j + 1)
      begin
        @(posedge clk_i);
        if (j > 0)
        begin
          data_write_i = write_data_buffer[j];
        end
      end

      // Wait for write burst to complete
      @(posedge clk_i);
      @(posedge clk_i);

      // Read operation
      @(posedge clk_i);
      command_i = 2'b10; // Read command
      data_address_i = random_address;
      @(posedge clk_i);
      command_i = 2'b00; // Idle command

      // Wait for read burst to start
      wait(data_read_valid_o);

      // Read burst
      for (j = 0; j < SdramReadBurstLength; j = j + 1)
      begin
        @(posedge clk_i);
        if (data_read_valid_o)
        begin
          read_data_buffer[j] = data_read_o;
        end
      end

      // Verify read data
      for (j = 0; j < SdramReadBurstLength; j = j + 1)
      begin
        if (read_data_buffer[j] !== write_data_buffer[j])
        begin
          $display("Data mismatch at iteration %0d, burst index %0d: expected %0h, got %0h", i, j, write_data_buffer[j], read_data_buffer[j]);
        end
      end

      @(posedge clk_i);
      @(posedge clk_i);
    end

    $display("Test completed.");
    $stop;
  end

endmodule
