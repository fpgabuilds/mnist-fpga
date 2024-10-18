// TODO: add padding to the input matrix
// TODO: add shifting to the sum
// TODO: add activation functions on results
// TODO: add testbench
module convolution_layer #(
    parameter MaxMatrixSize = 16383, // maximum matrix size that this convolver can convolve
    parameter KernelSize = 3, // kernel size
    parameter EngineCount = 1024, // Amount of instantiated convolvers
    parameter N = 16 // total bit width
  ) (
    input logic clk_i, // clock
    input logic rst_i, // reset active low
    input logic run_i, // run the convolution

    // Configuration Registers
    IConvConfig1.read config_1_i,
    IConvConfig2.read config_2_i,
    IConvConfig3.read config_3_i,
    IConvConfig4.read config_4_i,

    // Data Inputs
    input [N*KernelSize*KernelSize-1:0] kernel_weights_i [EngineCount-1:0], // kernel weights
    input [N-1:0] activation_data_i, // activation data

    // Output Registers
    IConvStatus.write status_o, // convolution results [1[Done], 1[Running], 14[Convolution Count]]

    // Data Outputs
    output [N-1:0] data_o [EngineCount-1:0], // convolution data output
    output conv_valid // convolution valid
  );

  always @ (posedge clk_i)
  begin
    assert(MaxMatrixSize <= 16383) else
            $error("MaxMatrixSize must be less than or equal to 16383"); // By specification
    assert(MaxMatrixSize < 0) else
            $error("MaxMatrixSize must be greater than 0");
    assert(EngineCount <= 1024) else
            $error("EngineCount must be less than or equal to 1024"); // By specification
    assert(EngineCount < 0) else
            $error("EngineCount must be greater than 0");

    assert(config_1_i.engine_count <= EngineCount) else
            $error("Requested EngineCount is greater than the instantiated EngineCount");
    assert(config_1_i.engine_count < 0) else
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


  counter #( // Counts how many valid convolution results have been generated, used for bram addressing
            .Bits(ConvOutputSize)
          ) conv_counter_inst (
            .clk_i(conv_valid), // 1st engine is always active
            .en_i(run_i),
            .rst_i,
            .start_val_i({ConvOutputSize{1'b0}}),
            .end_val_i({ConvOutputCount{1'b1}}),
            .count_by_i({{ConvOutputSize-1{1'b0}}, 1'b1}),
            .count_o(conv_counter)
          );

  generate
    genvar i;
    for(i = 0; i < EngineCount; i = i + 1)
    begin : conv_engines
      logic [2*N-1:0] conv_result;
      logic [2*N-1:0] prev_result;
      logic [2*N-1] sum, _sum;
      logic [N-1:0] sum_shifted;
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

      assign sum = (config_2_i.accumulate) ? conv_result + prev_result : conv_result; //TODO: add in shifting based on overflow and count for that
      assign sum_shifted[i] = sum[N-1:0]; //TODO: apply shifting to this

      dual_port_bram #(
                       .DataWidth(2*N),
                       .Depth(MaxMatrixSize*MaxMatrixSize)
                     ) weight_bram (
                       .clk_i(valid),
                       // Port A (load data)
                       .a_write_en_i(1'b1),
                       .a_addr_i(conv_counter),
                       .a_data_i(sum),
                       .a_data_o(_sum),
                       // Port B (Direct Convolution Access)
                       .b_write_en_i(1'b0),
                       .b_addr_i(conv_counter),
                       .b_data_i({N{1'b0}}),
                       .b_data_o(conv_result)
                     );

      // Outputs of generated convolvers
      if (i == 0)
        assign conv_valid = valid;

      assign conv_done[i] = (i < config_1_i.engine_count) ? done : 1'b1;
      assign data_o[i] = (i < config_1_i.engine_count) ? sum_shifted : {N{1'b0}};
    end
  endgenerate

  logic done;

  assign done = conv_done == {EngineCount{1'b1}};
  assign status_o.done = done;
  assign status_o.running = run_i && !done;
  assign status_o.count = conv_counter[13:0];
endmodule
