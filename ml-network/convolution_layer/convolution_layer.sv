`include "../../aether_engine/aether_registers/aether_registers.sv"
/*
convolution_layer #(
      .MaxMatrixSize(16383),
      .KernelSize(),
      .EngineCount(1023),
      .Bits()
    ) _inst (
      .clk_i,
      .rst_i,
      .start_i,
      .kernel_weights_i,
      .reg_bcfg1_i,
      .reg_bcfg2_i,
      .reg_bcfg3_i,
      .reg_cprm1_i,
      .has_data_i,
      .req_next_i,
      .activation_data_i,
      .used_data_o(),
      .conv_valid_o(),
      .data_o(),
      .conv_done_o(),
      .conv_running_o(),
      .assert_on_i
    );
*/

// TODO: add padding to the input matrix
// TODO: Allow for multiple kernels sizes
module convolution_layer #(
    /// maximum matrix size that this convolver can convolve
    parameter logic [13:0] MaxMatrixSize = 16383,
    parameter unsigned KernelSize,  /// kernel size
    parameter logic [9:0] EngineCount = 1023,  /// Amount of instantiated convolvers
    parameter unsigned Bits  /// total bit width
) (
    //------------------------------------------------------------------------------------
    // Non Time Critical Inputs (Initial or Asynchronous)
    //------------------------------------------------------------------------------------
    input logic clk_i,
    input logic rst_i,  // Asynchronous reset to clear counters and pipeline registers

    /// Start the convolution process, only has to be active for one clock cycle
    input logic start_i,

    /// Kernel Weights
    // These are cloned on start_i and do not depend on the input in further clock cycles
    input wire signed [Bits-1:0] kernel_weights_i[EngineCount-1:0][KernelSize*KernelSize-1:0],

    // Configuration Registers, These are cloned on start_i and do not depend on the input in further clock cycles
    input logic [15:0] reg_bcfg1_i,
    input logic [15:0] reg_bcfg2_i,
    input logic [15:0] reg_cprm1_i,

    //------------------------------------------------------------------------------------
    // Time Critical Inputs (1 clock cycle)
    //------------------------------------------------------------------------------------
    input logic has_data_i,  // has input data to process
    input logic req_next_i,  // request next data, no garanteed clock cycles to complete

    // Activation Data
    input logic signed [Bits-1:0] activation_data_i,

    //------------------------------------------------------------------------------------
    // Time Critical Outputs (1 clock cycle)
    //------------------------------------------------------------------------------------
    output logic used_data_o,  // used input data

    output logic conv_valid_o,  // when high, the data_o is valid
    output logic signed [Bits-1:0] data_o[EngineCount-1:0],  // convolution data output
    output logic conv_done_o,  // convolution done

    //------------------------------------------------------------------------------------
    // Non Time Critical Outputs
    //------------------------------------------------------------------------------------
    output logic conv_running_o,  // convolution running

    //------------------------------------------------------------------------------------
    // Debugging
    //------------------------------------------------------------------------------------
    input logic assert_on_i  // enable assertions
);

  //------------------------------------------------------------------------------------
  // Time 0, Initialize Convolution
  //------------------------------------------------------------------------------------

  // Inputs:
  //  - conv_done_c3: When high, the convolution is done, used to reset the running signal
  //  - start_i: When high, the convolution is started
  //  - kernel_weights_i: The kernel weights for the convolution
  //  - reg_bcfg1_i: Configuration register 1
  //  - reg_bcfg2_i: Configuration register 2
  //  - reg_bcfg3_i: Configuration register 3
  //  - reg_cprm1_i: Convolution parameters register 1

  // Outputs:
  //  - conv_running_o: When high, the convolution is running
  //  - kernel_weights_buffer: The kernel weights for the convolution, stored at the start of the convolution
  //  - reg_bcfg1: Configuration register 1, stored at the start of the convolution
  //  - reg_bcfg2: Configuration register 2, stored at the start of the convolution
  //  - reg_bcfg3: Configuration register 3, stored at the start of the convolution
  //  - reg_cprm1: Convolution parameters register 1, stored at the start of the convolution
  //  - shift_amount: The amount to shift the convolution result


  logic conv_done_c4;
  wire signed [Bits-1:0] kernel_weights_buffer[EngineCount-1:0][KernelSize*KernelSize-1:0];
  core_sr_ff conv_running_sr (
      .clk_i,
      .rst_i,
      .set_i (start_i),
      .srst_i(conv_done_c4),
      .data_o(conv_running_o),
      .assert_on_i
  );

  generate
    genvar i, j;
    for (i = 0; i < EngineCount; i++) begin : g_weight_engine
      for (j = 0; j < KernelSize * KernelSize; j++) begin : g_weight_kernel
        core_d_ff #(
            .Bits(Bits)
        ) kernel_conv_inst (
            .clk_i,
            .rst_i (1'b0),
            .en_i  (!conv_running_o),
            .data_i(kernel_weights_i[i][j]),
            .data_o(kernel_weights_buffer[i][j])
        );
      end
    end
  endgenerate

  logic [15:0] reg_bcfg1;
  logic [15:0] reg_bcfg2;
  logic [15:0] reg_cprm1;

  core_d_ff #(
      .Bits(16)
  ) reg_bcfg1_inst (
      .clk_i,
      .rst_i (1'b0),
      .en_i  (!conv_running_o),
      .data_i(reg_bcfg1_i),
      .data_o(reg_bcfg1)
  );

  core_d_ff #(
      .Bits(16)
  ) reg_bcfg2_inst (
      .clk_i,
      .rst_i (1'b0),
      .en_i  (!conv_running_o),
      .data_i(reg_bcfg2_i),
      .data_o(reg_bcfg2)
  );

  core_d_ff #(
      .Bits(16)
  ) reg_cprm1_inst (
      .clk_i,
      .rst_i (1'b0),
      .en_i  (!conv_running_o),
      .data_i(reg_cprm1_i),
      .data_o(reg_cprm1)
  );


  logic [5:0] shift_amount;
  assign shift_amount = {Bcfg2ShiftHigh(reg_bcfg2), Bcfg1ShiftLow(reg_bcfg1)};

  //------------------------------------------------------------------------------------
  // Debugging
  //------------------------------------------------------------------------------------
  logic enable_d;

  always @(posedge clk_i) begin
    if (assert_on_i && conv_running_o) begin
      assert (Bcfg1EngineCount(reg_bcfg1) <= EngineCount)
      else $error("Requested EngineCount is greater than the instantiated EngineCount");
      assert (Bcfg1EngineCount(reg_bcfg1) > 0)
      else $error("Requested EngineCount must be greater than 0");
      assert (Bcfg2MatrixSize(reg_bcfg2) + 2 * Crpm1Padding(reg_cprm1) <= MaxMatrixSize)
      else $error("Requested MatrixSize + padding is greater than the instantiated MaxMatrixSize");
      assert (shift_amount < 2 * Bits)
      else  // This is actually fine
        $warning("Shift amount is greater than the total bit width * 2");
      if (has_data_i)
        assert (activation_data_i == activation_data_i)
        else $error("activation_data_i is unknown %h", activation_data_i);
    end
  end

  //------------------------------------------------------------------------------------
  // Load SR Flip-Flops
  //------------------------------------------------------------------------------------
  logic request_next_data;
  core_sr_ff req_next_data_sr (
      .clk_i,
      .rst_i(!conv_running_o),
      .set_i(req_next_i && conv_running_o),  // If both set and srst are high, output will be set
      .srst_i(conv_valid_o),
      .data_o(request_next_data),
      .assert_on_i(1'b0)  // Expected for set and reset to be high at the same time
  );


  //------------------------------------------------------------------------------------
  // Clock  1,
  //------------------------------------------------------------------------------------

  // Inputs:
  //  - activation_data_c1: The activation data for the convolution
  //  - accum_data_in_c3: The data to write to the convolution output ram
  //  - accum_write_c2: When high, the data_o is valid, only valid for one clock cycle then turns off unless new data is valid
  //  - has_data_i: When high, there is data to process

  // Outputs:
  //  - data_conv_c2: The convolution data output
  //  - conv_valid_c2: When high, the data_o is valid
  //  - conv_done_c2: When high, the convolution is done
  //  - accum_data_out_c2: The previous convolution data to accumulate with the recently calculated convolution data

  localparam unsigned ConvOutputCount = (MaxMatrixSize - KernelSize + 1) ** 2;
  localparam unsigned ConvOutputSize = $clog2(ConvOutputCount + 1);
  localparam logic [ConvOutputSize-1:0] ConvOutputEndVal = ConvOutputCount - 1;

  logic signed [2*Bits-1:0] data_conv_c2[EngineCount-1:0];

  logic signed [2*Bits-1:0] accum_data_in_c3 [EngineCount-1:0]; //Not buffered, available for the next clock cycle
  logic signed [2*Bits-1:0] accum_data_out_c3[EngineCount-1:0];
  logic [ConvOutputSize-1:0] accum_addr_write;
  logic [ConvOutputSize-1:0] accum_addr_read;

  logic conv_valid_c2;
  logic conv_done_c2;
  logic conv_en_c2;
  logic accum_write_c2;

  logic conv_valid_c3;
  logic accum_write_c3;

  logic conv_valid_c4;

  generate
    for (i = 0; i < EngineCount; i = i + 1) begin : g_conv_engines
      logic signed [2*Bits-1:0] conv_result;
      logic valid;
      logic done;
      logic engine_active;
      logic conv_en_fill_pipe;
      logic conv_en;

      assign conv_en_fill_pipe = request_next_data || !conv_valid_c4 || !conv_valid_c3 || !conv_valid_c2;
      // - request_next_data: We are requesting the next data so the whole pipeline will shift
      // - !conv_valid_c4: The last stage of the pipeline is empty and ready to accept new data
      // - !conv_valid_c4: The output of the last convolution was not valid so we can overwrite it
      assign engine_active = (i < Bcfg1EngineCount(reg_bcfg1));
      // - engine_active: This engine is active
      assign conv_en = has_data_i && engine_active && conv_en_fill_pipe && conv_running_o;
      // - has_data_i: We need data to process

      // Convolver instantiation
      convolver #(
          .MaxMatrixSize(MaxMatrixSize),
          .KernelSize(KernelSize),
          .Bits(Bits)
      ) conv_inst (
          .clk_i,
          .rst_i(!conv_running_o),
          .en_i(conv_en),
          .data_i(activation_data_i),
          .stride_i(Crpm1Stride(reg_cprm1)),
          .matrix_size_i(Bcfg2MatrixSize(reg_bcfg2)),
          .weights_i(kernel_weights_buffer[i]),
          .conv_o(conv_result),
          .valid_conv_o(valid),
          .end_conv_o(done),
          .assert_on_i(assert_on_i && conv_running_o)
      );

      assign data_conv_c2[i] = (engine_active && valid) ? conv_result : {2 * Bits{1'b0}};

      if (i == 0) begin : g_assign_first_mod_outputs
        assign conv_valid_c2 = valid;
        assign conv_done_c2  = done;
        assign used_data_o   = conv_en;
      end

      logic signed [2*Bits-1:0] prev_result;

      core_bram_dual_port #(  //TODO: add gateing to save power when this is not used
          .ADataWidth(2 * Bits),
          .ABitDepth (ConvOutputCount)
      ) accumulate_prev_conv (
          // Port A (load data)
          .a_clk_i(clk_i),
          .a_write_en_i(accum_write_c3 && engine_active),  // Write on valid
          .a_addr_i(accum_addr_write),
          .a_data_i(accum_data_in_c3[i]),
          .a_data_o(),

          // Port B (Read Previous Data For Accumulation)
          .b_clk_i(clk_i),
          .b_write_en_i(1'b0),
          .b_addr_i(accum_addr_read),  //conv_counter != ConvOutputEndVal means run only once
          .b_data_i({{2 * Bits} {1'b0}}),
          .b_data_o(prev_result),

          .assert_on_i
      );

      assign accum_data_out_c3[i] = (engine_active) ? prev_result : {2 * Bits{1'b0}};
    end
  endgenerate

  core_delay #(
      .Delay(1)
  ) conv_en_delay_inst (
      .clk_i,
      .rst_i (!conv_running_o),
      .en_i  (1'b1),
      .data_i(used_data_o),
      .data_o(conv_en_c2),
      .assert_on_i
  );

  //------------------------------------------------------------------------------------
  // Clock 2, Buffer required for valid counter
  //------------------------------------------------------------------------------------

  assign accum_write_c2 = conv_valid_c2 && conv_en_c2;

  /// Counts how many valid convolution results have been generated, used for bram addressing
  simple_counter_end #(
      .Bits(ConvOutputSize)
  ) conv_counter_inst (
      .clk_i,
      .en_i(accum_write_c2),
      .rst_i(!conv_running_o),
      .end_val_i(ConvOutputEndVal),
      .count_o(accum_addr_read)
  );

  core_delay #(
      .Delay(1),
      .Bits (ConvOutputSize)
  ) accum_addr_c3_inst (
      .clk_i,
      .rst_i (!conv_running_o),
      .en_i  (request_next_data || !conv_valid_c4 || !conv_valid_c3),
      .data_i(accum_addr_read),
      .data_o(accum_addr_write),
      .assert_on_i
  );

  core_delay #(
      .Delay(1)
  ) accum_write_c2_inst (
      .clk_i,
      .rst_i (!conv_running_o),
      .en_i  (request_next_data || !conv_valid_c4 || !conv_valid_c3),
      .data_i(accum_write_c2),
      .data_o(accum_write_c3),
      .assert_on_i
  );

  logic signed [2*Bits-1:0] data_conv_c3[EngineCount-1:0];


  logic conv_done_c3;

  core_delay #(
      .Delay(1)
  ) conv_valid_c3_inst (
      .clk_i,
      .rst_i (!conv_running_o),
      .en_i  (request_next_data || !conv_valid_c3 || !conv_valid_c4),
      .data_i(conv_valid_c2),
      .data_o(conv_valid_c3),
      .assert_on_i
  );

  core_delay #(
      .Delay(1)
  ) conv_done_c3_inst (
      .clk_i,
      .rst_i (!conv_running_o),
      .en_i  (request_next_data || !conv_valid_c3 || !conv_valid_c4),
      .data_i(conv_done_c2),
      .data_o(conv_done_c3),
      .assert_on_i
  );

  generate
    for (i = 0; i < EngineCount; i = i + 1) begin : g_conv_data_c3
      core_d_ff #(
          .Bits(2 * Bits)
      ) conv_data_c3_inst (
          .clk_i,
          .rst_i (!conv_running_o),
          .en_i  (request_next_data || !conv_valid_c3 || !conv_valid_c4),
          .data_i(data_conv_c2[i]),
          .data_o(data_conv_c3[i])
      );
    end
  endgenerate


  //------------------------------------------------------------------------------------
  // Clock 3, Accumulate Convolution Results
  //------------------------------------------------------------------------------------

  // Inputs:
  //  - accum_data_out_c3: The previous convolution data to accumulate with the recently calculated convolution data
  //  - data_conv_c3: The convolution data output
  //  - conv_valid_c3: When high, the data_o is valid


  //  - conv_done_c3: When high, the convolution is done

  // Outputs:
  //  - accum_data_in_c3: The data to write to the convolution output ram
  //  - accum_write_c2: When high, the data_o is valid, only valid for one clock cycle then turns off unless new data is valid
  //  - accum_data_out_c4: The accumulated data

  logic signed [Bits-1:0] accum_data_out_c4[EngineCount-1:0];

  //TODO: Remove this from register
  //reg_bcfg3.shift_final_o;

  generate
    for (i = 0; i < EngineCount; i = i + 1) begin : g_conv_accum
      logic signed [  2*Bits:0] sum_accum;
      logic signed [2*Bits-1:0] sum;
      logic signed [  Bits-1:0] accum_out;

      assign sum_accum = (Crpm1Accumulate(
          reg_cprm1
      )) ? data_conv_c3[i] + accum_data_out_c3[i] : data_conv_c3[i];
      //assign sum = sum_accum >>> shift_amount;
      assign sum = (Crpm1SaveToRam(reg_cprm1)) ? 16'h5555 : sum_accum >>> shift_amount;
      assign accum_data_in_c3[i] = (i < Bcfg1EngineCount(reg_bcfg1)) ? sum : {2 * Bits{1'b0}};

      assign accum_out = accum_data_in_c3[i] >>> (2 * Bits - Bits);


      core_d_ff #(
          .Bits(Bits)
      ) accumed_data_inst (
          .clk_i,
          .rst_i (1'b0),
          .en_i  (request_next_data || !conv_valid_c4),
          .data_i(accum_out),
          .data_o(accum_data_out_c4[i])
      );
    end
  endgenerate

  // core_d_ff valid_pulse_inst (
  //        .clk_i,
  //        .rst_i(!conv_running_o),
  //        .en_i(1'b1),
  //        .data_i(conv_valid_c3 && conv_en_c2),
  //        .data_o(accum_write_c2)
  //      );


  core_d_ff conv_valid_c4_inst (
      .clk_i,
      .rst_i(!conv_running_o),

      // Move data if data is output or if pipeline is not full
      .en_i(request_next_data || !conv_valid_c4),
      .data_i((Crpm1SaveToRam(reg_cprm1) || Crpm1SaveToBuffer(reg_cprm1)) ? (conv_valid_c3) : 1'b0),
      .data_o(conv_valid_c4)
  );

  core_delay #(
      .Delay(1)
  ) conv_done_c4_inst (
      .clk_i,
      .rst_i (!conv_running_o),
      .en_i  (request_next_data || !conv_valid_c4),
      .data_i(conv_done_c3),
      .data_o(conv_done_c4),
      .assert_on_i
  );


  //------------------------------------------------------------------------------------
  // Clock 4, Activation Functions
  //------------------------------------------------------------------------------------

  activation_layer #(
      .Bits(Bits),
      .EngineCount(EngineCount)
  ) layer_activation (
      .clk_i,
      .en_i(request_next_data && conv_valid_c4),
      .activation_function_i(Crpm1ActivationFunction(reg_cprm1)),

      .value_i(accum_data_out_c4),
      .value_o(data_o)
  );

  core_d_ff conv_valid_delay (
      .clk_i,
      .rst_i (!conv_running_o),
      .en_i  (request_next_data),
      .data_i(conv_valid_c4),
      .data_o(conv_valid_o)
  );

  core_delay #(
      .Delay(1)
  ) conv_done_delay_c3_inst (
      .clk_i,
      .rst_i (rst_i),
      .en_i  (request_next_data),
      .data_i(conv_done_c4),
      .data_o(conv_done_o),
      .assert_on_i
  );
endmodule
