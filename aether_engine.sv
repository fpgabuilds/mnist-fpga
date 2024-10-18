module aether_engine #(
    parameter DataWidth = 16,

    //  Convolution Configuration
    parameter MaxMatrixSize = 16383, // maximum matrix size that this convolver can convolve
    parameter KernelSize = 3, // kernel size
    parameter ConvEngineCount = 1024 // Amount of instantiated convolvers

    //
  ) (
    input logic clk_i, // clock

    // Control Signals
    input logic [23:0] cmd_i, // command input
    output logic [15:0] data_o, // data output

    output logic buffer_full_o, // buffer full, do not send any more commands
    output logic interrupt_o // interrupt signal
  );
  // Register Variables
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


  // Convolution Variables
  logic conv_rst;
  logic conv_run;

  logic weight_rst;



  logic [DataWidth*KernelSize*KernelSize-1:0] conv_kernel_weights [ConvEngineCount-1:0];
  logic [DataWidth-1:0] conv_activation_data;

  logic [DataWidth-1:0] conv_data [ConvEngineCount-1:0];
  logic conv_valid;

  convolution_layer #(
                      .MaxMatrixSize(MaxMatrixSize),
                      .KernelSize(KernelSize),
                      .EngineCount(ConvEngineCount),
                      .N(DataWidth)
                    ) conv_layer_inst (
                      .clk_i, // clock
                      .rst_i(conv_rst), // reset active low
                      .run_i(conv_run), // run the convolution

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


  // Instruction Decoder Definitions
  localparam RESET = 4'b0000;
  localparam NOP = 4'b0001;
  localparam WRITE_REG = 4'b0010;
  localparam READ_REG = 4'b0011;
  localparam START_TASK = 4'b0100;

  localparam RST_ALL = 4'b0000;
  localparam RST_CONV = 4'b0001;
  localparam RST_WEIGHTS = 4'b0010;

  logic [23:0] cmd_buffer;

  // Instruction Decoder
  always_ff @ (posedge clk_i)
  begin
    cmd_buffer <= cmd_i;
  end

  always_comb // Reset Instruction
  begin
    //resets
    conv_rst = 1'b0;
    weight_rst = 1'b0;

    if (cmd_buffer[23:20] == RESET)
    begin
      case (cmd_buffer[19:16])
        RST_ALL:
        begin
          conv_rst = 1'b1;
          weight_rst = 1'b1;
        end
        RST_CONV:
          conv_rst = 1'b1;
        RST_WEIGHTS:
          weight_rst = 1'b1;
        default:
          conv_rst = 1'b0;
      endcase
    end
  end

  always_comb // Read Register
  begin
    data_o = 16'h0000;

    if (cmd_buffer[23:20] == READ_REG)
    begin
      case (cmd_buffer[19:16])
        1'h0 :
          version.read_full(data_o);
        1'h1 :
          ram_addr_low.read_full(data_o);
        1'h2 :
          ram_addr_high.read_full(data_o);
        1'h3 :
          conv_config_1.read_full(data_o);
        1'h4 :
          conv_config_2.read_full(data_o);
        1'h5 :
          conv_config_3.read_full(data_o);
        1'h6 :
          conv_config_4.read_full(data_o);
        1'h7 :
          conv_status.read_full(data_o);
        1'h8 :
        begin
          interrupt.read_full();
          interrupt.write_active( // This might reset it and need to be moved
            .mem_load_active(1'b0),
            .conv_active(1'b0),
            .dense_active(1'b0)
          );
        end
        // 1'h9 :
        //   data_o = 16'h0000;
        // 1'hA :
        //   data_o = 16'h0000;
        // 1'hB :
        //   data_o = 16'h0000;
        // 1'hC :
        //   data_o = 16'h0000;
        // 1'hD :
        //   data_o = 16'h0000;
        1'hE :
        begin
          data_o = 16'h0000;
          $error("Cannot read from write to memory register");
        end
        1'hF :
          read_from_mem.read_full(data_o); // TODO: This needs to shift the data too
        default:
        begin
          data_o = 16'h0000;
          $error("Invalid register read");
        end

      endcase
    end
  end

  always_comb // Write Register
  begin
    if (cmd_buffer[23:20] == WRITE_REG)
    begin
      case (cmd_buffer[19:16])
        1'h0 :
          $error("Cannot write to version register");
        1'h1 :
          ram_addr_low.write(cmd_buffer[15:0]);
        1'h2 :
          ram_addr_high.write(cmd_buffer[15:0]);
        1'h3 :
          conv_config_1.write(cmd_buffer[15:0]);
        1'h4 :
          conv_config_2.write(cmd_buffer[15:0]);
        1'h5 :
          conv_config_3.write(cmd_buffer[15:0]);
        1'h6 :
          conv_config_4.write(cmd_buffer[15:0]);
        1'h7 :
          $error("Cannot write to status register");
        1'h8 :
          interrupt.write(cmd_buffer[15:0]); //Some of these registers are read only
        // 1'h9 :
        // 1'hA :
        // 1'hB :
        // 1'hC :
        // 1'hD :
        1'hE :
          write_to_mem.write(cmd_buffer[15:0]);
        1'hF :
          $error("Cannot write to read from memory register");
        default:
          $error("Invalid register write");
      endcase
    end
  end




endmodule



