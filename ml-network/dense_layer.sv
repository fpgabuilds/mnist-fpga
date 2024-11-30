// The dense layer uses activation stationary to do the math, the weights should be looped through
// TODO: Add Testbench
module dense_layer #(
    parameter unsigned N,
    parameter unsigned [11:0] EngineCount = 4095
) (
    input logic clk_i,
    input logic en_i,
    input wire signed [N-1:0] value_i[EngineCount-1:0],
    input wire signed [N-1:0] weight_i[EngineCount-1:0],
    output logic signed [N-1:0] dense_o[EngineCount-1:0],

    // Configuration Registers
    IBcfg1.read reg_bcfg1_i,
    IBcfg2.read reg_bcfg2_i,
    IBcfg3.read reg_bcfg3_i,
    ICprm1.read reg_cprm1_i
);
  logic [5:0] shift_amount;
  assign shift_amount = {reg_bcfg2_i.shift_high_o, reg_bcfg1_i.shift_low_o};

  generate
    genvar i;
    for (i = 0; i < EngineCount; i++) begin : g_dense
      logic [2*N-1:0] dense_output;

      mac_shifter #(
          .N(N)
      ) dense_mac_inst (
          .clk_i,
          .en_i((i < reg_bcfg1_i.engine_count_o) ? en_i : 1'b0),
          .value_i(value_i[i]),
          .mult_i(weight_i[i]),
          .add_i(reg_cprm1_i.accumulate_o ? dense_output : {{2 * N} {1'b0}}),
          .shift_i(shift_amount),
          .mac_o(dense_output)
      );

      assign dense_o[i] = dense_output >>> reg_bcfg3_i.shift_final_o;
    end
  endgenerate
endmodule


