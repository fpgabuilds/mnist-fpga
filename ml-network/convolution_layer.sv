// TODO: add padding to the input matrix
// TODO: add shifting to the sum
// TODO: add activation functions on results
module convolution_layer #(
    parameter MaxMatrixSize = 16383, // maximum matrix size that this convolver can convolve
    parameter KernelSize = 3, // kernel size
    parameter EngineCount = 1024, // Amount of instantiated convolvers
    parameter N = 16 // total bit width
  ) (
    input logic clk_i, // clock
    input logic rst_i,
    input logic run_i, // run the convolution

    // Configuration Registers
    IConvConfig1.read config_1_i,
    IConvConfig2.read config_2_i,
    IConvConfig3.read config_3_i,
    IConvConfig4.read config_4_i,

    // Data Inputs
    input signed [N-1:0] kernel_weights_i [EngineCount-1:0][KernelSize*KernelSize-1:0], // kernel weights
    input signed [N-1:0] activation_data_i, // activation data

    // Output Registers
    IConvStatus.write status_o, // convolution results [1[Done], 1[Running], 14[Convolution Count]]

    // Data Outputs
    output signed [N-1:0] data_o [EngineCount-1:0], // convolution data output
    output conv_valid_o // convolution valid
  );

  always @ (posedge clk_i)
  begin
    assert(MaxMatrixSize <= 16383) else
            $error("MaxMatrixSize must be less than or equal to 16383"); // By specification
    assert(MaxMatrixSize > 0) else
            $error("MaxMatrixSize must be greater than 0");
    assert(EngineCount <= 1024) else
            $error("EngineCount must be less than or equal to 1024"); // By specification
    assert(EngineCount > 0) else
            $error("EngineCount must be greater than 0");

    assert(config_1_i.engine_count <= EngineCount) else
            $error("Requested EngineCount is greater than the instantiated EngineCount");
    assert(config_1_i.engine_count > 0) else
            $error("Requested EngineCount must be greater than 0");
    assert(config_2_i.matrix_size + 2 * config_3_i.padding <= MaxMatrixSize) else
            $error("Requested MatrixSize + padding is greater than the instantiated MaxMatrixSize");
    assert(config_3_i.shift_amount < 2 * N) else
            $error("Shift amount is greater than the total bit width * 2");
  end


  localparam ConvOutputCount = (MaxMatrixSize-KernelSize+1)**2;
  localparam ConvOutputSize = $clog2(ConvOutputCount) + 1;

  logic [EngineCount-1:0] conv_done;
  logic [ConvOutputSize-1:0] conv_counter;
  logic conv_valid;


  counter #( // Counts how many valid convolution results have been generated, used for bram addressing
            .Bits(ConvOutputSize)
          ) conv_counter_inst (
            .clk_i, // 1st engine is always active
            .en_i(conv_valid && run_i),
            .rst_i,
            .start_val_i({ConvOutputSize{1'b0}}),
            .end_val_i({ConvOutputSize{1'b1}}),
            .count_by_i({{ConvOutputSize-1{1'b0}}, 1'b1}),
            .count_o(conv_counter)
          );

  generate
    genvar i;
    for(i = 0; i < EngineCount; i = i + 1)
    begin : conv_engines
      logic signed  [2*N-1:0] conv_result;
      logic signed  [2*N-1:0] prev_result;
      logic signed  [2*N:0] sum_accum;
      logic signed  [2*N-1:0] sum;
      logic signed  [N-1:0] sum_output;
      logic valid, done;

      // Convolver instantiation
      convolver #(
                  .MaxMatrixSize(MaxMatrixSize),
                  .KernelSize(KernelSize),
                  .N(N)
                ) conv_inst (
                  .clk_i,
                  .rst_i,
                  .en_i((i < config_1_i.engine_count) ? run_i : 1'b0),
                  .data_i(activation_data_i),
                  .stride_i(config_1_i.stride),
                  .matrix_size_i(config_2_i.matrix_size),
                  .weights_i(kernel_weights_i[i]),
                  .conv_o(conv_result),
                  .valid_conv_o(valid),
                  .end_conv_o(done)
                );

      assign sum_accum = (config_2_i.accumulate) ? conv_result + prev_result : conv_result;
      assign sum = sum_accum >>> config_3_i.shift_amount;

      dual_port_bram #(
                       .DataWidth(2*N),
                       .Depth(ConvOutputCount)
                     ) accumulate_prev_conv (
                       .clk_i,
                       // Port A (load data)
                       .a_write_en_i(valid), // Write on valid
                       .a_addr_i(conv_counter),
                       .a_data_i(sum),
                       .a_data_o(),
                       // Port B (Direct Convolution Access)
                       .b_write_en_i(1'b0),
                       .b_addr_i(valid? (conv_counter + 1'd1) : conv_counter),
                       .b_data_i({{2*N}{1'b0}}),
                       .b_data_o(prev_result)
                     );

      // Outputs of generated convolvers
      if (i == 0)
        assign conv_valid = valid;

      assign conv_done[i] = (i < config_1_i.engine_count) ? done : 1'b1;
      assign data_o[i] = (i < config_1_i.engine_count && config_2_i.save_to_ram && valid) ? sum[N-1:0] : {N{1'b0}};
    end
  endgenerate

  logic done;

  assign done = (conv_done == {EngineCount{1'b1}});
  assign status_o.done = done;
  assign status_o.running = run_i && !done;
  assign conv_valid_o = (config_2_i.save_to_ram) ? conv_valid : 1'b0;

  generate
    if (ConvOutputSize <= 14)
    begin : gen_count_pad
      assign status_o.count = {{(14-ConvOutputSize){1'b0}}, conv_counter};  // Zero pad upper bits
    end
    else
    begin : gen_count_truncate
      assign status_o.count = conv_counter[13:0];  // Take lower 14 bits
    end
  endgenerate
endmodule


// TODO: Add more test that cover other features
module tb_convolution_layer ();
  parameter Bits = 8;
  parameter EngineCount = 2;
  parameter KernelSize = 3;
  parameter MatrixSize = 5;

  logic clk;
  logic en;
  logic rst;

  IConvConfig1 conv_config_1();
  IConvConfig2 conv_config_2();
  IConvConfig3 conv_config_3();
  IConvConfig4 conv_config_4();
  IConvStatus conv_status();

  logic signed  [Bits-1:0] kernel_weights [EngineCount-1:0][KernelSize*KernelSize-1:0];
  logic signed  [Bits-1:0] activation_data;

  logic signed  [Bits-1:0] data_o [EngineCount-1:0];
  logic conv_valid;

  convolution_layer #(
                      .MaxMatrixSize(MatrixSize), // maximum matrix size that this convolver can convolve
                      .KernelSize(KernelSize), // kernel size
                      .EngineCount(EngineCount), // Amount of instantiated convolvers
                      .N(Bits) // total bit width
                    ) uut (
                      .clk_i(clk), // clock
                      .rst_i(rst), // reset active low
                      .run_i(en), // run the convolution

                      // Configuration Registers
                      .config_1_i(conv_config_1.read),
                      .config_2_i(conv_config_2.read),
                      .config_3_i(conv_config_3.read),
                      .config_4_i(conv_config_4.read),

                      // Data Inputs
                      .kernel_weights_i(kernel_weights), // kernel weights
                      .activation_data_i(activation_data), // activation data

                      // Output Registers
                      .status_o(conv_status.write), // convolution results [1[Done], 1[Running], 14[Convolution Count]]

                      // Data Outputs
                      .data_o, // convolution data output
                      .conv_valid_o(conv_valid) // convolution valid
                    );

  // Clock generation
  always #5 clk = ~clk;

  assign conv_config_1.full_register = 16'h0402; // Stride = 1, EngineCount = 2
  assign conv_config_4.full_register = 16'h0000; // ActivationFunction = 0

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



  initial
  begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b0;
    activation_data = 8'b0;
    conv_config_2.full_register = 16'h0005; // Accumulate = 0, SaveToRam = 0, MatrixSize = 5
    conv_config_3.full_register = 16'h0000; // Padding = 0, PaddingFill = 0, ShiftAmount = 0

    @(posedge clk);
    @(posedge clk);

    rst = 1'b0;
    en = 1'b1;

    for (int i = 0; i < MatrixSize*MatrixSize; i = i + 1)
    begin
      activation_data = i;
      @(posedge clk);
    end

    @(posedge conv_status.done);
    @(posedge clk);
    conv_config_2.full_register = 16'hC005; // Accumulate = 1, SaveToRam = 1, MatrixSize = 5
    conv_config_3.full_register = 16'h0009; // Padding = 0, PaddingFill = 0, ShiftAmount = 9
    rst = 1'b1;
    @(posedge clk);
    rst = 1'b0;

    for (int i = 0; i < MatrixSize*MatrixSize; i = i + 1)
    begin
      activation_data = -i;
      @(posedge clk);
    end

    @(posedge conv_status.done);
    @(posedge clk);

    $finish;
  end

  always @(posedge clk)
  begin
    if (conv_valid)
    begin
      assert(data_o[0] == 8'h00) else
              $error("Convolution 0 failed: output = %d, expected %d", data_o[0], 8'h00);
      assert(data_o[1] == 8'h00) else
              $error("Convolution 1 failed: output = %d, expected %d", data_o[1], 8'h00);
    end
  end
endmodule
