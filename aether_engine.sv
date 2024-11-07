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
    inout wire [15:0] sdram_dq_io,

    //Debugging
    input logic assert_on_i
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
  logic rst_regs;
  logic rst_full;

  // Load Weights Signals
  logic load_conv_weights;
  logic load_dense_weights;
  logic ldw_strt;
  logic ldw_cont;
  logic lip_strt;
  logic lip_cont;
  logic ldw_move;

  logic load_mem_from_buffer;

  // Convolution Signals
  logic run_conv;
  logic [19:0] cnv_save_addr;

  logic signed [DataWidth-1:0] conv_data [ConvEngineCount-1:0];
  logic conv_valid;
  logic conv_done;

  // Dense Signals
  logic run_dense;
  logic [19:0] dns_save_addr;

  // Memory Signals
  logic [1:0] mem_command;
  logic [15:0] mem_data_read;

  logic mem_data_read_valid;
  logic data_write_ready;
  logic mem_task_finished;

  //------------------------------------------------------------------------------------
  // Register Interfaces
  //------------------------------------------------------------------------------------

  IVersn #(.ResetValue(16'h6C00)) reg_versn();
  IHwrid #(.ResetValue(16'hB2E9)) reg_hwrid();
  IMemup #(.ResetValue(16'h0000)) reg_memup();
  IMstrt #(.ResetValue(16'h0000)) reg_mstrt();
  IMendd #(.ResetValue(16'h0000)) reg_mendd();
  IBcfg1 #(.ResetValue({4'b0, ConvEngineCount})) reg_bcfg1();
  IBcfg2 #(.ResetValue({2'b0, MaxMatrixSize})) reg_bcfg2();
  IBcfg3 #(.ResetValue(16'h0000)) reg_bcfg3();
  ICprm1 #(.ResetValue(16'h0040)) reg_cprm1();
  IStats #(.ResetValue(16'h2240)) reg_stats();

  assign reg_memup.clk_i = clk_i;
  assign reg_memup.rst_i = rst_regs;

  assign reg_mstrt.clk_i = clk_i;
  assign reg_mstrt.rst_i = rst_regs;

  assign reg_mendd.clk_i = clk_i;
  assign reg_mendd.rst_i = rst_regs;

  assign reg_bcfg1.clk_i = clk_i;
  assign reg_bcfg1.rst_i = rst_regs;

  assign reg_bcfg2.clk_i = clk_i;
  assign reg_bcfg2.rst_i = rst_regs;

  assign reg_bcfg3.clk_i = clk_i;
  assign reg_bcfg3.rst_i = rst_regs;

  assign reg_cprm1.clk_i = clk_i;
  assign reg_cprm1.rst_i = rst_regs;

  assign reg_stats.clk_i = clk_i;
  assign reg_stats.rst_i = rst_regs;


  //------------------------------------------------------------------------------------
  // Input Data Buffer
  //------------------------------------------------------------------------------------

  localparam InputBuffer = MaxMatrixSize**2;
  localparam BuffAddrSize = $clog2(InputBuffer + 1);

  logic [BuffAddrSize-1:0] input_buffer_addr;
  logic load_from_input_buffer;
  logic [BuffAddrSize-1:0] input_buffer_count;
  logic [15:0] input_buffer_data;

  assign load_from_input_buffer = 1'b0; // TODO: Implement this

  simple_counter #(
                   .Bits(BuffAddrSize)
                 ) simple_counter_inst (
                   .clk_i(clk_data_i),
                   .en_i(ldw_cont || lip_cont), // Continue load input buffer
                   .rst_i(ldw_strt || lip_strt || rst_full), // Start load input buffer. TODO: do I really want to reset on full?
                   .count_o(input_buffer_addr)
                 );

  logic [BuffAddrSize-1:0] mem_count_difference;
  assign mem_count_difference = reg_mendd.mem_end_o - reg_mstrt.mem_start_o;

  increment_then_stop #(
                        .Bits(BuffAddrSize)
                      ) data_buffer_counter_inst (
                        .clk_i,
                        .en_i(load_from_input_buffer || (load_mem_from_buffer && data_write_ready)),
                        .rst_i(rst_conv || ldw_strt),
                        .start_val_i({BuffAddrSize{1'b0}}),
                        .end_val_i((load_mem_from_buffer)? mem_count_difference : InputBuffer[BuffAddrSize-1:0]),
                        .count_o(input_buffer_count),
                        .assert_on_i
                      );

  dual_port_bram #(
                   .DataWidth(16),
                   .Depth(InputBuffer)
                 ) input_buffer_bram (
                   .clk_i,
                   // Port A
                   .a_write_en_i(ldw_cont || lip_cont),
                   .a_addr_i(input_buffer_addr),
                   .a_data_i(param_2_i),
                   .a_data_o(),
                   // Port B
                   .b_write_en_i(1'b0), //TODO: Implement this
                   .b_addr_i(input_buffer_count),
                   .b_data_i(),
                   .b_data_o(input_buffer_data),

                   .assert_on_i
                 );

  //------------------------------------------------------------------------------------
  // Weight loading from buffer to ram
  //------------------------------------------------------------------------------------

  d_ff #(
         .Width(1)
       ) load_buf_to_mem_wgts_inst (
         .clk_i,
         .rst_i(mem_task_finished || rst_full),
         .en_i(ldw_move),
         .data_i(1'b1),
         .data_o(load_mem_from_buffer)
       );

  //------------------------------------------------------------------------------------
  // Convolution Weight Module
  //------------------------------------------------------------------------------------
  localparam KernelSize = 3;
  localparam ConvWeightSizeMem = (KernelSize**2 * ConvEngineCount) / 2 + (KernelSize**2 * ConvEngineCount) % 2; // 2 weights per memory location, round up

  logic signed [DataWidth-1:0] conv_kernel_weights [ConvEngineCount-1:0][KernelSize*KernelSize-1:0];

  logic load_conv_weights_longterm;
  logic [15:0] weight_shift_store [ConvWeightSizeMem-1:0];
  logic [(ConvWeightSizeMem * 16)-1:0] raw_store;

  d_ff #(
         .Width(1)
       ) load_wgts_to_mem_inst (
         .clk_i,
         .rst_i(mem_task_finished),
         .en_i(load_conv_weights),
         .data_i(1'b1),
         .data_o(load_conv_weights_longterm)
       );

  shift_reg_with_store #(
                         .N(16), // Width of the data
                         .Length(ConvWeightSizeMem) // Number of registers
                       ) conv_weight_mem_shift_inst (
                         .clk_i, // clock
                         .en_i(mem_data_read_valid && load_conv_weights_longterm), // enable shift
                         .rst_i(rst_conv_weight), // is this needed
                         .rst_val_i(16'b0), //reset value (Every register will be initialized with this value)
                         .data_i(mem_data_read), //data in
                         .data_o(), //data out
                         .store_o(weight_shift_store) //the register that holds the data
                       );

  generate
    for (genvar i = 0; i < ConvWeightSizeMem; i++)
    begin : gen_raw_store
      assign raw_store[16*i +: 16] = weight_shift_store[i];
    end
  endgenerate


  generate
    for (genvar i = 0; i < ConvEngineCount; i++)
    begin : weight_conversion
      for (genvar j = 0; j < KernelSize*KernelSize; j++)
      begin : kernel_mapping
        assign conv_kernel_weights[i][j] = $signed(raw_store[(i * KernelSize * KernelSize + j) * DataWidth +: DataWidth]);
      end
    end
  endgenerate



  //------------------------------------------------------------------------------------
  // Convolution Module
  //------------------------------------------------------------------------------------
  // Load data
  logic conv_no_data;
  logic signed [DataWidth-1:
                0] conv_activation_data;

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
                      .en_i(!conv_no_data), // run the convolution

                      // Configuration Registers
                      .reg_bcfg1_i(reg_bcfg1.read),
                      .reg_bcfg2_i(reg_bcfg2.read),
                      .reg_bcfg3_i(reg_bcfg3.read),
                      .reg_cprm1_i(reg_cprm1.read),

                      // Data Inputs
                      .kernel_weights_i(conv_kernel_weights), // kernel weights
                      .activation_data_i(conv_activation_data), // activation data

                      // Data Outputs
                      .data_o(conv_data), // convolution data output
                      .conv_valid_o(conv_valid), // convolution valid
                      .conv_done_o(conv_done), // convolution done

                      .assert_on_i(assert_on_i)
                    );

  ///--------------------------------------------------------------------------------------------
  // Dense Layer
  //--------------------------------------------------------------------------------------------

  dense_layer #(
                .N(16),
                .EngineCount(1024)
              ) dense_inst (
                .clk_i,
                .en_i(),
                .value_i(),
                .weight_i(),
                .dense_o(),

                // Configuration Registers
                .reg_bcfg1_i(reg_bcfg1.read),
                .reg_bcfg2_i(reg_bcfg2.read),
                .reg_bcfg3_i(reg_bcfg3.read),
                .reg_cprm1_i(reg_cprm1.read)
              );


  //------------------------------------------------------------------------------------
  // Instruction Decoder Module
  //------------------------------------------------------------------------------------

  aether_engine_decoder decode_inst (
                          .clk_i,

                          // Control Signals
                          .instruction_i, // instruction input
                          .param_1_i, // parameter 1 input
                          .param_2_i, // parameter 2 input
                          .data_o, // data output

                          // Register Variables
                          .reg_versn_i(reg_versn.read_full),
                          .reg_hwrid_i(reg_hwrid.read_full),
                          .reg_memup_i(reg_memup.read_full),
                          .reg_mstrt_i(reg_mstrt.read_full),
                          .reg_mendd_i(reg_mendd.read_full),
                          .reg_bcfg1_i(reg_bcfg1.read_full),
                          .reg_bcfg2_i(reg_bcfg2.read_full),
                          .reg_bcfg3_i(reg_bcfg3.read_full),
                          .reg_cprm1_i(reg_cprm1.read_full),
                          .reg_stats_i(reg_stats.read_full),
                          .reg_memup_o(reg_memup.write_ext),
                          .reg_mstrt_o(reg_mstrt.write_ext),
                          .reg_mendd_o(reg_mendd.write_ext),
                          .reg_bcfg1_o(reg_bcfg1.write_ext),
                          .reg_bcfg2_o(reg_bcfg2.write_ext),
                          .reg_bcfg3_o(reg_bcfg3.write_ext),
                          .reg_cprm1_o(reg_cprm1.write_ext),
                          .reg_stats_o(reg_stats.write_ext),

                          // Reset Variables
                          .rst_cwgt_o(rst_conv_weight),
                          .rst_conv_o(rst_conv),
                          .rst_dwgt_o(rst_dense_weight),
                          .rst_dens_o(rst_dense),
                          .rst_regs_o(rst_regs),
                          .rst_full_o(rst_full),

                          // Load Weights Variables
                          .ldw_cwgt_o(load_conv_weights),
                          .ldw_dwgt_o(load_dense_weights),
                          .ldw_strt_o(ldw_strt),
                          .ldw_cont_o(ldw_cont),
                          .ldw_move_o(ldw_move),

                          // Convolution Variables
                          .cnv_run_o(run_conv),
                          .cnv_save_addr_o(cnv_save_addr),

                          // Dense Variables
                          .dns_run_o(run_dense),
                          .dns_save_addr_o(dns_save_addr),

                          // Load Input Data Variables
                          .lip_strt_o(lip_strt),
                          .lip_cont_o(lip_cont),

                          // Memory Variables
                          .mem_command_o(mem_command)
                        );


  //------------------------------------------------------------------------------------
  // Memory Interface
  //------------------------------------------------------------------------------------

  logic [15:
         0] data_write;
  assign data_write = input_buffer_data; // TODO: Implement this with a state machine so that only one task can write/read from memory and handle the case when its busy

  aether_engine_generic_mem_simp #(
                                   .ClkRate(ClkRate)
                                 ) sys_ram_inst (
                                   .clk_i,
                                   .rst_i(rst_full),
                                   .command_i(mem_command),
                                   .start_address_i({reg_memup.mem_upper_o, reg_mstrt.mem_start_o}),
                                   .end_address_i({reg_memup.mem_upper_o, reg_mendd.mem_end_o}),
                                   .data_write_i(data_write),
                                   .data_read_o(mem_data_read),
                                   .data_read_valid_o(mem_data_read_valid),
                                   .data_write_ready_o(data_write_ready),
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
                                   .sdram_dq_io,

                                   .assert_on_i
                                 );
endmodule



