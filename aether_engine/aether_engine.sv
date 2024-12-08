module aether_engine #(
    parameter unsigned DataWidth,

    // Convolution Configuration
    /// 16383 maximum matrix size that this convolver can convolve
    parameter unsigned [13:0] MaxMatrixSize,

    /// 1023 Amount of instantiated convolvers
    // TODO: add this to an info register and create errors
    parameter unsigned [9:0] ConvEngineCount,

    // Dense Configuration
    /// Amount of instantiated dense layers
    // TODO: add this to an info register and create errors
    parameter unsigned DenseEngineCount,

    // Memory Configuration
    parameter unsigned ClkRate = 143_000_000
) (
    input logic clk_i,  // clock

    /// clock for input data
    ///    *(This is a stretch goal)*
    // TODO: implement this so that the main board can run at different speeds then the controller.
    input logic clk_data_i,
    // assign clk_data_i = clk_i; they should be set to the same for now

    // Control Signals
    input logic [3:0] instruction_i,  // instruction input
    input logic [3:0] param_1_i,  // parameter 1 input
    input logic [15:0] param_2_i,  // parameter 2 input

    output logic [15:0] data_o,  // data output
    output logic interrupt_o,  // buffer full, do not input any more commands


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
    input logic assert_on_i,
    output logic signed [15:0] dense_out_o  // Needed for quartis build to estimate utilization
);

  `include "./constants/aether_constants.sv"
  import aether_registers::*;

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
  logic conv_running;

  logic signed [DataWidth-1:0] conv_data[ConvEngineCount-1:0];
  logic [15:0] conv_data_mem;
  logic conv_valid;
  logic conv_done;
  logic conv_save_mem;
  logic conv_save_done;
  logic conv_save_mem_running;
  logic conv_data_used_half;

  // Dense Signals
  logic run_dense;
  logic [19:0] dns_save_addr;
  logic signed [DataWidth-1:0] dense_out[DenseEngineCount-1:0];

  // Memory Signals
  logic [1:0] mem_command;
  logic [15:0] mem_data_read;

  logic mem_data_read_valid;
  logic data_write_ready;
  logic mem_task_finished;
  logic mem_task_running;


  // Register Variables
  logic [15:0] reg_versn;
  logic [15:0] reg_hwrid;
  logic [15:0] reg_memup;
  logic [15:0] reg_mstrt;
  logic [15:0] reg_mendd;
  logic [15:0] reg_bcfg1;
  logic [15:0] reg_bcfg2;
  logic [15:0] reg_bcfg3;
  logic [15:0] reg_cprm1;
  logic [15:0] reg_stats;


  //------------------------------------------------------------------------------------
  // Debug stuff
  //------------------------------------------------------------------------------------

  // For dense_out
  logic signed [15:0] dense_out_temp;
  always_comb begin
    dense_out_temp = dense_out[0];
    for (int i = 1; i < DenseEngineCount; i++) begin
      dense_out_temp = dense_out_temp ^ dense_out[i];
    end
    dense_out_o = dense_out_temp;
  end


  //------------------------------------------------------------------------------------
  // Input Data Buffer
  //------------------------------------------------------------------------------------
  localparam real Ratio = DataWidth / 16;
  localparam unsigned InputBuffer = ((MaxMatrixSize ** 2) * DataWidth / 16);

  initial begin
    assert (16 % DataWidth == 0)
    else $error("DataWidth must be a multiple of 2 up to 16");
  end

  localparam unsigned BuffAddrSize = $clog2(InputBuffer + 1);
  localparam logic [BuffAddrSize-1:0] LastBufferAddr = InputBuffer - 1;

  logic [BuffAddrSize-1:0] input_buffer_addr;
  logic [BuffAddrSize-1:0] input_buffer_count;
  logic [15:0] input_buffer_data;


  simple_counter_end #(
      .Bits(BuffAddrSize)
  ) buffer_input_counter (
      .clk_i(clk_data_i),
      .en_i(ldw_cont || lip_cont),  // Continue load input buffer
      .rst_i(ldw_strt || lip_strt || rst_full),  // Start load input buffer.
      .end_val_i(LastBufferAddr),  // The value the counter will stop at
      .count_o(input_buffer_addr)
  );

  logic [BuffAddrSize-1:0] mem_count_difference;
  assign mem_count_difference = reg_mendd - reg_mstrt;

  /// This counter is used to keep track of the number of elements in the buffer
  /// It incremets in 2 Conditions:
  /// 1. When the convolution is running with the load from buffer set and the data is used
  /// 2. When the memory is being loaded from the buffer and the data is ready to be written
  increment_then_stop #(
      .Bits(BuffAddrSize)
  ) data_buffer_counter_inst (
      .clk_i,
      .en_i((Bcfg3LoadFrom(
          reg_bcfg3
      ) == 2'b0 && conv_data_used_half && conv_running) ||
          (load_mem_from_buffer && data_write_ready)),
      .rst_i(rst_conv || ldw_strt),
      .start_val_i({BuffAddrSize{1'b0}}),
      .end_val_i((load_mem_from_buffer) ? mem_count_difference : LastBufferAddr),
      .count_o(input_buffer_count),
      .assert_on_i
  );

  core_bram_dual_port #(
      .ADataWidth(16),
      .ABitDepth (InputBuffer)
  ) input_buffer_bram (
      // Port A
      .a_clk_i(clk_i),
      .a_write_en_i(ldw_cont || lip_cont),
      .a_addr_i(input_buffer_addr),
      .a_data_i(param_2_i),
      .a_data_o(),
      // Port B
      .b_clk_i(clk_i),
      .b_write_en_i(1'b0),  //TODO: Implement this
      .b_addr_i(input_buffer_count),
      .b_data_i(),
      .b_data_o(input_buffer_data),

      .assert_on_i
  );

  //------------------------------------------------------------------------------------
  // Weight loading from buffer to ram
  //------------------------------------------------------------------------------------

  core_sr_ff load_buf_to_mem_wgts_inst (
      .clk_i,
      .rst_i (rst_full),
      .set_i (ldw_move),
      .srst_i(mem_task_finished),
      .data_o(load_mem_from_buffer),
      .assert_on_i
  );

  //------------------------------------------------------------------------------------
  // Convolution Weight Module
  //------------------------------------------------------------------------------------
  localparam unsigned KernelSize = 3;
  localparam unsigned ConvWeightSizeMem = (KernelSize**2 * ConvEngineCount) / 2 + (KernelSize**2 * ConvEngineCount) % 2; // 2 weights per memory location, round up

  logic signed [DataWidth-1:0] conv_kernel_weights[ConvEngineCount-1:0][KernelSize*KernelSize-1:0];

  logic load_conv_weights_longterm;
  logic [15:0] weight_shift_store[ConvWeightSizeMem-1:0];
  logic [(ConvWeightSizeMem * 16)-1:0] raw_store;

  core_sr_ff load_wgts_to_mem_inst (
      .clk_i,
      .rst_i (1'b0),
      .set_i (load_conv_weights),
      .srst_i(mem_task_finished),
      .data_o(load_conv_weights_longterm),
      .assert_on_i
  );

  core_shift_reg_store #(
      .Bits(16),  // Width of the data
      .Length(ConvWeightSizeMem)  // Number of registers
  ) conv_weight_mem_shift_inst (
      .clk_i,  // clock
      .en_i(mem_data_read_valid && load_conv_weights_longterm),  // enable shift
      .rst_i(rst_conv_weight),  // is this needed
      .rst_val_i(16'b0),  //reset value (Every register will be initialized with this value)
      .data_i(mem_data_read),  //data in
      .data_o(),  //data out
      .store_o(weight_shift_store)  //the register that holds the data
  );

  genvar i;
  genvar j;
  generate
    for (i = 0; i < ConvWeightSizeMem; i++) begin : gen_raw_store
      assign raw_store[16*i+:16] = weight_shift_store[i];
    end
  endgenerate


  generate
    for (i = 0; i < ConvEngineCount; i++) begin : g_weight_conversion
      for (j = 0; j < KernelSize * KernelSize; j++) begin : g_kernel_mapping
        assign conv_kernel_weights[i][j] = $signed(
            raw_store[(i*KernelSize*KernelSize+j)*DataWidth+:DataWidth]
        );
      end
    end
  endgenerate



  //------------------------------------------------------------------------------------
  // Convolution Module
  //------------------------------------------------------------------------------------

  //TODO: This is hardcoded bitwidth, make it dynamic
  localparam unsigned ConvEngineCountCeil = (ConvEngineCount / 2) + (ConvEngineCount % 2);
  logic signed [DataWidth-1:0] conv_activation_data;

  logic signed [7:0] data_a;
  logic signed [7:0] data_b;
  logic data_number;
  logic conv_data_used;

  assign data_a = $signed(input_buffer_data[7:0]);
  assign data_b = $signed(input_buffer_data[15:8]);

  // assign reg_stats.conv_done_i = conv_done;
  // assign reg_stats.conv_running_i = conv_running;

  /// Activations are 8 bits in a 16 bit store, we need to only get new data at 1/2 clk rate
  /// TODO: This is a crappy T flip flop, but it works
  core_d_ff conv_used_data_half (
      .clk_i,
      .rst_i (rst_conv),
      .en_i  (conv_data_used),
      .data_i(~conv_data_used_half),
      .data_o(conv_data_used_half)
  );

  /// Activations are 8 bits in a 16 bit store, we need to only get new data at 1/2 clk rate
  always_comb begin : split_conv_data
    conv_activation_data = {DataWidth{1'b0}};
    if (conv_running) begin
      if (conv_data_used_half) conv_activation_data = data_a;
      else conv_activation_data = data_b;
    end
  end

  convolution_layer #(
      .MaxMatrixSize(MaxMatrixSize),
      .KernelSize(KernelSize),
      .EngineCount(ConvEngineCount),
      .Bits(DataWidth)
  ) conv_layer_inst (
      .clk_i,
      .rst_i(rst_conv),
      .start_i(run_conv),
      .kernel_weights_i(conv_kernel_weights),
      .reg_bcfg1_i(reg_bcfg1),
      .reg_bcfg2_i(reg_bcfg2),
      .reg_cprm1_i(reg_cprm1),
      .has_data_i(Bcfg3LoadFrom(
          reg_bcfg3
      ) == 2'b0 ? 1'b1 : 1'b0),  //TODO: When not loading from buffer send the signal

      // enable convolution
      // run the convolution
      // - We need to have data to run the convolution
      // - We need to not be saving the data to memory if the convolution is valid
      // TODO: does this need !conv_no_data as the has_data_I might have problems (fine for now)
      .req_next_i(!Crpm1SaveToRam(
          reg_cprm1
      ) || Crpm1SaveToRam(
          reg_cprm1
      ) && conv_save_done && conv_valid),

      .activation_data_i(conv_activation_data),
      .used_data_o(conv_data_used),
      .conv_valid_o(conv_valid),
      .data_o(conv_data),
      .conv_done_o(conv_done),
      .conv_running_o(conv_running),
      .assert_on_i
  );

  // logic signed [DataWidth-1:0] conv_data [ConvEngineCount-1:0];
  logic [15:0] conv_save_mem_store[ConvEngineCountCeil-1:0];
  logic [16*ConvEngineCountCeil-1:0] conv_store_raw;
  generate
    for (i = 0; i < ConvEngineCount; i++) begin : gen_raw_conv_out_store
      assign conv_store_raw[8*i+:8] = conv_data[i];
    end
  endgenerate

  generate
    for (i = 0; i < ConvEngineCountCeil; i++) begin : g_parallel_to_serial_conv
      assign conv_save_mem_store[i] = conv_store_raw[i*16+:16];
    end
  endgenerate

  core_sr_ff conv_save_mem_delay_inst (
      .clk_i,
      .rst_i (rst_full),
      .set_i (conv_valid && Crpm1SaveToRam(reg_cprm1)),
      .srst_i(conv_done),
      .data_o(conv_save_mem),
      .assert_on_i
  );

  logic [$clog2(ConvEngineCountCeil+1)-1:0] engine_count_16b;
  assign engine_count_16b = ((Bcfg1EngineCount(reg_bcfg1) / 2) + (Bcfg1EngineCount(reg_bcfg1) % 2));

  core_parallel_to_serial #(
      .Bits(16),  // Width of the data
      .Length(ConvEngineCountCeil)  // Number of registers
  ) save_conv_to_mem (
      .clk_i,  // clock
      .run_i(conv_valid && Crpm1SaveToRam(reg_cprm1)),
      .en_i(data_write_ready),  // enable shift
      .srst_i((conv_valid && Crpm1SaveToRam(reg_cprm1) && conv_save_done) || rst_full),
      .store_i(conv_save_mem_store),  //the reset register for every data
      .shift_count_i(engine_count_16b),  //the number of shift
      .data_o(conv_data_mem),  //data out
      .done_o(conv_save_done),
      .running_o(conv_save_mem_running),
      .assert_on_i
  );

  ///--------------------------------------------------------------------------------------------
  // Dense Layer
  //--------------------------------------------------------------------------------------------

  logic signed [DataWidth-1:0] data_array[DenseEngineCount-1:0];

  generate
    for (i = 0; i < DenseEngineCount; i++) begin : gen_data
      assign data_array[i] = mem_data_read + i;  // i is automatically cast to 16-bit signed
    end
  endgenerate


  logic signed [DataWidth-1:0] weight_array[DenseEngineCount-1:0];

  generate
    for (i = 0; i < DenseEngineCount; i++) begin : gen_data2
      assign weight_array[i] = input_buffer_data + i;  // i is automatically cast to 16-bit signed
    end
  endgenerate


  dense_layer #(
      .N(DataWidth),
      .EngineCount(DenseEngineCount)
  ) dense_inst (
      .clk_i,
      .en_i(1'b1),
      .value_i(data_array),
      .weight_i(weight_array),
      .dense_o(dense_out),

      // Configuration Registers
      .reg_bcfg1_i(reg_bcfg1),
      .reg_bcfg2_i(reg_bcfg2),
      .reg_cprm1_i(reg_cprm1)
  );

  // assign reg_stats.dense_done_i = 1'b0;
  // assign reg_stats.dense_running_i = 1'b0;

  //------------------------------------------------------------------------------------
  // Instruction Decoder Module
  //------------------------------------------------------------------------------------

  aether_instruct_decoder decode_inst (
      .clk_i,

      .instruction_i,
      .param_1_i,
      .param_2_i,
      .data_o,

      .reg_stats_i({
        1'b0,  // unused
        conv_running,
        1'b0,  //dense running
        mem_task_running,
        1'b0,  //error asserted
        conv_done,
        1'b0,  // dense done
        mem_task_finished
      }),  // TODO: Implement interrupts
      .we_reg_stats_i(1'b1),

      // Register Variables
      .reg_versn_o(reg_versn),
      .reg_hwrid_o(reg_hwrid),
      .reg_memup_o(reg_memup),
      .reg_mstrt_o(reg_mstrt),
      .reg_mendd_o(reg_mendd),
      .reg_bcfg1_o(reg_bcfg1),
      .reg_bcfg2_o(reg_bcfg2),
      .reg_bcfg3_o(reg_bcfg3),
      .reg_cprm1_o(reg_cprm1),
      .reg_stats_o(reg_stats),

      // Reset Variables
      .rst_cwgt_o(rst_conv_weight),
      .rst_conv_o(rst_conv),
      .rst_dwgt_o(rst_dense_weight),
      .rst_dens_o(rst_dense),
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

  logic [15:0] data_write;
  logic [31:0] mem_start_address;
  logic [31:0] mem_end_address;

  logic mem_en;

  always_comb begin
    data_write = 16'h0000;
    mem_en = 1'b0;
    if (conv_save_mem) begin
      data_write = conv_data_mem;
      mem_en = conv_save_mem_running;
    end else if (load_mem_from_buffer) begin
      data_write = input_buffer_data;
      mem_en = 1'b1;
    end
  end

  //conv_save_memconv_save_done

  assign mem_start_address = {reg_memup, reg_mstrt};
  assign mem_end_address   = {reg_memup, reg_mendd};

  // assign reg_stats.memory_done_i = mem_task_finished;
  // assign reg_stats.memory_running_i = mem_task_running;

  aether_generic_mem #(
      .ClkRate(ClkRate)
  ) sys_ram_inst (
      .clk_i,
      .en_i(mem_en),
      .rst_i(rst_full),
      .command_i(mem_command),
      .start_address_i(mem_start_address),
      .end_address_i(mem_end_address),
      .data_write_i(data_write),
      .data_read_o(mem_data_read),
      .data_read_valid_o(mem_data_read_valid),
      .data_write_ready_o(data_write_ready),
      .task_finished_o(mem_task_finished),
      .mem_running_o(mem_task_running),

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



