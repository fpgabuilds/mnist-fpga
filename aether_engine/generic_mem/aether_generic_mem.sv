//TODO this memory is weird mix between sdram and bram
module aether_generic_mem #(  // This is simulation ram
    parameter unsigned ClkRate = 143_000_000
) (
    input logic clk_i,
    input logic en_i,
    input logic rst_i,
    input logic [1:0] command_i,
    input logic [31:0] start_address_i,
    input logic [31:0] end_address_i,
    input logic [15:0] data_write_i,
    output logic [15:0] data_read_o,
    output logic data_read_valid_o,
    output logic data_write_ready_o,
    output logic task_finished_o,  //TODO: this goes high on reset
    output logic mem_running_o,

    // These ports should be connected directly to the SDRAM chip
    output logic sdram_clk_en_o,
    output logic [2-1:0] sdram_bank_activate_o,
    output logic [13-1:0] sdram_address_o,
    output logic sdram_cs_o,
    output logic sdram_row_addr_strobe_o,
    output logic sdram_column_addr_strobe_o,
    output logic sdram_we_o,
    output logic [2-1:0] sdram_dqm_o,
    inout wire [16-1:0] sdram_dq_io,

    input logic assert_on_i
);
  localparam logic [1:0] IDLE = 2'b00;
  localparam logic [1:0] WRITE = 2'b01;
  localparam logic [1:0] READ = 2'b10;

  logic [1:0] mem_command_mid;
  logic [1:0] mem_command;

  always @(posedge clk_i) begin
    if (assert_on_i) begin
      assert (command_i == IDLE || command_i == WRITE || command_i == READ)
      else $error("mem_command must be 0, 1, or 2");
      assert (addr_count < {25{1'b1}})
      else $error("addr_count must be less than 2^25");
    end
  end

  logic [31:0] end_address_buffer;
  logic [31:0] start_address_buffer;

  core_delay #(
      .Bits (32),
      .Delay(1)
  ) end_address_buffer_inst (
      .clk_i,
      .rst_i,
      .en_i  (mem_command == IDLE && command_i != IDLE),
      .data_i(end_address_i),
      .data_o(end_address_buffer),
      .assert_on_i
  );

  core_delay #(
      .Bits (32),
      .Delay(1)
  ) start_address_buffer_inst (
      .clk_i,
      .rst_i,
      .en_i  (mem_command == IDLE && command_i != IDLE),
      .data_i(start_address_i),
      .data_o(start_address_buffer),
      .assert_on_i
  );

  core_d_ff #(
      .Bits(2)
  ) command_buffer (
      .clk_i,
      .rst_i (task_finished_o || rst_i),
      .en_i  (command_i != IDLE),
      .data_i(command_i),
      .data_o(mem_command_mid)
  );

  core_d_ff #(
      .Bits(2)
  ) command_buffer_2 (
      .clk_i,
      .rst_i (task_finished_o || rst_i),
      .en_i  (mem_command_mid != IDLE && (en_i || mem_command_mid == READ)),
      .data_i(mem_command_mid),
      .data_o(mem_command)
  );


  logic [31:0] addr_count;  // Total count

  increment_then_stop #(
      .Bits(32)
  ) addr_counter (
      .clk_i,
      .en_i(mem_command != IDLE && (en_i || mem_command == READ)),
      .rst_i((mem_command == IDLE) || rst_i),
      .start_val_i(start_address_buffer),
      .end_val_i(end_address_buffer),
      .count_o(addr_count),
      .assert_on_i
  );

  logic [15:0] bram_output;
  core_bram_single_port #(
      .DataWidth(16),
      .Depth(2 ** 16 - 1)
  ) memory_store_inst (
      .clk_i,
      .write_en_i(mem_command == WRITE),
      .addr_i(addr_count[15:0]),
      .data_i(data_write_i),
      .data_o(bram_output)
  );

  logic task_finished_mid;
  core_d_ff task_finished_middle_inst (
      .clk_i,
      .rst_i (),
      .en_i  (1'b1),
      .data_i(addr_count == end_address_buffer && end_address_buffer != 0),
      .data_o(task_finished_mid)
  );

  core_d_ff task_finished_inst (
      .clk_i,
      .rst_i (rst_i),
      .en_i  (1'b1),
      .data_i(task_finished_mid),
      .data_o(task_finished_o)
  );

  core_d_ff data_valid_buffer (
      .clk_i,
      .rst_i (task_finished_o),
      .en_i  (1'b1),
      .data_i(mem_command == READ),
      .data_o(data_read_valid_o)
  );

  assign data_read_o = (mem_command == READ) ? bram_output : 16'h0000;
  assign data_write_ready_o = (mem_command == WRITE) || (mem_command_mid == WRITE);
  assign mem_running_o = (mem_command != IDLE) || (mem_command_mid != IDLE);

  //unused ports

  assign sdram_clk_en_o = 1'b0;
  assign sdram_bank_activate_o = 2'b00;
  assign sdram_address_o = 13'h0000;
  assign sdram_cs_o = 1'b0;
  assign sdram_row_addr_strobe_o = 1'b0;
  assign sdram_column_addr_strobe_o = 1'b0;
  assign sdram_we_o = 1'b0;
  assign sdram_dqm_o = 2'b00;
  assign sdram_dq_io = 16'h0000;
endmodule



// module aether_engine_generic_mem #(
//     parameter ClkRate = 143_000_000
//   ) (
//     input logic clk_i,
//     input logic [1:0] command_i,
//     input logic [31:0] start_address_i,
//     input logic [31:0] end_address_i,
//     input logic [15:0] data_write_i,
//     output logic [15:0] data_read_o,
//     output logic data_read_valid_o,
//     output logic data_write_ready_o,
//     output logic task_finished_o,

//     // These ports should be connected directly to the SDRAM chip
//     output logic sdram_clk_en_o,
//     output logic [2-1:0] sdram_bank_activate_o,
//     output logic [13-1:0] sdram_address_o,
//     output logic sdram_cs_o,
//     output logic sdram_row_addr_strobe_o,
//     output logic sdram_column_addr_strobe_o,
//     output logic sdram_we_o,
//     output logic [2-1:0] sdram_dqm_o,
//     inout wire [16-1:0] sdram_dq_io
//   );

//   localparam IDLE = 2'b00;
//   localparam WRITE = 2'b01;
//   localparam READ = 2'b10;

//   always @(posedge clk_i)
//   begin
//     assert (command_i == IDLE || command_i == WRITE || command_i == READ) else
//              $error("command_i must be 0, 1, or 2");
//     assert (addr_count < {25{1'b1}}) else
//              $error("addr_count must be less than 2^25");
//   end



//   logic [31:0] addr_count; // Total count
//   logic [24:0] data_address; // Address sent to sdram taken from addr_count

//   logic [1:0] command_buffer; // buffered command, keeps value for whole task
//   logic [1:0] mem_command; // command to be sent to the sdram
//   logic busy; // memory is busy


//   increment_then_stop #(
//                         .Bits(32)
//                       ) addr_counter (
//                         .clk_i,
//                         .en_i(!busy),
//                         .rst_i(command_i != IDLE),
//                         .start_val_i(start_address_i),
//                         .end_val_i(end_address_i),
//                         .count_o(addr_count),
//                         .assert_on_i(1'b1)
//                       );


//   core_sr_ff  #( // Store the command for the whole task
//            .Width(2)
//          ) cmd_buffer (
//            .clk_i,
//            .rst_i(1'b0),
//            .en_i(1'b1),
//            .s(command_i),
//            .r(task_finished_o),
//            .data_o(command_buffer)
//          );

//   core_sr_ff  #(
//            .Width(1)
//          ) busy_inst (
//            .clk_i,
//            .rst_i(command_i != IDLE),
//            .en_i(1'b1),
//            .s(mem_command == READ || mem_command == WRITE),
//            .r(data_read_valid_o || data_write_done_o),
//            .data_o(busy)
//          );


//   assign data_address = addr_count[24:0];
//   assign task_finished_o = (addr_count == end_address_i) && !busy;

//   assign mem_command = (~busy) ? command_buffer : IDLE;

//   de10_lite_sdram #(
//                     .SdramClkRate(ClkRate), // Speed of your sdram clock in Hz
//                     .SdramReadBurstLength(1), // 1, 2, 4, 8. All other values are reserved.
//                     .SdramWriteBurst(1) // OFF = Single write mode, ON = Burst write mode (same length as read burst)
//                   ) de10_ram_inst (
//                     .clk_i,

//                     // 0 = Idle
//                     // 1 = Write (with Auto Precharge)
//                     // 2 = Read (with Auto Precharge)
//                     .command_i(mem_command),
//                     .data_address_i(data_address), // BANK_ADDRESS_WIDTH + ROW_ADDRESS_WIDTH + COLUMN_ADDRESS_WIDTH
//                     .data_write_i,
//                     .data_read_o,
//                     .data_read_valid_o, // goes high when a burst-read is ready
//                     .data_write_done_o, // goes high once the first write of a burst-write / single-write is done

//                     // These ports should be connected directly to the SDRAM chip
//                     .sdram_clk_en_o,
//                     .sdram_bank_activate_o,
//                     .sdram_address_o,
//                     .sdram_cs_o,
//                     .sdram_row_addr_strobe_o,
//                     .sdram_column_addr_strobe_o,
//                     .sdram_we_o,
//                     .sdram_dqm_o,
//                     .sdram_dq_io
//                   );

// endmodule
