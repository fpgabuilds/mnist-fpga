// Inspiration taken from https://thedatabus.in/convolver
// and then heavily modified to fit the requirements of the project
// TODO: when matrix size is cut in half, we can duplicate covolution and get 2 for the price of 1 ewngine
module convolver #(
    parameter logic [13:0] MaxMatrixSize,  // maximum matrix size that this convolver can convolve
    parameter unsigned KernelSize,  // kernel size
    parameter unsigned N  // total bit width
) (
    input logic clk_i,  // clock
    input logic rst_i,  // reset active high
    input logic en_i,  // enable convolver
    input logic signed [N-1:0] data_i,  //data in
    input logic [5:0] stride_i,  // value of stride (horizontal and vertical stride are equal) 0-64
    input logic [13:0] matrix_size_i,  // size of the matrix
    input wire signed [N-1:0] weights_i[KernelSize*KernelSize-1:0],  // weights

    output logic signed [2*N-1:0] conv_o,  // convolution output
    output logic valid_conv_o,  // valid convolution output
    output logic end_conv_o,  // end of convolution

    input logic assert_on_i  // enable assertions
);
  always @(posedge clk_i) begin
    if (assert_on_i) begin
      assert (KernelSize > 1)
      else $error("KernelSize must be greater than 1");
      assert (N > 0)
      else $error("N must be greater than 0");
      assert (matrix_size_i >= KernelSize)
      else $error("matrix_size_i must be greater than or equal to KernelSize");
      assert (stride_i < matrix_size_i)
      else
        $error(
            "Stride must be less than matrix_size_i, stride = %0d, matrix_size_i = %0d",
            stride_i,
            matrix_size_i
        );
      assert (matrix_size_i <= MaxMatrixSize)
      else $error("matrix_size_i must be less than or equal to MaxMatrixSize");
    end
  end

  logic [2*N-1:0] conv_vals[KernelSize*KernelSize-2:0];

  generate
    genvar i;
    for (i = 0; i < KernelSize * KernelSize; i++) begin : g_MAC
      if(i == 0) // first MAC unit
      begin : g_first_mac
        mac #(
            .N(N)
        ) mac_start (
            .clk_i,
            .en_i,
            .value_i(data_i),
            .mult_i (weights_i[i]),
            .add_i  ({2 * N{1'b0}}),
            .mac_o  (conv_vals[i])
        );
      end
      else if((i+1) % KernelSize == 0) // end of the row
      begin
        if((i+1) == KernelSize*KernelSize) // end of convolver
        begin : g_conv_last_mac
          mac #(
              .N(N)
          ) mac_final (
              .clk_i,
              .en_i,
              .value_i(data_i),
              .mult_i (weights_i[i]),
              .add_i  (conv_vals[i-1]),
              .mac_o  (conv_o)
          );
        end else begin : g_row_last_mac
          logic signed [2*N-1:0] end_row_data;
          mac #(
              .N(N)
          ) mac_end_row (
              .clk_i,
              .en_i,
              .value_i(data_i),
              .mult_i (weights_i[i]),
              .add_i  (conv_vals[i-1]),
              .mac_o  (end_row_data)
          );

          logic [2*N-1:0] store[MaxMatrixSize-KernelSize-1:0];
          shift_reg_with_store #(
              .N(2 * N),
              .Length(MaxMatrixSize - KernelSize)
          ) row_shift (
              .clk_i,
              .en_i,
              .rst_i(),
              .rst_val_i({2 * N{1'b0}}),
              .data_i(end_row_data),
              .data_o(),
              .store_o(store)
          );
          assign conv_vals[i] = store[matrix_size_i-KernelSize-1];
        end
      end else begin : g_middle_mac
        mac #(
            .N(N)
        ) mac_middle (
            .clk_i,
            .en_i,
            .value_i(data_i),
            .mult_i (weights_i[i]),
            .add_i  (conv_vals[i-1]),
            .mac_o  (conv_vals[i])
        );
      end
    end
  endgenerate

  logic min_cycles;
  logic row_conv;
  logic stride_conv;

  // Count the amount of clock cycles used in the convolution
  localparam unsigned ClkCountSize = $clog2(MaxMatrixSize * MaxMatrixSize + 2);

  logic [ClkCountSize-1:0] max_clk_count;
  logic [ClkCountSize-1:0] clk_count;

  assign max_clk_count = matrix_size_i * matrix_size_i + 1;

  increment_then_stop #(
      .Bits(ClkCountSize)
  ) clk_counter (  // Counts total clock cycles used in this convolution
      .clk_i,
      .en_i,
      .rst_i,
      .start_val_i({ClkCountSize{1'b0}}),
      .end_val_i(max_clk_count),  // it does not matter if the actual matrix is smaller as the end
      .count_o(clk_count),  // of the convolution is signaled by the end_conv_o signal
      .assert_on_i
  );

  assign min_cycles = clk_count > ((KernelSize - 1) * matrix_size_i + KernelSize - 1);
  assign end_conv_o = (clk_count == max_clk_count) ? 1'b1 : 1'b0;


  // Count valid and invalid convolution outputs per row
  localparam unsigned ConvCountSize = $clog2(MaxMatrixSize - KernelSize + 1);

  // KernelSize - 2 ( + 1 for the 0 index)
  localparam unsigned InvConcCountSize = $clog2(KernelSize - 1);

  logic [ConvCountSize-1:0] max_conv_count;
  logic [ConvCountSize-1:0] conv_count;
  logic [InvConcCountSize-1:0] max_inv_count;
  logic [InvConcCountSize-1:0] inv_count;

  assign max_conv_count = matrix_size_i - KernelSize;
  assign max_inv_count  = KernelSize - 2;

  counter #(
      .Bits(ConvCountSize)
  ) conv_counter (
      .clk_i,
      .en_i(min_cycles && row_conv),
      .rst_i,
      .start_val_i({ConvCountSize{1'b0}}),
      .end_val_i(max_conv_count),
      .count_by_i({{ConvCountSize - 1{1'b0}}, 1'b1}),
      .count_o(conv_count),
      .assert_on_i
  );

  counter #(
      .Bits(InvConcCountSize)
  ) inv_counter (
      .clk_i,
      .en_i(!row_conv),
      .rst_i,
      .start_val_i({InvConcCountSize{1'b0}}),
      .end_val_i(max_inv_count),
      .count_by_i({{InvConcCountSize - 1{1'b0}}, 1'b1}),
      .count_o(inv_count),
      .assert_on_i
  );

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) row_conv <= 1'b1;
    else if (inv_count == KernelSize - 2) row_conv <= 1'b1;
    else if (conv_count == max_conv_count) row_conv <= 1'b0;
  end


  // Count the amount of output rows done in the convolution
  localparam unsigned RowCountSize = $clog2(MaxMatrixSize - KernelSize + 1);
  logic [RowCountSize-1:0] row_count;

  increment_then_stop #(
      .Bits(RowCountSize)
  ) row_counter (  // Counts total clock cycles used in this convolution
      .clk_i,
      .en_i(conv_count == matrix_size_i - KernelSize),
      .rst_i,
      .start_val_i({RowCountSize{1'b0}}),
      .end_val_i({RowCountSize{1'b1}}),
      .count_o(row_count),
      .assert_on_i
  );

  logic a;
  logic b;
  logic c;

  assign a = ((conv_count + 1) % stride_i == 0) && (row_count % stride_i == 0);
  assign b = (inv_count == KernelSize - 2) && (row_count % stride_i == 0);
  assign c = (clk_count == (KernelSize - 1) * matrix_size_i + KernelSize - 1);

  assign stride_conv = (a || b || c);
  assign valid_conv_o = (min_cycles && row_conv && stride_conv && !end_conv_o);

endmodule



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
