module aether_engine #(
    parameter DataWidth = 8,

    //  Convolution Configuration
    parameter MaxMatrixSize = 16383, // maximum matrix size that this convolver can convolve
    parameter KernelSize = 3, // kernel size
    parameter ConvEngineCount = 1024 // Amount of instantiated convolvers // TODO: add this to an info register and create errors
  ) (
    input logic clk_i, // clock

    // Control Signals
    input logic [23:0] cmd_i, // command input
    output logic [15:0] data_o, // data output

    output logic buffer_full_o, // buffer full, do not send any more commands
    output logic interrupt_o // interrupt signal
  );

  logic [63:0] ram_data;
  logic [3:0] ram_task;
  logic ram_data_valid;

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

  IInterrupt interrupt();

  IWriteToMem write_to_mem();
  IReadFromMem read_from_mem();

  assign interrupt_o = |interrupt.read_active;


  //------------------------------------------------------------------------------------
  // Convolution Weight Module
  //------------------------------------------------------------------------------------
  logic conv_weight_rst;
  logic [DataWidth-1:0] conv_kernel_weights [ConvEngineCount-1:0][KernelSize*KernelSize-1:0];


  // Load data
  logic conv_weight_write_en;
  logic conv_weight_no_data;
  logic [DataWidth-1:0] conv_weight_data;
  assign conv_weight_write_en = (ram_task == 4'b0000 && ram_data_valid)? 1'b1 : 1'b0; //LOAD_CONV_WEIGHTS TODO: import this from the decoder

  fifo #(
         .InputWidth(64), // Memory Interface is 64 bits
         .OutputWidth(DataWidth),
         .Depth(4) // Can store 4 words
       ) conv_weight_fifo (
         .clk_i,
         .rst_i(conv_weight_rst),
         .write_en_i(conv_weight_write_en),
         .read_en_i(1'b1),
         .data_i(ram_data),
         .data_o(conv_weight_data),
         .full_o(),
         .empty_o(conv_weight_no_data)
       );

  localparam ConvEngineCountSize = $clog2(ConvEngineCount) + 1;
  logic [ConvEngineCountSize-1:0] conv_weight_count;

  counter #(
            .Bits(ConvEngineCountSize)
          ) conv_engine_weight_count_inst (
            .clk_i,
            .en_i(1'b1),
            .rst_i(conv_weight_rst),
            .start_val_i({ConvEngineCountSize{1'b0}}),
            .end_val_i(ConvEngineCount),
            .count_by_i({{ConvEngineCountSize{1'b0}}, {1'b1}}),
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
                             .store_o(conv_kernel_weights[i])
                           );
    end
  endgenerate



  //------------------------------------------------------------------------------------
  // Convolution Module
  //------------------------------------------------------------------------------------
  logic conv_rst;

  // Load data
  logic activation_write_en;
  logic conv_no_data;
  logic [DataWidth-1:0] conv_activation_data;
  assign activation_write_en = (ram_task == 4'b0001 && ram_data_valid)? 1'b1 : 1'b0; //LOAD_CONV_DATA TODO: import this from the decoder

  // Convolution Outputs
  logic [DataWidth-1:0] conv_data [ConvEngineCount-1:0];
  logic conv_valid;

  fifo #(
         .InputWidth(64), // Memory Interface is 64 bits
         .OutputWidth(DataWidth),
         .Depth(4) // Can store 4 words
       ) conv_fifo (
         .clk_i,
         .rst_i(conv_rst),
         .write_en_i(activation_write_en),
         .read_en_i(1'b1),
         .data_i(ram_data),
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
                      .rst_i(conv_rst), // reset active low
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
                      .conv_valid(conv_valid) // convolution valid
                    );


  //------------------------------------------------------------------------------------
  // Instruction Decoder Module
  //------------------------------------------------------------------------------------




  aether_engine_decoder decode_inst (
                          .clk_i,

                          // Control Signals
                          .cmd_i, // command input
                          .data_o, // data output

                          .buffer_full_o, // buffer full, do not send any more commands

                          // Register Variables
                          .version,
                          .ram_addr_low,
                          .ram_addr_high,
                          .conv_config_1,
                          .conv_config_2,
                          .conv_config_3,
                          .conv_config_4,
                          .conv_status,
                          .interrupt,
                          .write_to_mem,
                          .read_from_mem,

                          // Convolution Weight Variables
                          .conv_weight_rst_o(conv_weight_rst),

                          // Convolution Variables
                          .conv_rst_o(conv_rst),

                          // Ram Output
                          .ram_data_o(ram_data),
                          .ram_task_o(ram_task),
                          .ram_data_valid_o(ram_data_valid)
                        );
endmodule



