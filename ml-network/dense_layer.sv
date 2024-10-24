module dense_layer #(
    parameter N = 16,
    parameter EngineCount = 1024
  ) (
    input logic clk_i,
    input logic rst_i,
    input logic en_i,
    input wire signed [N-1:0] value_i [EngineCount-1:0],
    input wire signed [N-1:0] weight_i [EngineCount-1:0],
    output logic signed [N-1:0] dense_o [EngineCount-1:0],

    IDenseConfig.read config_1_i  //accum = 1 for 1x1 conv, and 0 for dense
  );

  generate
    genvar i;
    for (i = 0; i < EngineCount; i++)
    begin : dense
      logic [2*N-1:0] dense_output;
      logic shifted;
      logic [5:0] shift_count;
      logic [5:0] shifted_amount;

      mac_shifter #(
                    .N(N)
                  )(
                    .clk_i,
                    .rst_i,
                    .en_i,
                    .value_i(value_i[i]),
                    .mult_i(weight_i),
                    .add_i(config_1_i.accum? dense_output : {{2*N}{1'b0}}),
                    .mac_o(dense_output),
                    .shifted_o(shifted)
                  );


      increment_then_stop #(
                            .Bits(6) // Number of bits in the counter, this can be found using $clog2(N) where N is the maximum value of the counter
                          ) (
                            .clk_i, // Clock input
                            .run_i(shifted), // Run signal, when high the counter will increment, when low the counter will not change but will hold the current value
                            .rst_i, // Reset signal, when low the counter will be reset to the start value. Not tied to the clock
                            .start_val_i(6'b0), // The value the counter will be set to when rst_i is high
                            .end_val_i(config_1_i.shift), // The value the counter will stop at
                            .count_o(shift_count) // The current value of the counter, will start at start_val_i and increment until end_val_i
                          );

      assign shifted_amount = config_1_i.accum? shift_count : {{5'b0}, shifted};

      assign dense_o[i] = dense_output >>> (config_1_i.shift - shifted_amount) ;
    end
  endgenerate
endmodule


