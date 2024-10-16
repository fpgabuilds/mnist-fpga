// TODO: add padding to the input matrix
module convolution_layer #(
    parameter MatrixSize = 3, // maximum matrix size that this convolver can convolve
    parameter KernelSize = 3, // kernel size (TODO: Make dynamic)
    parameter Stride = 1, // value of stride (horizontal and vertical stride are equal)
    parameter AddrSize = 10, // size of the address (bits)
    parameter ConvCountSize = 7, // size of the convolution count
    parameter N = 16, // total bit width
    parameter Q = 12 // number of fractional bits in case of fixed point representation.
  ) (
    input wire clk_i, // clock
    input wire rst_ni, // reset active low
    input wire run_i, // run the convolution
    input wire [ConvCountSize-1:0] conv_count_i, // convolution count (max 128)

    // input / activation layer ram
    input wire [N-1:0] activation_ram_data_i,
    output wire [AddrSize-1:0] activation_ram_addr_o,

    // weight and bias ram
    input wire [N-1:0] weights_ram_data_i,
    output wire [AddrSize-1:0] weights_ram_addr_o,

    output [N-1:0] conv_op_o, // convolution output
    output valid_conv_o // valid convolution output
  );

  wire [N*KernelSize*KernelSize-1:0] flattened_weights, flattened_bias;
  wire end_conv;
  wire loaded_data;
  wire [ConvCountSize-1:0] data_count;
  wire rstn;

  reg [1:0] state;

  localparam STATE_LOAD_WEIGHTS = 2'b00;
  localparam STATE_TRANS = 2'b01;
  localparam STATE_CONVOLVE = 2'b10;



  logic [N-1:0] weights [KernelSize*KernelSize-1:0];

  generate
    genvar l;
    for(l = 0; l < KernelSize * KernelSize; l = l + 1)
    begin: assign_weight
      assign weights [l][N-1:0] = flattened_weights[N*l +: N];
    end
  endgenerate


  increment_then_stop #(
                        .Bits(ConvCountSize)
                      )
                      conv_counter (
                        .clk_i(loaded_data),
                        .run_i(run_i),
                        .rst_i(1'b0),
                        .start_val_i({ConvCountSize{1'b0}}),
                        .end_val_i(conv_count_i),
                        .count_o(data_count)
                      );

  increment_then_stop #(
                        .Bits(AddrSize)
                      )
                      activation_data_counter (
                        .clk_i(clk_i),
                        .run_i(state == STATE_CONVOLVE),
                        .rst_i(1'b0),
                        .start_val_i({AddrSize{1'b0}}),
                        .end_val_i(MatrixSize*MatrixSize),
                        .count_o(activation_ram_addr_o)
                      );

  weight_loader #(
                  .N(N), // total bit width
                  .KernelSize(KernelSize), // size of the weight matrix
                  .AddrSize(AddrSize) // size of the address (bits)
                ) weight_bias_loader (
                  .clk_i(clk_i),
                  .load_en_i(state == STATE_LOAD_WEIGHTS),
                  .data_pos_0_i(KernelSize*KernelSize*2*data_count), // Start address of the weights and biases
                  .update_i(state == STATE_TRANS), // Update the weights and biases

                  .weights_o({flattened_weights, flattened_bias}), // Contains both weights and biases
                  .loaded_o(loaded_data),

                  // RAM interface
                  .data_i(weights_ram_data_i),
                  .addr_o(weights_ram_addr_o)
                );

  convolver #(
              .MatrixSize(MatrixSize),
              .KernelSize(KernelSize),
              .N(N)
            ) conv_inst (
              .clk_i(clk_i),
              .rst_i(!rstn),
              .en_i(run_i),
              .data_i(activation_ram_data_i),
              .stride_i(Stride),
              .matrix_size_i(MatrixSize),
              .weights_i(weights),
              .conv_o(conv_op_o),
              .valid_conv_o(valid_conv_o),
              .end_conv_o(end_conv)
            );

  assign rstn = (state == STATE_CONVOLVE);

  always @ (posedge clk_i or negedge rst_ni)
  begin
    if (!rst_ni)
      state <= STATE_LOAD_WEIGHTS;
    else
    begin
      case(state)
        STATE_LOAD_WEIGHTS:
        begin
          if (loaded_data)
            state <= STATE_TRANS;
        end
        STATE_TRANS:
          state <= STATE_CONVOLVE;
        STATE_CONVOLVE:
          state <= STATE_TRANS;
      endcase
    end
  end


endmodule
