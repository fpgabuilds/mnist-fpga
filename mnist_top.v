module mnist_top #(
    parameter FileNameLength = 11, // length of FILE_NAME (in bytes). Since the length of "example.txt" is 11, so here is 11.
    parameter [52*8-1:0] FileName = "example.txt", // file name to read, ignore upper and lower case
    parameter N = 8, // total bit width
    parameter MaxMatrixSize = 28,
    parameter KernelSize = 3,
    parameter Stride = 1
  ) (
    input wire clk_i,
    input wire rst_ni,
    input [N-1:0] data_activation_i, // Data activation input

    // Convolution signals
    output wire [N-1:0] conv_o,
    output wire conv_valid_o
  );

  //------------------------------------------------------------------------------------
  // Memory initialization for weights and biases and current input activation
  //------------------------------------------------------------------------------------

  wire act_a_write_en;
  wire [$clog2(1024):0] act_a_addr;
  wire [N-1:0] act_a_data_in;
  wire [N-1:0] act_a_data_out;

  wire [$clog2(1024):0] act_b_addr;
  wire [N-1:0] act_b_data_out;


  dual_port_bram #(
                   .DataWidth(N),
                   .Depth(1024)
                 ) activation_bram (
                   .clk_i(clk_i),
                   // Port A (load data)
                   .a_write_en_i(act_a_write_en),
                   .a_addr_i(act_a_addr),
                   .a_data_i(act_a_data_in),
                   .a_data_o(act_a_data_out),
                   // Port B (Direct Convolution Access)
                   .b_write_en_i(1'b0),
                   .b_addr_i(act_b_addr),
                   .b_data_i({N{1'b0}}),
                   .b_data_o(act_b_data_out)
                 );

  wire wgt_a_write_en;
  wire [$clog2(1024):0] wgt_a_addr;
  wire [N-1:0] wgt_a_data_in;
  wire [N-1:0] wgt_a_data_out;

  wire [$clog2(1024):0] wgt_b_addr;
  wire [N-1:0] wgt_b_data_out;

  dual_port_bram #(
                   .DataWidth(N),
                   .Depth(1024)
                 ) weight_bram (
                   .clk_i(clk_i),
                   // Port A (load data)
                   .a_write_en_i(wgt_a_write_en),
                   .a_addr_i(wgt_a_addr),
                   .a_data_i(wgt_a_data_in),
                   .a_data_o(wgt_a_data_out),
                   // Port B (Direct Convolution Access)
                   .b_write_en_i(1'b0),
                   .b_addr_i(wgt_b_addr),
                   .b_data_i({N{1'b0}}),
                   .b_data_o(wgt_b_data_out)
                 );



  //------------------------------------------------------------------------------------
  // State Machine to load weights and biases then convolve
  //------------------------------------------------------------------------------------
  localparam STATE_LOAD_WEIGHTS = 2'b00;
  localparam STATE_TRANS = 2'b01;
  localparam STATE_LOAD_ACTIVATION = 2'b10;
  localparam STATE_CONVOLVE = 2'b11;

  localparam SizeOfActCount = $clog2(MaxMatrixSize*MaxMatrixSize) + 1;
  localparam [SizeOfActCount-1:0] ActCountTot = MaxMatrixSize*MaxMatrixSize; // Assumed to be bigger than kernel weight count
  localparam [SizeOfActCount-1:0] WeightCountTot = 2*KernelSize*KernelSize; // 2 for weights and biases



  reg [1:0] state;

  wire [SizeOfActCount-1:0] data_count;

  wire [SizeOfActCount-1:0] counter_max;
  wire run_counter;

  assign counter_max = (state == STATE_LOAD_WEIGHTS) ? WeightCountTot : ActCountTot;
  assign run_counter = (state == STATE_LOAD_WEIGHTS || state == STATE_LOAD_ACTIVATION);

  assign act_a_write_en = (state == STATE_LOAD_WEIGHTS || state == STATE_LOAD_ACTIVATION);
  assign act_a_addr = data_count;
  assign act_a_data_in = data_activation_i; // TODO: use multiple bytes to get the data

  assign wgt_a_write_en = (state == STATE_LOAD_WEIGHTS || state == STATE_LOAD_ACTIVATION);
  assign wgt_a_addr = data_count;
  assign wgt_a_data_in = data_activation_i; // TODO: use multiple bytes to get the data


  increment_then_stop #(
                        .Bits(SizeOfActCount) // Number of bits in the counter, this can be found using $clog2(N) where N is the maximum value of the counter
                      ) data_counter (
                        .clk_i(clk_i),
                        .run_i(run_counter),
                        .rst_i(!rst_ni),
                        .start_val_i({SizeOfActCount{1'b0}}),
                        .end_val_i(counter_max),
                        .count_o(data_count)
                      );


  always @(posedge clk_i or negedge rst_ni)
  begin
    if (!rst_ni)
      state <= STATE_LOAD_WEIGHTS;
    else
    begin
      case(state)
        STATE_LOAD_WEIGHTS:
        begin
          if (data_count == counter_max)
            state <= STATE_TRANS;
        end
        STATE_TRANS:
          state <= STATE_LOAD_ACTIVATION; // Once clock cycle to clear the counter
        STATE_LOAD_ACTIVATION:
        begin
          if (data_count == counter_max)
            state <= STATE_CONVOLVE;
        end
        STATE_CONVOLVE:
          state <= STATE_CONVOLVE;
        default:
          state <= STATE_TRANS;
      endcase
    end
  end






  //------------------------------------------------------------------------------------
  // Convolution Layer
  //------------------------------------------------------------------------------------

  convolution_layer #(
                      .MatrixSize(MaxMatrixSize), // maximum matrix size that this convolver can convolve
                      .KernelSize(KernelSize), // kernel size (TODO: Make dynamic)
                      .Stride(Stride), // value of stride (horizontal and vertical stride are equal)
                      .AddrSize(10), // size of the address (bits)
                      .N(N), // total bit width
                      .Q(12) // number of fractional bits in case of fixed point representation.
                    ) convolution (
                      .clk_i(clk_i), // clock
                      .rst_ni(rst_ni), // reset active low
                      .run_i(state == STATE_CONVOLVE), // run the convolution
                      .conv_count_i(7'd100), // convolution count (max 128)

                      // input / activation layer ram
                      .activation_ram_data_i(act_b_data_out),
                      .activation_ram_addr_o(act_b_addr),

                      // weight and bias ram
                      .weights_ram_data_i(wgt_b_data_out),
                      .weights_ram_addr_o(wgt_b_addr),

                      .conv_op_o(conv_o), // convolution output
                      .valid_conv_o(conv_valid_o) // valid convolution output
                    );

endmodule
