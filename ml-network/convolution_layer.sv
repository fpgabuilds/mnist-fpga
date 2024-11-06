// TODO: add padding to the input matrix
module convolution_layer #(
    parameter [13:0] MaxMatrixSize = 16383, // maximum matrix size that this convolver can convolve
    parameter KernelSize = 3, // kernel size
    parameter [9:0] EngineCount = 1023, // Amount of instantiated convolvers
    parameter N = 16 // total bit width
  ) (
    input logic clk_i, // clock
    input logic rst_i,
    input logic en_i, // run the convolution

    // Configuration Registers
    IBcfg1.read reg_bcfg1_i,
    IBcfg2.read reg_bcfg2_i,
    IBcfg3.read reg_bcfg3_i,
    ICprm1.read reg_cprm1_i,

    // Data Inputs
    input wire signed [N-1:0] kernel_weights_i [EngineCount-1:0][KernelSize*KernelSize-1:0], // kernel weights
    input logic signed [N-1:0] activation_data_i, // activation data

    // Data Outputs
    output logic signed [N-1:0] data_o [EngineCount-1:0], // convolution data output
    output logic conv_valid_o, // convolution valid
    output logic conv_done_o, // convolution done

    input logic assert_on_i // enable assertions
  );
  logic [5:0] shift_amount;
  assign shift_amount = {reg_bcfg2_i.shift_high_o, reg_bcfg1_i.shift_low_o};

  always @ (posedge clk_i)
  begin
    if (assert_on_i)
    begin
      assert(reg_bcfg1.engine_count_o <= EngineCount) else
              $error("Requested EngineCount is greater than the instantiated EngineCount");
      assert(reg_bcfg1.engine_count_o > 0) else
              $error("Requested EngineCount must be greater than 0");
      assert(reg_bcfg2_i.matrix_size_o + 2 * reg_cprm1_i.padding_o <= MaxMatrixSize) else
              $error("Requested MatrixSize + padding is greater than the instantiated MaxMatrixSize");
      assert(shift_amount < 2 * N) else // This is actually fine
              $warning("Shift amount is greater than the total bit width * 2");
    end
  end


  localparam ConvOutputCount = (MaxMatrixSize-KernelSize+1)**2;
  localparam ConvOutputSize = $clog2(ConvOutputCount + 1);

  logic [EngineCount-1:0] conv_done;
  logic [ConvOutputSize-1:0] conv_counter;
  logic conv_valid;
  logic signed [N-1:0] data_conv [EngineCount-1:0];


  counter #( // Counts how many valid convolution results have been generated, used for bram addressing
            .Bits(ConvOutputSize)
          ) conv_counter_inst (
            .clk_i, // 1st engine is always active
            .en_i(conv_valid && en_i),
            .rst_i,
            .start_val_i({ConvOutputSize{1'b0}}),
            .end_val_i({ConvOutputSize{1'b1}}),
            .count_by_i({{ConvOutputSize-1{1'b0}}, 1'b1}),
            .count_o(conv_counter),
            .assert_on_i
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
                  .en_i((i < reg_bcfg1.engine_count_o) ? en_i : 1'b0),
                  .data_i(activation_data_i),
                  .stride_i(reg_cprm1_i.stride_o),
                  .matrix_size_i(reg_bcfg2_i.matrix_size_o),
                  .weights_i(kernel_weights_i[i]),
                  .conv_o(conv_result),
                  .valid_conv_o(valid),
                  .end_conv_o(done),
                  .assert_on_i(assert_on_i)
                );

      assign sum_accum = (reg_cprm1_i.accumulate_o) ? conv_result + prev_result : conv_result;
      assign sum = sum_accum >>> shift_amount;
      assign sum_output = sum >>> reg_bcfg3_i.shift_final_o;

      dual_port_bram #( //TODO: add gateing to save power when this is not used
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

      assign conv_done[i] = (i < reg_bcfg1.engine_count_o) ? done : 1'b1;
      assign data_conv[i] = (i < reg_bcfg1.engine_count_o && (reg_cprm1_i.save_to_ram_o || reg_cprm1_i.save_to_buffer_o) && valid) ? sum_output : {N{1'b0}};
    end
  endgenerate

  activation_layer #(
                     .N(N),
                     .EngineCount(EngineCount)
                   ) layer_activation (
                     .clk_i,
                     .en_i,
                     .activation_function_i(reg_cprm1_i.activation_function_o),

                     .value_i(data_conv),
                     .value_o(data_o)
                   );

  d_ff #(
         .Width(1)
       ) conv_valid_delay_inst (
         .clk_i,
         .rst_i(1'b0),
         .en_i,
         .data_i((reg_cprm1_i.save_to_ram_o || reg_cprm1_i.save_to_buffer_o) ? conv_valid : 1'b0),
         .data_o(conv_valid_o)
       );

  d_ff #(
         .Width(1)
       ) conv_done_delay_inst (
         .clk_i,
         .rst_i(1'b0),
         .en_i,
         .data_i(conv_done == {EngineCount{1'b1}}),
         .data_o(conv_done_o)
       );

  //assign status_o.running = en_i && !done;
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

  logic signed  [Bits-1:0] data_o [EngineCount-1:0];
  logic conv_valid;
  logic conv_done;

  logic reg_reset;
  logic assert_on;

  convolution_layer #(
                      .MaxMatrixSize(MaxMatrixSize), // maximum matrix size that this convolver can convolve
                      .KernelSize(KernelSize), // kernel size
                      .EngineCount(EngineCount), // Amount of instantiated convolvers
                      .N(Bits) // total bit width
                    ) uut (
                      .clk_i(clk), // clock
                      .rst_i(rst), // reset active low
                      .en_i(en), // run the convolution

                      // Configuration Registers
                      .reg_bcfg1_i(reg_bcfg1.read),
                      .reg_bcfg2_i(reg_bcfg2.read),
                      .reg_bcfg3_i(reg_bcfg3.read),
                      .reg_cprm1_i(reg_cprm1.read),

                      // Data Inputs
                      .kernel_weights_i(kernel_weights), // kernel weights
                      .activation_data_i(activation_data), // activation data

                      // Data Outputs
                      .data_o, // convolution data output
                      .conv_valid_o(conv_valid), // convolution valid
                      .conv_done_o(conv_done), // convolution done

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
    en = 1'b1;

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
      assert(data_o[0] == 8'h00) else
              $error("Convolution 0 failed: output = %d, expected %d", data_o[0], 8'h00);
      assert(data_o[1] == 8'h00) else
              $error("Convolution 1 failed: output = %d, expected %d", data_o[1], 8'h00);
    end
  end
endmodule
