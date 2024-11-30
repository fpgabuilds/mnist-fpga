// TODO: Test stride and verify that it does the optimal clock cycles
module tb_convolver;
  parameter logic [13:0] MaxMatrixSize = 10;  // Changed to 8 for the 8x8 activation map
  parameter unsigned [13:0] MatrixSize = 8;  // Changed to 8 for the 8x8 activation map
  parameter unsigned KernelSize = 3;  // Kept as 3 for the 3x3 kernel
  parameter unsigned N = 16;

  // Inputs
  reg clk;
  reg en;
  reg rst;
  reg [N-1:0] activation;
  logic signed [N-1:0] weights_3x3[KernelSize*KernelSize-1:0];

  // Outputs
  logic signed [2*N-1:0] conv_op;
  logic end_conv;
  logic valid_conv;
  integer i;

  // Counter for checking output
  integer output_counter;

  // Expected output values (replace with actual expected values)
  logic signed [2*N-1:0] expected_outputs [36-1:0];  // 36 is the number of outputs for 8x8 input with 3x3 kernel

  // Instantiate the Unit Under Test (UUT)
  convolver #(
      .MaxMatrixSize(MaxMatrixSize),
      .KernelSize(KernelSize),
      .N(N)
  ) uut_3x3 (
      .clk_i(clk),
      .rst_i(rst),
      .en_i(en),
      .data_i(activation),
      .stride_i(6'd1),
      .matrix_size_i(MatrixSize),  // size of the matrix
      .weights_i(weights_3x3),
      .conv_o(conv_op),
      .valid_conv_o(valid_conv),
      .end_conv_o(end_conv),
      .assert_on_i(1'b1)
  );

  always #5 clk = ~clk;

  initial begin
    // Initialize Inputs
    clk = 0;
    en = 0;
    rst = 0;
    activation = 0;
    output_counter = 0;

    weights_3x3 = '{16'd8, 16'd7, 16'd6, 16'd5, 16'd4, 16'd3, 16'd2, 16'd1, 16'd0};

    expected_outputs[0] = 32'd474;
    expected_outputs[1] = 32'd510;
    expected_outputs[2] = 32'd546;
    expected_outputs[3] = 32'd582;
    expected_outputs[4] = 32'd618;
    expected_outputs[5] = 32'd654;
    expected_outputs[6] = 32'd762;
    expected_outputs[7] = 32'd798;
    expected_outputs[8] = 32'd834;
    expected_outputs[9] = 32'd870;
    expected_outputs[10] = 32'd906;
    expected_outputs[11] = 32'd942;
    expected_outputs[12] = 32'd1050;
    expected_outputs[13] = 32'd1086;
    expected_outputs[14] = 32'd1122;
    expected_outputs[15] = 32'd1158;
    expected_outputs[16] = 32'd1194;
    expected_outputs[17] = 32'd1230;
    expected_outputs[18] = 32'd1338;
    expected_outputs[19] = 32'd1374;
    expected_outputs[20] = 32'd1410;
    expected_outputs[21] = 32'd1446;
    expected_outputs[22] = 32'd1482;
    expected_outputs[23] = 32'd1518;
    expected_outputs[24] = 32'd1626;
    expected_outputs[25] = 32'd1662;
    expected_outputs[26] = 32'd1698;
    expected_outputs[27] = 32'd1734;
    expected_outputs[28] = 32'd1770;
    expected_outputs[29] = 32'd1806;
    expected_outputs[30] = 32'd1914;
    expected_outputs[31] = 32'd1950;
    expected_outputs[32] = 32'd1986;
    expected_outputs[33] = 32'd2022;
    expected_outputs[34] = 32'd2058;
    expected_outputs[35] = 32'd2094;

    @(posedge clk);
    rst = 1;
    @(posedge clk);
    rst = 0;
    @(posedge clk);
    en = 1;
    for (
        i = 0; i < 67; i = i + 1
    )  // 64 inputs for 8x8 matrix and then a few more to finish the convolution
        begin
      activation = i;
      @(posedge clk);
      if (valid_conv) begin
        assert (conv_op == expected_outputs[output_counter])
        else
          $error(
              "Mismatch at output %0d: expected %0d, got %0d",
              output_counter,
              expected_outputs[output_counter],
              conv_op
          );
        output_counter = output_counter + 1;
      end
    end
    assert (output_counter == 36)
    else $error("Expected 36 outputs, got %0d", output_counter);
    $display("Test completed successfully");
    $stop;
  end
endmodule
