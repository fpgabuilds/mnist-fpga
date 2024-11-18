// convolution_layer #(
//                     .MaxMatrixSize(16383),
//                     .KernelSize(),
//                     .EngineCount(1023),
//                     .N()
//                   ) _inst (
//                     .clk_i,
//                     .rst_i,
//                     .start_i,
//                     .kernel_weights_i,
//                     .reg_bcfg1_i,
//                     .reg_bcfg2_i,
//                     .reg_bcfg3_i,
//                     .reg_cprm1_i,
//                     .has_data_i,
//                     .req_next_i,
//                     .activation_data_i,
//                     .used_data_o(),
//                     .conv_valid_o(),
//                     .data_o(),
//                     .conv_done_o(),
//                     .conv_running_o(),
//                     .assert_on_i
//                   );

// TODO: add padding to the input matrix
// TODO: Allow for multiple kernels sizes
module convolution_layer #(
    parameter [13:0] MaxMatrixSize = 16383, // maximum matrix size that this convolver can convolve
    parameter KernelSize, // kernel size
    parameter [9:0] EngineCount = 1023, // Amount of instantiated convolvers
    parameter N // total bit width
  ) (
    //------------------------------------------------------------------------------------
    // Non Time Critical Inputs (Initial or Asynchronous)
    //------------------------------------------------------------------------------------
    input logic clk_i,
    input logic rst_i, // Asynchronous reset to clear counters and pipeline registers
    input logic start_i, // Start the convolution process, only has to be active for one clock cycle

    // Kernel Weights
    input wire signed [N-1:0] kernel_weights_i [EngineCount-1:0][KernelSize*KernelSize-1:0], // These are cloned on start_i and do not depend on the input in further clock cycles

    // Configuration Registers, These are cloned on start_i and do not depend on the input in further clock cycles
    IBcfg1.read_full reg_bcfg1_i,
    IBcfg2.read_full reg_bcfg2_i,
    IBcfg3.read_full reg_bcfg3_i,
    ICprm1.read_full reg_cprm1_i,

    //------------------------------------------------------------------------------------
    // Time Critical Inputs (1 clock cycle)
    //------------------------------------------------------------------------------------
    input logic has_data_i, // has input data to process
    input logic req_next_i, // request next data, no garanteed clock cycles to complete

    // Activation Data
    input logic signed [N-1:0] activation_data_i,

    //------------------------------------------------------------------------------------
    // Time Critical Outputs (1 clock cycle)
    //------------------------------------------------------------------------------------
    output logic used_data_o, // used input data

    output logic conv_valid_o, // when high, the data_o is valid
    output logic signed [N-1:0] data_o [EngineCount-1:0], // convolution data output
    output logic conv_done_o, // convolution done

    //------------------------------------------------------------------------------------
    // Non Time Critical Outputs
    //------------------------------------------------------------------------------------
    output logic conv_running_o, // convolution running

    //------------------------------------------------------------------------------------
    // Debugging
    //------------------------------------------------------------------------------------
    input logic assert_on_i // enable assertions
  );

  //------------------------------------------------------------------------------------
  // Time 0, Initialize Convolution
  //------------------------------------------------------------------------------------

  // Inputs:
  //  - conv_done_c2: When high, the convolution is done, used to reset the running signal
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


  logic conv_done_c2;
  logic signed [N-1:0] kernel_weights_buffer [EngineCount-1:0][KernelSize*KernelSize-1:0];
  sr_ff conv_running_sr (
          .clk_i,
          .rst_i,
          .set_i(start_i),
          .srst_i(conv_done_c2),
          .data_o(conv_running_o),
          .assert_on_i
        );

  generate
    genvar i, j;
    for (i = 0; i < EngineCount; i++)
    begin : weight_engine_g
      for (j = 0; j < KernelSize*KernelSize; j++)
      begin : weight_kernel_g
        d_ff_mult #(
                    .Bits(N)
                  ) kernel_conv_inst (
                    .clk_i,
                    .rst_i,
                    .en_i(!conv_running_o),
                    .data_i(kernel_weights_i[i][j]),
                    .data_o(kernel_weights_buffer[i][j])
                  );
      end
    end
  endgenerate

  IBcfg1 #(.ResetValue(16'h0000)) reg_bcfg1();
  IBcfg2 #(.ResetValue(16'h0000)) reg_bcfg2();
  IBcfg3 #(.ResetValue(16'h0000)) reg_bcfg3();
  ICprm1 #(.ResetValue(16'h0000)) reg_cprm1();

  assign reg_bcfg1.clk_i = clk_i;
  assign reg_bcfg1.rst_i = 1'b0;
  assign reg_bcfg1.we_i = 1'b1;
  assign reg_bcfg2.clk_i = clk_i;
  assign reg_bcfg2.rst_i = 1'b0;
  assign reg_bcfg2.we_i = 1'b1;
  assign reg_bcfg3.clk_i = clk_i;
  assign reg_bcfg3.rst_i = 1'b0;
  assign reg_bcfg3.we_i = 1'b1;
  assign reg_cprm1.clk_i = clk_i;
  assign reg_cprm1.rst_i = 1'b0;
  assign reg_cprm1.we_i = 1'b1;

  d_ff_mult #(
              .Bits(16)
            ) reg_bcfg1_conv_inst (
              .clk_i,
              .rst_i,
              .en_i(!conv_running_o),
              .data_i(reg_bcfg1_i.register_o),
              .data_o(reg_bcfg1.register_i)
            );

  d_ff_mult #(
              .Bits(16)
            ) reg_bcfg2_conv_inst (
              .clk_i,
              .rst_i,
              .en_i(!conv_running_o),
              .data_i(reg_bcfg2_i.register_o),
              .data_o(reg_bcfg2.register_i)
            );

  d_ff_mult #(
              .Bits(16)
            ) reg_bcfg3_conv_inst (
              .clk_i,
              .rst_i,
              .en_i(!conv_running_o),
              .data_i(reg_bcfg3_i.register_o),
              .data_o(reg_bcfg3.register_i)
            );

  d_ff_mult #(
              .Bits(16)
            ) reg_cprm1_conv_inst (
              .clk_i,
              .rst_i,
              .en_i(!conv_running_o),
              .data_i(reg_cprm1_i.register_o),
              .data_o(reg_cprm1.register_i)
            );

  logic [5:0] shift_amount;
  assign shift_amount = {reg_bcfg2.shift_high_o, reg_bcfg1.shift_low_o};

  //------------------------------------------------------------------------------------
  // Debugging
  //------------------------------------------------------------------------------------
  logic enable_d;

  always @ (posedge clk_i)
  begin
    if (assert_on_i && conv_running_o)
    begin
      assert(reg_bcfg1.engine_count_o <= EngineCount) else
              $error("Requested EngineCount is greater than the instantiated EngineCount");
      assert(reg_bcfg1.engine_count_o > 0) else
              $error("Requested EngineCount must be greater than 0");
      assert(reg_bcfg2.matrix_size_o + 2 * reg_cprm1.padding_o <= MaxMatrixSize) else
              $error("Requested MatrixSize + padding is greater than the instantiated MaxMatrixSize");
      assert(shift_amount < 2 * N) else // This is actually fine
              $warning("Shift amount is greater than the total bit width * 2");
      if (has_data_i)
        assert(activation_data_i == activation_data_i) else
                $error("activation_data_i is unknown %h", activation_data_i);
    end
  end

  //------------------------------------------------------------------------------------
  // Load SR Flip-Flops
  //------------------------------------------------------------------------------------
  logic request_next_data;
  sr_ff req_next_data_sr (
          .clk_i,
          .rst_i,
          .set_i(req_next_i && conv_running_o), // If both set and srst are high, output will be set
          .srst_i(conv_valid_o),
          .data_o(request_next_data),
          .assert_on_i(1'b0) // Expected for set and reset to be high at the same time
        );


  //------------------------------------------------------------------------------------
  // Clock  1,
  //------------------------------------------------------------------------------------

  // Inputs:
  //  - activation_data_c1: The activation data for the convolution
  //  - accum_data_in_c2: The data to write to the convolution output ram
  //  - accum_write_c3: When high, the data_o is valid, only valid for one clock cycle then turns off unless new data is valid
  //  - has_data_i: When high, there is data to process

  // Outputs:
  //  - data_conv_c2: The convolution data output
  //  - conv_valid_c2: When high, the data_o is valid
  //  - conv_done_c2: When high, the convolution is done
  //  - accum_data_out_c2: The previous convolution data to accumulate with the recently calculated convolution data

  localparam ConvOutputCount = (MaxMatrixSize-KernelSize+1)**2;
  localparam ConvOutputSize = $clog2(ConvOutputCount + 1);
  localparam [ConvOutputSize-1:0] ConvOutputEndVal = ConvOutputCount - 1;

  logic signed [2*N-1:0] data_conv_c2 [EngineCount-1:0];

  logic signed [2*N-1:0] accum_data_in_c2 [EngineCount-1:0]; //Not buffered, available for the next clock cycle
  logic signed [2*N-1:0] accum_data_out_c2 [EngineCount-1:0];
  logic [ConvOutputSize-1:0] accum_addr_write;
  logic [ConvOutputSize-1:0] accum_addr_read;

  logic conv_valid_c2;

  logic accum_write_c3;
  logic conv_valid_c3;

  generate
    for(i = 0; i < EngineCount; i = i + 1)
    begin : conv_engines_g
      logic signed  [2*N-1:0] conv_result;
      logic valid;
      logic done;
      logic engine_active;
      logic conv_en_fill_pipe;
      logic conv_en;

      assign conv_en_fill_pipe = request_next_data || !conv_valid_c3 || !conv_valid_c2;
      // - request_next_data: We are requesting the next data so the whole pipeline will shift
      // - !conv_valid_c3: The last stage of the pipeline is empty and ready to accept new data
      // - !conv_valid_c3: The output of the last convolution was not valid so we can overwrite it
      assign engine_active = (i < reg_bcfg1.engine_count_o);
      // - engine_active: This engine is active
      assign conv_en = has_data_i && engine_active && conv_en_fill_pipe && conv_running_o;
      // - has_data_i: We need data to process

      // Convolver instantiation
      convolver #(
                  .MaxMatrixSize(MaxMatrixSize),
                  .KernelSize(KernelSize),
                  .N(N)
                ) conv_inst (
                  .clk_i,
                  .rst_i,
                  .en_i(conv_en),
                  .data_i(activation_data_i),
                  .stride_i(reg_cprm1.stride_o),
                  .matrix_size_i(reg_bcfg2.matrix_size_o),
                  .weights_i(kernel_weights_buffer[i]),
                  .conv_o(conv_result),
                  .valid_conv_o(valid),
                  .end_conv_o(done),
                  .assert_on_i
                );

      assign data_conv_c2[i] = (engine_active) ? conv_result : {2*N{1'b0}};

      if (i == 0)
      begin
        assign conv_valid_c2 = valid;
        assign conv_done_c2 = done;
        assign used_data_o = conv_en;
      end

      logic signed [2*N-1:0] prev_result;

      dual_port_bram #( //TODO: add gateing to save power when this is not used
                       .DataWidth(2*N),
                       .Depth(ConvOutputCount)
                     ) accumulate_prev_conv (
                       .clk_i,
                       // Port A (load data)
                       .a_write_en_i(accum_write_c3 && engine_active), // Write on valid
                       .a_addr_i(accum_addr_write),
                       .a_data_i(accum_data_in_c2[i]),
                       .a_data_o(),

                       // Port B (Read Previous Data For Accumulation)
                       .b_write_en_i(1'b0),
                       .b_addr_i(accum_addr_read), //conv_counter != ConvOutputEndVal means run only once
                       .b_data_i({{2*N}{1'b0}}),
                       .b_data_o(prev_result),

                       .assert_on_i
                     );

      assign accum_data_out_c2[i] = (engine_active) ? prev_result : {2*N{1'b0}};
    end
  endgenerate

  //------------------------------------------------------------------------------------
  // Clock 2, Accumulate Convolution Results
  //------------------------------------------------------------------------------------

  // Inputs:
  //  - accum_data_out_c2: The previous convolution data to accumulate with the recently calculated convolution data
  //  - data_conv_c2: The convolution data output
  //  - conv_valid_c2: When high, the data_o is valid


  //  - conv_done_c2: When high, the convolution is done

  // Outputs:
  //  - accum_data_in_c2: The data to write to the convolution output ram
  //  - accum_write_c3: When high, the data_o is valid, only valid for one clock cycle then turns off unless new data is valid
  //  - accum_data_out_c3: The accumulated data

  logic signed [N-1:0] accum_data_out_c3 [EngineCount-1:0];

  //TODO: Remove this from register
  //reg_bcfg3.shift_final_o;

  generate
    for(i = 0; i < EngineCount; i = i + 1)
    begin : conv_accum_g
      logic signed  [2*N:0] sum_accum;
      logic signed  [2*N-1:0] sum;
      logic signed [N-1:0] accum_out;

      assign sum_accum = (reg_cprm1.accumulate_o) ? data_conv_c2[i] + accum_data_out_c2[i] : data_conv_c2[i];
      //assign sum = sum_accum >>> shift_amount;
      assign sum = (reg_cprm1.save_to_ram_o)? 16'h5555 : sum_accum >>> shift_amount;
      assign accum_data_in_c2[i] = (i < reg_bcfg1.engine_count_o) ? sum : {2*N{1'b0}};

      assign accum_out = accum_data_in_c2[i] >>> (2*N - N);


      d_ff_mult #(
                  .Bits(N)
                ) accumed_data_inst (
                  .clk_i,
                  .rst_i,
                  .en_i(request_next_data || !conv_valid_c3),
                  .data_i(accum_out),
                  .data_o(accum_data_out_c3[i])
                );
    end
  endgenerate

  assign accum_addr_write = accum_addr_read + 1; // Delayed until after accumulation step

  d_ff valid_pulse_inst ( //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
         .clk_i,
         .rst_i,
         .en_i(1'b1),
         .data_i(conv_valid_c2 && !conv_en),
         .data_o(accum_write_c3)
       );


  d_ff conv_valid_c3_inst (
         .clk_i,
         .rst_i,
         .en_i(request_next_data || !conv_valid_c3), // Move data if data is output or if pipeline is not full
         .data_i(conv_valid_c2),
         .data_o(conv_valid_c3)
       );

  logic conv_done_c3;
  d_delay #(
            .Delay(1)
          ) conv_done_c3_inst (
            .clk_i,
            .rst_i,
            .en_i(request_next_data || !conv_valid_c3),
            .data_i(conv_done_c2),
            .data_o(conv_done_c3)
          );

  //------------------------------------------------------------------------------------
  // Clock 3, Activation Functions
  //------------------------------------------------------------------------------------

  simple_counter_end #( // Counts how many valid convolution results have been generated, used for bram addressing
                       .Bits(ConvOutputSize)
                     ) conv_counter_inst (
                       .clk_i,
                       .en_i(accum_write_c3),
                       .rst_i,
                       .end_val_i(ConvOutputEndVal),
                       .count_o(accum_addr_read)
                     );

  activation_layer #(
                     .N(N),
                     .EngineCount(EngineCount)
                   ) layer_activation (
                     .clk_i,
                     .en_i(request_next_data && conv_valid_c3),
                     .activation_function_i(reg_cprm1.activation_function_o),

                     .value_i(accum_data_out_c3),
                     .value_o(data_o)
                   );

  d_ff conv_valid_delay (
         .clk_i,
         .rst_i,
         .en_i(request_next_data),
         .data_i((reg_cprm1.save_to_ram_o || reg_cprm1.save_to_buffer_o) ? (conv_valid_c3) : 1'b0),
         .data_o(conv_valid_o)
       );

  d_delay #(
            .Delay(1)
          ) conv_done_delay_c3_inst (
            .clk_i,
            .rst_i,
            .en_i(request_next_data),
            .data_i(conv_done_c3),
            .data_o(conv_done_o)
          );
endmodule


// TODO: Add more test that cover other features
module tb_convolution_layer ();
  parameter Bits = 8;
  parameter EngineCount = 2;
  parameter KernelSize = 3;
  parameter MaxMatrixSize = 10;
  parameter MatrixSize = 5;

  logic clk;
  logic en;
  logic rst;

  IBcfg1 #(.ResetValue(16'h0001)) reg_bcfg1();
  IBcfg2 #(.ResetValue(16'h0000)) reg_bcfg2();
  IBcfg3 #(.ResetValue(16'h0000)) reg_bcfg3();
  ICprm1 #(.ResetValue(16'h0040)) reg_cprm1();


  logic signed  [Bits-1:0] kernel_weights [EngineCount-1:0][KernelSize*KernelSize-1:0];
  logic signed  [Bits-1:0] activation_data;

  logic signed  [Bits-1:0] data_out [EngineCount-1:0];
  logic conv_valid;
  logic conv_done;

  logic reg_reset;
  logic assert_on;

  logic start;

  convolution_layer #(
                      .MaxMatrixSize(MaxMatrixSize),
                      .KernelSize(KernelSize),
                      .EngineCount(EngineCount),
                      .N(Bits)
                    ) uut (
                      .clk_i(clk),
                      .rst_i(rst),
                      .start_i(start),
                      .kernel_weights_i(kernel_weights),
                      .reg_bcfg1_i(reg_bcfg1.read_full),
                      .reg_bcfg2_i(reg_bcfg2.read_full),
                      .reg_bcfg3_i(reg_bcfg3.read_full),
                      .reg_cprm1_i(reg_cprm1.read_full),
                      .has_data_i(1'b1),
                      .req_next_i(en),
                      .activation_data_i(activation_data),
                      .used_data_o(),
                      .conv_valid_o(conv_valid),
                      .data_o(data_out),
                      .conv_done_o(conv_done),
                      .conv_running_o(),
                      .assert_on_i(assert_on)
                    );

  // Clock generation
  always #5 clk = ~clk;

  assign kernel_weights[0][0] = 8'h01;  // top left
  assign kernel_weights[0][1] = 8'h02;  // top middle
  assign kernel_weights[0][2] = 8'h03;  // top right
  assign kernel_weights[0][3] = 8'h04;  // middle left
  assign kernel_weights[0][4] = 8'h05;  // center
  assign kernel_weights[0][5] = 8'h06;  // middle right
  assign kernel_weights[0][6] = 8'h07;  // bottom left
  assign kernel_weights[0][7] = 8'h08;  // bottom middle
  assign kernel_weights[0][8] = 8'h09;  // bottom right

  assign kernel_weights[1][0] = 8'h0A;   // 10
  assign kernel_weights[1][1] = 8'hF6;   // -10
  assign kernel_weights[1][2] = 8'h14;   // 20
  assign kernel_weights[1][3] = 8'hEC;   // -20
  assign kernel_weights[1][4] = 8'h1E;   // 30
  assign kernel_weights[1][5] = 8'hE2;   // -30
  assign kernel_weights[1][6] = 8'h28;   // 40
  assign kernel_weights[1][7] = 8'hD8;   // -40
  assign kernel_weights[1][8] = 8'h32;   // 50

  assign reg_bcfg1.clk_i = clk;
  assign reg_bcfg1.rst_i = reg_reset;

  assign reg_bcfg2.clk_i = clk;
  assign reg_bcfg2.rst_i = reg_reset;

  assign reg_bcfg3.clk_i = clk;
  assign reg_bcfg3.rst_i = reg_reset; // A reset is the only thing needed to configure this reg for this testbench

  assign reg_cprm1.clk_i = clk;
  assign reg_cprm1.rst_i = reg_reset;


  initial
  begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b0;
    reg_reset = 1'b1;
    activation_data = 8'b0;
    assert_on = 1'b0;
    start = 1'b0;

    @(posedge clk);
    reg_reset = 1'b0;

    @(posedge clk);
    reg_bcfg1.register_i = 16'h0002; // Shift = 0, EngineCount = 2
    reg_bcfg1.we_i = 1'b1;
    reg_bcfg2.register_i = 16'h0005; // MatrixSize = 5
    reg_bcfg2.we_i = 1'b1;
    reg_cprm1.register_i = 16'b0000_0000_0100_0000; // Stride = 1
    reg_cprm1.we_i = 1'b1;

    @(posedge clk);
    reg_bcfg1.we_i = 1'b0;
    reg_bcfg2.we_i = 1'b0;
    reg_cprm1.we_i = 1'b0;
    assert_on = 1'b1;

    @(posedge clk);
    rst = 1'b0;
    start = 1'b1;

    @(posedge clk);
    en = 1'b1;
    start = 1'b0;

    for (int i = 0; i < MatrixSize*MatrixSize; i = i + 1)
    begin
      activation_data = i;
      @(posedge clk);
    end

    @(posedge conv_done);
    @(posedge clk);
    reg_cprm1.register_i = 16'b0000_0000_0100_0101; // Stride = 1
    reg_cprm1.we_i = 1'b1;
    rst = 1'b1;
    @(posedge clk);
    reg_cprm1.we_i = 1'b0;
    rst = 1'b0;

    for (int i = 0; i < MatrixSize*MatrixSize; i = i + 1)
    begin
      activation_data = -i;
      @(posedge clk);
    end

    @(posedge conv_done);
    @(posedge clk);

    $stop;
  end

  always @(posedge clk)
  begin
    if (conv_valid)
    begin
      assert(data_out[0] == 8'h00) else
              $error("Convolution 0 failed: output = %d, expected %d", data_out[0], 8'h00);
      assert(data_out[1] == 8'h00) else
              $error("Convolution 1 failed: output = %d, expected %d", data_out[1], 8'h00);
    end
  end
endmodule
