module aether_engine_decoder (
    input logic clk_i,

    // Control Signals
    input logic [23:0] cmd_i, // command input
    output logic [15:0] data_o, // data output

    output logic buffer_full_o, // buffer full, do not send any more commands

    // Register Variables
    IVersion version,
    IRamAddrLow ram_addr_low,
    IRamAddrHigh ram_addr_high,

    IConvConfig1 conv_config_1,
    IConvConfig2 conv_config_2,
    IConvConfig3 conv_config_3,
    IConvConfig4 conv_config_4,

    IConvStatus conv_status,

    IInterrupt interrupt,

    IWriteToMem write_to_mem,
    IReadFromMem read_from_mem,

    // Convolution Weight Variables
    output logic conv_weight_rst_o,

    // Convolution Variables
    output logic conv_rst_o,
    output logic start_conv_o,

    // Ram Output
    output logic [63:0] ram_data_o,
    output logic [3:0] ram_task_o,
    output logic ram_data_valid_o
  );

  //------------------------------------------------------------------------------------
  // Instruction Definitions
  //------------------------------------------------------------------------------------
  localparam NOP = 4'b0000;
  localparam RESET = 4'b0001;
  localparam WRITE_REG = 4'b0010;
  localparam READ_REG = 4'b0011;
  localparam START_TASK = 4'b0100;


  //------------------------------------------------------------------------------------
  // Input Command Buffer
  //------------------------------------------------------------------------------------
  logic [23:0] last_cmd;
  logic [23:0] cmd_buffer;

  d_ff #( // Last Command
         .Width(24)
       ) d_ff_instruction (
         .clk_i,
         .rst_i(1'b0),
         .en_i(1'b1),
         .data_i(cmd_i),
         .data_o(last_cmd)
       );

  assign cmd_buffer = last_cmd; // TODO: This needs to be a fifo buffer
  assign buffer_full_o = 1'b0; // TODO: This needs to be calulated based on the fifo buffer


  //------------------------------------------------------------------------------------
  // No Operation Instruction
  //------------------------------------------------------------------------------------

  // This is a NOP instruction, do nothing


  //------------------------------------------------------------------------------------
  // Reset Instruction Instruction
  //------------------------------------------------------------------------------------
  localparam RST_ALL = 4'b0000;
  localparam RST_CONV = 4'b0001;
  localparam RST_CONV_WEIGHTS = 4'b0010;
  localparam TASK_RAM = 4'b0011; // Can be used to clear memory tasks from processing data, but probably bad idea

  logic task_ram_rst;
  logic rst_conv_rst;

  always_comb
  begin
    rst_conv_rst = 1'b0;
    conv_weight_rst_o = 1'b0;
    task_ram_rst = 1'b0;

    if (cmd_buffer[23:20] == RESET)
    begin
      case (cmd_buffer[19:16])
        RST_ALL:
        begin
          rst_conv_rst = 1'b1;
          conv_weight_rst_o = 1'b1;
        end
        RST_CONV:
          rst_conv_rst = 1'b1;
        RST_CONV_WEIGHTS:
          conv_weight_rst_o = 1'b1;
        TASK_RAM:
          task_ram_rst = 1'b1;
        default:
        begin
          $error("Invalid reset command");
          rst_conv_rst = 1'b0;
          conv_weight_rst_o = 1'b0;
          task_ram_rst = 1'b0;
        end
      endcase
    end
  end


  //------------------------------------------------------------------------------------
  // Write Register Instruction
  //------------------------------------------------------------------------------------
  always_comb
  begin
    if (cmd_buffer[23:20] == WRITE_REG)
    begin
      case (cmd_buffer[19:16])
        4'h0 :
          $error("Cannot write to version register");
        4'h1 :
          ram_addr_low.full_register = cmd_buffer[15:0];
        4'h2 :
          ram_addr_high.full_register = cmd_buffer[15:0];
        4'h3 :
          conv_config_1.full_register = cmd_buffer[15:0];
        4'h4 :
          conv_config_2.full_register = cmd_buffer[15:0];
        4'h5 :
          conv_config_3.full_register = cmd_buffer[15:0];
        4'h6 :
          conv_config_4.full_register = cmd_buffer[15:0];
        4'h7 :
          $error("Cannot write to status register");
        // 4'h8 :
        //   interrupt.write_enable_temp = cmd_buffer[15:0];
        4'hE :
          write_to_mem.full_register = cmd_buffer[15:0];
        4'hF :
          $error("Cannot write to read from memory register");
        default:
          $error("Invalid register write");
      endcase
    end
  end

  //------------------------------------------------------------------------------------
  // Read Reset Instruction
  //------------------------------------------------------------------------------------
  always_comb
  begin
    data_o = 16'h0000;

    if (cmd_buffer[23:20] == READ_REG)
    begin
      case (cmd_buffer[19:16])
        4'h0 :
          data_o = version.full_register;
        4'h1 :
          data_o = ram_addr_low.full_register;
        4'h2 :
          data_o = ram_addr_high.full_register;
        4'h3 :
          data_o = conv_config_1.full_register;
        4'h4 :
          data_o = conv_config_2.full_register;
        4'h5 :
          data_o = conv_config_3.full_register;
        4'h6 :
          data_o = conv_config_4.full_register;
        4'h7 :
          data_o = conv_status.full_register;
        4'h8 :
        begin
          data_o = interrupt.full_register;
          interrupt.mem_load_active = 1'b0;
          interrupt.conv_active = 1'b0;
          interrupt.dense_active = 1'b0;
        end
        4'hE :
          $error("Cannot read from write to memory register");
        4'hF :
          data_o = read_from_mem.full_register;
        default:
          $error("Invalid register read");
      endcase
    end
  end



  //------------------------------------------------------------------------------------
  // Start Task Instruction
  //------------------------------------------------------------------------------------
  localparam LOAD_CONV_WEIGHTS = 4'b0000;
  localparam LOAD_CONV_DATA = 4'b0001;
  localparam START_CONV = 4'b0010;
  localparam LOAD_DENSE_WEIGHTS = 4'b0011;
  localparam LOAD_DENSE_DATA = 4'b0100;
  localparam START_DENSE = 4'b0101;
  localparam WRITE_TO_MEM = 4'b0110;
  localparam READ_FROM_MEM = 4'b0111;

  logic ram_read_en;
  logic ram_write_en;
  logic task_conv_rst;
  logic [15:0] ram_addr_msb;

  assign ram_addr_msb = ram_addr_high.full_register;



  // aether_engine_tasked_ram tasked_ram (
  //                            .clk_i,
  //                            .rst_i(task_ram_rst),
  //                            .addr_i({ram_addr_msb, cmd_buffer[15:0]}),

  //                            // Read
  //                            .read_en_i(ram_read_en),
  //                            .task_i(cmd_buffer[19:16]),
  //                            .data_o(ram_data_o),
  //                            .task_o(ram_task_o),
  //                            .data_valid_o(ram_data_valid_o),

  //                            // Write
  //                            .data_i(64'h55AA55AA55AA55AA), // TODO: This needs to come from the register (maybe a fifo)
  //                            .write_en_i(ram_write_en),
  //                            .byte_en_i(8'b1) // If the register is fifo this can be calculated
  //                          );

  always_comb
  begin
    ram_read_en = 1'b0;
    ram_write_en = 1'b0;
    task_conv_rst = 1'b0;

    if (cmd_buffer[23:20] == START_TASK)
    begin
      case (cmd_buffer[19:16])
        LOAD_CONV_WEIGHTS:
          ram_read_en = 1'b1;
        LOAD_CONV_DATA:
          ram_read_en = 1'b1;
        START_CONV:
          task_conv_rst = 1'b1;
        WRITE_TO_MEM:
          ram_write_en = 1'b1; // TODO: Others will have to write data too
        READ_FROM_MEM:
          ram_read_en = 1'b1;
        default:
        begin
          $error("Invalid task command");
          ram_read_en = 1'b0;
          ram_write_en = 1'b0;
          task_conv_rst = 1'b0;
        end
      endcase
    end
  end


  //------------------------------------------------------------------------------------
  // Merge Signals from Different Instruction Types
  //------------------------------------------------------------------------------------
  assign conv_rst_o = rst_conv_rst | task_conv_rst;

endmodule
