// TODO: Add more test that cover other features
module tb_convolution_layer ();
  parameter unsigned Bits = 8;
  parameter unsigned EngineCount = 2;
  parameter unsigned KernelSize = 3;
  parameter unsigned MaxMatrixSize = 10;
  parameter unsigned MatrixSize = 5;

  logic clk;
  logic en;
  logic rst;

  logic signed [Bits-1:0] kernel_weights[EngineCount-1:0][KernelSize*KernelSize-1:0];
  logic signed [Bits-1:0] activation_data;

  logic signed [Bits-1:0] data_out[EngineCount-1:0];
  logic conv_valid;
  logic conv_done;

  logic assert_on;

  logic start;

  logic [15:0] reg_bcfg1;
  logic [15:0] reg_bcfg2;
  logic [15:0] reg_cprm1;

  convolution_layer #(
      .MaxMatrixSize(MaxMatrixSize),
      .KernelSize(KernelSize),
      .EngineCount(EngineCount),
      .Bits(Bits)
  ) uut (
      .clk_i(clk),
      .rst_i(rst),
      .start_i(start),
      .kernel_weights_i(kernel_weights),
      .reg_bcfg1_i(reg_bcfg1),
      .reg_bcfg2_i(reg_bcfg2),
      .reg_cprm1_i(reg_cprm1),
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

  assign kernel_weights[1][0] = 8'h0A;  // 10
  assign kernel_weights[1][1] = 8'hF6;  // -10
  assign kernel_weights[1][2] = 8'h14;  // 20
  assign kernel_weights[1][3] = 8'hEC;  // -20
  assign kernel_weights[1][4] = 8'h1E;  // 30
  assign kernel_weights[1][5] = 8'hE2;  // -30
  assign kernel_weights[1][6] = 8'h28;  // 40
  assign kernel_weights[1][7] = 8'hD8;  // -40
  assign kernel_weights[1][8] = 8'h32;  // 50


  initial begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b0;
    activation_data = 8'd255;
    assert_on = 1'b0;
    start = 1'b0;
    reg_bcfg1 = 16'h0002;  // Shift = 0, EngineCount = 2
    reg_bcfg2 = 16'h0005;  // MatrixSize = 5
    reg_cprm1 = 16'b0000_0000_0100_0000;  // Stride = 1

    @(posedge clk);
    assert_on = 1'b1;
    rst = 1'b0;

    @(posedge clk);
    start = 1'b1;

    @(posedge clk);
    en = 1'b1;
    start = 1'b0;
    reg_bcfg2 = 16'h0010;  // Test that these are cloned on start

    for (int i = 0; i < MatrixSize * MatrixSize; i = i + 1) begin
      activation_data = 8'(i);
      @(posedge clk);
    end

    @(posedge conv_done);
    @(posedge clk);
    reg_bcfg2 = 16'h0005;  // MatrixSize = 5
    reg_cprm1 = 16'b0000_0000_0100_0101;  // Stride = 1
    rst = 1'b1;
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    for (int i = 0; i < MatrixSize * MatrixSize; i = i + 1) begin
      activation_data = 8'(-i);
      @(posedge clk);
    end

    @(posedge conv_done);
    @(posedge clk);

    $stop;
  end

  always @(posedge clk) begin
    if (conv_valid) begin
      assert (data_out[0] == 8'h00)
      else $error("Convolution 0 failed: output = %d, expected %d", data_out[0], 8'h00);
      assert (data_out[1] == 8'h00)
      else $error("Convolution 1 failed: output = %d, expected %d", data_out[1], 8'h00);
    end
  end
endmodule
