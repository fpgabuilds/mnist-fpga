// Inspiration taken from https://thedatabus.in/convolver
// and then heavily modified to fit the requirements of the project
module convolver #(
    parameter MatrixSize = 3, // maximum matrix size that this convolver can convolve
    parameter KernelSize = 3, // kernel size
    parameter N = 16 // total bit width
  )(
    input logic clk_i, // clock
    input logic rst_i, // reset active high
    input logic en_i, // enable convolver
    input logic [N-1:0] data_i, //data in
    input logic [5:0] stride_i, // value of stride (horizontal and vertical stride are equal) 0-64
    input logic [$clog2(MatrixSize):0] matrix_size_i, // size of the matrix
    input [N-1:0] weights_i [KernelSize*KernelSize-1:0], // weights

    output logic [2*N-1:0] conv_o, // convolution output
    output logic valid_conv_o, // valid convolution output
    output logic end_conv_o // end of convolution
  );
  always @(posedge clk_i)
  begin
    assert (KernelSize > 1) else
             $error("KernelSize must be greater than 1");
    assert (MatrixSize > 1) else
             $error("MatrixSize must be greater than 1");
    assert (N > 0) else
             $error("N must be greater than 0");
    assert (MatrixSize >= KernelSize) else
             $error("MatrixSize must be greater than or equal to KernelSize");
    assert (stride_i < MatrixSize) else
             $error("Stride must be less than MatrixSize, stride = %0d, MatrixSize = %0d", stride_i, MatrixSize);
    assert (matrix_size_i <= MatrixSize) else
             $error("matrix_size_i must be less than or equal to MatrixSize");
    assert (matrix_size_i > 1) else
             $error("matrix_size_i must be greater than 1");
  end

  logic [2*N-1:0] conv_vals [KernelSize*KernelSize-2:0];

  generate
    genvar i;
    for(i = 0; i < KernelSize*KernelSize; i++)
    begin: MAC
      if(i == 0) // first MAC unit
      begin
        mac #(.N(N)) mac_start (
              .clk_i(clk_i),
              .rst_i(rst_i),
              .en_i(en_i),
              .value_i(data_i),
              .mult_i(weights_i[i]),
              .add_i({2*N{1'b0}}),
              .mac_o(conv_vals[i])
            );
      end
      else if((i+1) % KernelSize == 0) // end of the row
      begin
        if((i+1) == KernelSize*KernelSize) // end of convolver
        begin
          mac #(.N(N)) mac_final (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .en_i(en_i),
                .value_i(data_i),
                .mult_i(weights_i[i]),
                .add_i(conv_vals[i-1]),
                .mac_o(conv_o)
              );
        end
        else
        begin
          logic [2*N-1:0] end_row_data;
          mac #(.N(N)) mac_end_row (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .en_i(en_i),
                .value_i(data_i),
                .mult_i(weights_i[i]),
                .add_i(conv_vals[i-1]),
                .mac_o(end_row_data)
              );

          shift_reg #(
                      .N(2*N), // Width of the data
                      .Length(MatrixSize-KernelSize) // Number of registers
                    ) row_shift (
                      .clk_i(clk_i), // clock
                      .en_i(en_i), // enable shift
                      .rst_i(rst_i), //reset
                      .rst_val_i({2*N{1'b0}}), //reset value (Every register will be initialized with this value)
                      .data_i(end_row_data), //data in
                      .data_o(conv_vals[i]) //data out
                    );
        end
      end
      else
      begin
        mac #(.N(N)) mac_middle (
              .clk_i(clk_i),
              .rst_i(rst_i),
              .en_i(en_i),
              .value_i(data_i),
              .mult_i(weights_i[i]),
              .add_i(conv_vals[i-1]),
              .mac_o(conv_vals[i])
            );
      end
    end
  endgenerate

  logic min_cycles;
  logic row_conv;
  logic stride_conv;

  // Count the amount of clock cycles used in the convolution
  localparam ClkCountSize = $clog2(MatrixSize*MatrixSize + 1) + 1;

  logic [ClkCountSize-1:0] max_clk_count;
  logic [ClkCountSize-1:0] clk_count;

  assign max_clk_count = matrix_size_i*matrix_size_i + 1;

  increment_then_stop #(
                        .Bits(ClkCountSize)
                      ) clk_counter ( // Counts total clock cycles used in this convolution
                        .clk_i(clk_i),
                        .run_i(en_i),
                        .rst_i(rst_i),
                        .start_val_i({ClkCountSize{1'b0}}),
                        .end_val_i(max_clk_count), // it does not matter if the actual matrix is smaller as the end
                        .count_o(clk_count)        // of the convolution is signaled by the end_conv_o signal
                      );

  assign min_cycles = clk_count > ((KernelSize-1)*MatrixSize+KernelSize-1);
  assign end_conv_o = (clk_count == max_clk_count) ? 1'b1 : 1'b0;


  // Count valid and invalid convolution outputs per row
  localparam ConvCountSize = $clog2(MatrixSize-KernelSize) + 1;
  localparam InvConcCountSize = $clog2(KernelSize-2) + 1;

  logic [ConvCountSize-1:0] max_conv_count;
  logic [ConvCountSize-1:0] conv_count;
  logic [InvConcCountSize-1:0] max_inv_count;
  logic [InvConcCountSize-1:0] inv_count;

  assign max_conv_count = MatrixSize-KernelSize;
  assign max_inv_count = KernelSize-2;

  counter #(
            .Bits(ConvCountSize)
          ) conv_counter (
            .clk_i,
            .en_i(min_cycles && row_conv),
            .rst_i,
            .start_val_i({ConvCountSize{1'b0}}),
            .end_val_i(max_conv_count),
            .count_by_i({{ConvCountSize-1{1'b0}}, 1'b1}),
            .count_o(conv_count)
          );

  counter #(
            .Bits(InvConcCountSize)
          ) inv_counter (
            .clk_i,
            .en_i(!row_conv),
            .rst_i,
            .start_val_i({InvConcCountSize{1'b0}}),
            .end_val_i(max_inv_count),
            .count_by_i({{InvConcCountSize-1{1'b0}}, 1'b1}),
            .count_o(inv_count)
          );

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
      row_conv <= 1'b1;
    else if (inv_count == KernelSize-2)
      row_conv <= 1'b1;
    else if (conv_count == max_conv_count)
      row_conv <= 1'b0;
  end


  // Count the amount of output rows done in the convolution
  localparam RowCountSize = $clog2(MatrixSize-KernelSize) + 1;

  logic [RowCountSize-1:0] max_row_count;
  logic [RowCountSize-1:0] row_count;

  assign max_row_count = MatrixSize - KernelSize;

  increment_then_stop #(
                        .Bits(RowCountSize)
                      ) row_counter ( // Counts total clock cycles used in this convolution
                        .clk_i(clk_i),
                        .run_i(conv_count == MatrixSize-KernelSize),
                        .rst_i(rst_i),
                        .start_val_i({RowCountSize{1'b0}}),
                        .end_val_i(max_row_count), // it does not matter if the actual matrix is smaller
                        .count_o(row_count)
                      );

  logic a;
  logic b;
  logic c;

  assign a = ((conv_count + 1) % stride_i == 0) && (row_count % stride_i == 0);
  assign b = (inv_count == KernelSize-2)&&(row_count % stride_i == 0);
  assign c = (clk_count == (KernelSize-1)*MatrixSize+KernelSize-1);

  assign stride_conv = (a || b || c);
  assign valid_conv_o = (min_cycles && row_conv && stride_conv && !end_conv_o);

endmodule



// TODO: Test stride and verify that it does the optimal clock cycles
module tb_convolver;
  parameter MatrixSize = 8;  // Changed to 8 for the 8x8 activation map
  parameter KernelSize = 3;  // Kept as 3 for the 3x3 kernel
  parameter N = 16;

  // Inputs
  reg clk;
  reg en;
  reg rst;
  reg [N-1:0] activation;
  logic [N-1:0] weights_3x3 [KernelSize*KernelSize-1:0];

  // Outputs
  logic [2*N-1:0] conv_op;
  logic end_conv;
  logic valid_conv;
  integer i;

  // Counter for checking output
  integer output_counter;

  // Expected output values (replace with actual expected values)
  logic [2*N-1:0] expected_outputs [36-1:0];  // 36 is the number of outputs for 8x8 input with 3x3 kernel

  // Instantiate the Unit Under Test (UUT)
  convolver #(
              .MatrixSize(MatrixSize),
              .KernelSize(KernelSize),
              .N(N)
            ) uut_3x3 (
              .clk_i(clk),
              .rst_i(rst),
              .en_i(en),
              .data_i(activation),
              .stride_i(6'd1),
              .matrix_size_i(MatrixSize), // size of the matrix
              .weights_i(weights_3x3),
              .conv_o(conv_op),
              .valid_conv_o(valid_conv),
              .end_conv_o(end_conv)
            );

  always #5 clk = ~clk;

  initial
  begin
    // Initialize Inputs
    clk = 0;
    en = 0;
    rst = 0;
    activation = 0;
    output_counter = 0;

    weights_3x3 = '{
                  16'd8, 16'd7, 16'd6,
                  16'd5, 16'd4, 16'd3,
                  16'd2, 16'd1, 16'd0
                };

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


    // Wait 100 ns for global reset to finish
    #10;
    rst = 1;
    #10;
    rst = 0;
    #10;
    en = 1;
    for(i = 0; i < 64; i = i + 1)  // 64 inputs for 8x8 matrix
    begin
      activation = i;
      @(posedge clk);
      if (valid_conv)
      begin
        assert(conv_op == expected_outputs[output_counter])
              else
                $error("Mismatch at output %0d: expected %0d, got %0d", output_counter, expected_outputs[output_counter], conv_op);
        output_counter = output_counter + 1;
      end
    end
    $display("Test completed. Total outputs checked: %0d", output_counter);
    $finish;
  end
endmodule


// module tb_convolver;
//   parameter MatrixSize = 4;  // Changed to 4 for the 4x4 activation map
//   parameter KernelSize = 3;  // Changed to 3 for the 3x3 kernel
//   parameter N = 16;

//   // Inputs
//   logic clk;
//   logic rst;
//   logic en;
//   logic [N-1:0] data;
//   logic [5:0] stride;

//   // Outputs for 3x3 convolver
//   logic [N-1:0] conv_3x3;
//   logic valid_conv_3x3;
//   logic end_conv_3x3;

//   // Test vectors
//   logic [N-1:0] input_matrix [MatrixSize*MatrixSize-1:0];
//   logic [N-1:0] weights_3x3 [KernelSize*KernelSize-1:0];
//   logic [N-1:0] expected_output [2*2-1:0];  // 2x2 output for 4x4 input with 3x3 kernel

//   // Instantiate the 3x3 convolver
//   convolver #(
//               .MatrixSize(MatrixSize),
//               .KernelSize(KernelSize),
//               .N(N)
//             ) uut_3x3 (
//               .clk_i(clk),
//               .rst_i(rst),
//               .en_i(en),
//               .data_i(data),
//               .stride_i(stride),
//               .weights_i(weights_3x3),
//               .conv_o(conv_3x3),
//               .valid_conv_o(valid_conv_3x3),
//               .end_conv_o(end_conv_3x3)
//             );

//   // Clock generation
//   always #5 clk = ~clk;

//   initial
//   begin
//     // Initialize inputs
//     clk = 1'b0;
//     rst = 1'b1;
//     en = 1'b0;
//     data = {N{1'b0}};
//     stride = 6'd1;

//     // Initialize test vectors
//     input_matrix = '{
//                    16'd15,  16'd14,  16'd13,  16'd12,
//                    16'd11,  16'd10,  16'd9,  16'd8,
//                    16'd7,  16'd6,  16'd5, 16'd4,
//                    16'd3, 16'd2, 16'd1, 16'd0
//                  };

//     weights_3x3 = '{
//                   16'd8, 16'd7, 16'd6,
//                   16'd5, 16'd4, 16'd3,
//                   16'd2, 16'd1, 16'd0
//                 };

//     expected_output = '{
//                       16'd258, 16'd294,
//                       16'd402, 16'd438
//                     };

//     // Reset
//     @(negedge clk) rst = 1'b0;

//     // Test case: 3x3 convolution
//     $display("Test: 3x3 convolution, Time: %0t", $time);

//     en = 1'b1;

//     for (int i = 0; i < MatrixSize*MatrixSize; i++)
//     begin
//       data = input_matrix[i];
//       @(posedge clk);
//       if (valid_conv_3x3)
//       begin
//         automatic int row = i / MatrixSize;
//         automatic int col = i % MatrixSize;
//         if (row >= KernelSize-1 && col >= KernelSize-1)
//         begin
//           automatic int output_index = (row-KernelSize+1)*2 + (col-KernelSize+1);
//           assert(conv_3x3 == expected_output[output_index])
//                 else
//                   $error("3x3 convolution error at index %0d: expected %0d, got %0d",
//                          output_index, expected_output[output_index], conv_3x3);
//         end
//       end
//     end

//     @(posedge clk);
//     assert(end_conv_3x3 == 1'b1) else
//             $error("3x3 convolution did not signal end_conv");

//     $display("Test completed successfully!");
//     $finish;
//   end
// endmodule

// module tb_convolver;
//   parameter MatrixSize = 4;  // Changed to 4 for the 4x4 activation map
//   parameter KernelSize = 3;  // Changed to 3 for the 3x3 kernel
//   parameter N = 16;

//   // Inputs
//   reg clk;
//   reg en;
//   reg rst;
//   reg [N-1:0] activation;
//   logic [N-1:0] weights_3x3 [KernelSize*KernelSize-1:0];

//   // Outputs
//   logic [2*N-1:0] conv_op;
//   logic end_conv;
//   logic valid_conv;
//   integer i;

//   // Instantiate the Unit Under Test (UUT)
//   convolver #(
//               .MatrixSize(MatrixSize),
//               .KernelSize(KernelSize),
//               .N(N)
//             ) uut_3x3 (
//               .clk_i(clk),
//               .rst_i(rst),
//               .en_i(en),
//               .data_i(activation),
//               .stride_i(6'd1),
//               .matrix_size_i(MatrixSize), // size of the matrix
//               .weights_i(weights_3x3),
//               .conv_o(conv_op),
//               .valid_conv_o(valid_conv),
//               .end_conv_o(end_conv)
//             );

//   always #5 clk = ~clk;

//   initial
//   begin
//     // Initialize Inputs
//     clk = 0;
//     en = 0;
//     rst = 0;
//     activation = 0;

//     weights_3x3 = '{
//                   16'd8, 16'd7, 16'd6,
//                   16'd5, 16'd4, 16'd3,
//                   16'd2, 16'd1, 16'd0
//                 };

//     // weights_3x3 = '{
//     //               16'd0, 16'd1, 16'd2,
//     //               16'd3, 16'd4, 16'd5,
//     //               16'd6, 16'd7, 16'd8
//     //             };
//     // Wait 100 ns for global reset to finish
//     #10;
//     clk = 0;
//     en = 0;
//     activation = 0;
//     rst =1;
//     #10;
//     rst =0;
//     #10;
//     en=1;
//     //we use the same set of weights and activations as the sample input in the golden model (python code) above.
//     for(i=0;i<255;i=i+1)
//     begin
//       activation = i;
//       @(posedge clk);
//     end
//     $finish;
//   end
// endmodule
