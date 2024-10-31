module aether_engine #(
    parameter DataWidth = 8,

    // Convolution Configuration
    parameter [13:0] MaxMatrixSize = 16383, // maximum matrix size that this convolver can convolve
    parameter [9:0] ConvEngineCount = 1023, // Amount of instantiated convolvers // TODO: add this to an info register and create errors

    // Dense Configuration
    parameter DenseEngineCount = 1024, // Amount of instantiated dense layers // TODO: add this to an info register and create errors

    // Memory Configuration
    parameter ClkRate = 143_000_000
  ) (
    input logic clk_i, // clock
    input logic clk_data_i, // clock for input data TODO: implement this so that the main board can run at different speeds then the controller. *(This is a stretch goal)*
    // assign clk_data_i = clk_i; they should be set to the same for now

    // Control Signals
    input logic [3:0] instruction_i, // instruction input
    input logic [3:0] param_1_i, // parameter 1 input
    input logic [15:0] param_2_i, // parameter 2 input

    output logic [15:0] data_o, // data output
    output logic interrupt_o, // buffer full, do not input any more commands


    // These ports should be connected directly to the SDRAM chip
    output logic sdram_clk_en_o,
    output logic [1:0] sdram_bank_activate_o,
    output logic [12:0] sdram_address_o,
    output logic sdram_cs_o,
    output logic sdram_row_addr_strobe_o,
    output logic sdram_column_addr_strobe_o,
    output logic sdram_we_o,
    output logic [1:0] sdram_dqm_o,
    inout wire [15:0] sdram_dq_io
  );

`include "aether_constants.sv";

  //------------------------------------------------------------------------------------
  // Variable Definitions
  //------------------------------------------------------------------------------------

  // Decoder Interface
  logic [23:0] current_cmd;

  // Reset Signals
  logic rst_conv_weight;
  logic rst_conv;
  logic rst_dense_weight;
  logic rst_dense;

  // Load Weights Signals
  logic load_conv_weights;
  logic load_dense_weights;

  logic [31:0] conv_weight_mem_count;
  logic [31:0] dense_weight_mem_count;

  // Convolution Signals
  logic run_conv;
  logic [3:0] conv_count;
  logic [31:0] conv_mem_count;

  logic signed [DataWidth-1:0] conv_data [ConvEngineCount-1:0];
  logic conv_valid;

  // Dense Signals
  logic run_dense;
  logic [3:0] dense_count;

  logic [31:0] dense_mem_count;

  // Memory Signals
  logic [31:0] mem_addr_start;
  logic mem_load_enable;
  logic [15:0] mem_data_read;

  logic mem_data_read_valid;
  logic mem_data_write_done;
  logic mem_task_finished;


  localparam real Ratio = DataWidth / 16;

  //------------------------------------------------------------------------------------
  // Register Interfaces
  //------------------------------------------------------------------------------------

  IVersion version();
  IRamAddrLow ram_addr_low();
  IRamAddrHigh ram_addr_high();

  IConvConfig1 conv_config_1();
  IConvConfig2 conv_config_2();
  IConvConfig3 conv_config_3();
  IConvConfig4 conv_config_4();

  IConvStatus conv_status();

  IWriteToMem write_to_mem();
  IReadFromMem read_from_mem();



  //------------------------------------------------------------------------------------
  // Input Data Buffer
  //------------------------------------------------------------------------------------

  localparam InputBufferBits = MaxMatrixSize**2 * DataWidth;
  localparam AAddrSize = $clog2((InputBufferBits / 16) + 1);
  localparam BAddrSize = $clog2((InputBufferBits / DataWidth) + 1);

  logic [AAddrSize-1:0] input_buffer_addr;
  logic load_from_input_buffer;
  logic [BAddrSize-1:0] input_buffer_count;
  logic [DataWidth-1:0] input_buffer_data;

  simple_counter #(
                   .Bits(AAddrSize)
                 ) (
                   .clk_i(clk_data_i),
                   .en_i(instruction_i == LIP && param_1 == LIP_CONT), // Continue load input buffer
                   .rst_i(instruction_i == LIP && param_1 == LIP_STRT), // Start load input buffer
                   .count_o(input_buffer_addr)
                 );

  increment_then_stop #(
                        .Bits(BAddrSize)
                      ) (
                        .clk_i,
                        .run_i(load_from_input_buffer),
                        .rst_i(rst_conv),
                        .start_val_i({BAddrSize{1'b0}}),
                        .end_val_i(InputBufferBits / DataWidth),
                        .count_o(input_buffer_count)
                      );

  dual_port_bram2 #(
                    .ADataWidth(16),
                    .BDataWidth(DataWidth),
                    .BitDepth(InputBufferBits),
                    .AAddrSize(AAddrSize),
                    .BAddrSize(BAddrSize)
                  ) (
                    // Port A
                    .a_clk_i(clk_data_i),
                    .a_write_en_i(instruction_i == 4'h7),
                    .a_addr_i(input_buffer_addr),
                    .a_data_i(param_2_i),
                    .a_data_o(),
                    // Port B
                    .b_clk_i(clk_i),
                    .b_write_en_i(1'b0),
                    .b_addr_i(input_buffer_count),
                    .b_data_i({BAddrSize{1'b0}}),
                    .b_data_o(input_buffer_data)
                  );



  //------------------------------------------------------------------------------------
  // Convolution Weight Module
  //------------------------------------------------------------------------------------
  localparam KernelSize = 3;
  localparam ConvWeightSizeMem = KernelSize * KernelSize * Ratio;

  logic [DataWidth-1:0] conv_kernel_weights_unsigned [ConvEngineCount-1:0][KernelSize*KernelSize-1:0];
  logic signed [DataWidth-1:0] conv_kernel_weights [ConvEngineCount-1:0][KernelSize*KernelSize-1:0];

  generate
    for (genvar i = 0; i < ConvEngineCount; i++)
    begin
      for (genvar j = 0; j < KernelSize*KernelSize; j++)
      begin
        assign conv_kernel_weights[i][j] = $signed(conv_kernel_weights_unsigned[i][j]);
      end
    end
  endgenerate

  assign conv_weight_mem_count = conv_config_1.engine_count * ConvWeightSizeMem; // TODO: seems like a 4 dsp to preform this, fix later


  // Load data
  logic conv_weight_no_data;
  logic [DataWidth-1:0] conv_weight_data;

  fifo #(
         .InputWidth(16), // Memory Interface is 16 bits
         .OutputWidth(DataWidth),
         .Depth(4) // Can store 4 words
       ) conv_weight_fifo (
         .clk_i,
         .rst_i(rst_conv_weight),
         .write_en_i(load_conv_weights && mem_data_read_valid),
         .read_en_i(1'b1),
         .data_i(mem_data_read),
         .data_o(conv_weight_data),
         .full_o(),
         .empty_o(conv_weight_no_data)
       );

  localparam ConvEngineCountSize = $clog2(ConvEngineCount + 1);
  logic [ConvEngineCountSize-1:0] conv_weight_count;

  counter #(
            .Bits(ConvEngineCountSize)
          ) conv_engine_weight_count_inst (
            .clk_i,
            .en_i(1'b1),
            .rst_i(rst_conv_weight),
            .start_val_i({ConvEngineCountSize{1'b0}}),
            .end_val_i(ConvEngineCount),
            .count_by_i({{{ConvEngineCountSize-1}{1'b0}}, {1'b1}}),
            .count_o(conv_weight_count)
          );

  genvar i;
  generate
    for (i = 0; i < ConvEngineCount; i++)
    begin : conv_weight_shift_regs
      shift_reg_with_store #(
                             .N(DataWidth),
                             .Length(KernelSize*KernelSize)
                           ) conv_weight_shift_reg (
                             .clk_i(clk_i),
                             .en_i(!conv_weight_no_data && conv_weight_count == i),
                             .rst_i(1'b0),
                             .rst_val_i({DataWidth{1'b0}}),  // Reset to 0, adjust if needed
                             .data_i(conv_weight_data),
                             .data_o(),
                             .store_o(conv_kernel_weights_unsigned[i])
                           );
    end
  endgenerate



  //------------------------------------------------------------------------------------
  // Convolution Module
  //------------------------------------------------------------------------------------
  assign conv_mem_count = conv_config_1.engine_count * conv_config_2.matrix_size * conv_config_2.matrix_size * Ratio * conv_count; // TODO: seems like a 16 dsp to preform this, fix later

  // Load data
  logic conv_no_data;
  logic signed [DataWidth-1:0] conv_activation_data;

  fifo #(
         .InputWidth(16), // Memory Interface is 64 bits
         .OutputWidth(DataWidth),
         .Depth(4) // Can store 4 words
       ) conv_fifo (
         .clk_i,
         .rst_i(rst_conv),
         .write_en_i(run_conv && mem_data_read_valid),
         .read_en_i(1'b1),
         .data_i(mem_data_read),
         .data_o(conv_activation_data),
         .full_o(),
         .empty_o(conv_no_data)
       );

  convolution_layer #(
                      .MaxMatrixSize(MaxMatrixSize),
                      .KernelSize(KernelSize),
                      .EngineCount(ConvEngineCount),
                      .N(DataWidth)
                    ) conv_layer_inst (
                      .clk_i, // clock
                      .rst_i(rst_conv), // reset active low
                      .run_i(!conv_no_data), // run the convolution

                      // Configuration Registers
                      .config_1_i(conv_config_1),
                      .config_2_i(conv_config_2),
                      .config_3_i(conv_config_3),
                      .config_4_i(conv_config_4),

                      // Data Inputs
                      .kernel_weights_i(conv_kernel_weights), // kernel weights
                      .activation_data_i(conv_activation_data), // activation data

                      // Output Registers
                      .status_o(conv_status), // convolution results [1[Done], 1[Running], 14[Convolution Count]]

                      // Data Outputs
                      .data_o(conv_data), // convolution data output
                      .conv_valid_o(conv_valid) // convolution valid
                    );

  ///--------------------------------------------------------------------------------------------
  // Dense Layer
  //--------------------------------------------------------------------------------------------

  dense_layer #(
                .N(16),
                .EngineCount(1024)
              ) (
                .clk_i,
                .rst_i(),
                .en_i(),
                .value_i(),
                .weight_i(),
                .dense_o(),

                .config_1_i()  //accum = 1 for 1x1 conv, and 0 for dense
              );


  //------------------------------------------------------------------------------------
  // Instruction Decoder Module
  //------------------------------------------------------------------------------------

  aether_engine_decoder decode_inst (
                          .clk_i,

                          // Control Signals
                          .cmd_i(current_cmd), // command input
                          .data_o, // data output

                          // Register Variables
                          .version,
                          .ram_addr_low,
                          .ram_addr_high,
                          .conv_config_1,
                          .conv_config_2,
                          .conv_config_3,
                          .conv_config_4,
                          .conv_status,
                          .write_to_mem,
                          .read_from_mem,


                          // Reset Variables
                          .rst_cwgt_o(rst_conv_weight),
                          .rst_conv_o(rst_conv),
                          .rst_dwgt_o(rst_dense_weight),
                          .rst_dens_o(rst_dense),

                          // Load Weights Variables
                          .ldw_cwgt_o(load_conv_weights),
                          .ldw_dwgt_o(load_dense_weights),

                          // Convolution Variables
                          .cnv_run_o(run_conv),
                          .cnv_count_o(conv_count),

                          // Dense Variables
                          .dns_run_o(run_dense),
                          .dns_count_o(dense_count),

                          // Memory Variables
                          .mem_addr_start_o(mem_addr_start),
                          .mem_load_enable_o(mem_load_enable)
                        );


  //------------------------------------------------------------------------------------
  // Memory Interface
  //------------------------------------------------------------------------------------
  localparam IDLE = 2'b00;
  localparam WRITE = 2'b01;
  localparam READ = 2'b10;

  logic [1:0] command;
  logic [15:0] data_write;
  logic [31:0] count_total;

  assign command = mem_load_enable? READ : IDLE;
  assign data_write = 16'b0; // TODO: Implement this

  always_comb
  begin
    count_total = 32'b0;

    if (load_conv_weights)
      count_total = conv_weight_mem_count;
    else if (load_dense_weights)
      count_total = dense_weight_mem_count;
    else if (run_conv)
      count_total = conv_mem_count;
    else if (run_dense)
      count_total = dense_mem_count; // TODO: this depends on 1x1 or dense mode
  end

  aether_engine_generic_mem #(
                              .ClkRate(ClkRate)
                            ) sys_ram_inst (
                              .clk_i,
                              .command_i(command),
                              .start_address_i(mem_addr_start),
                              .count_total_i(count_total),
                              .data_write_i(data_write),
                              .data_read_o(mem_data_read),
                              .data_read_valid_o(mem_data_read_valid),
                              .data_write_done_o(mem_data_write_done),
                              .task_finished_o(mem_task_finished),

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



