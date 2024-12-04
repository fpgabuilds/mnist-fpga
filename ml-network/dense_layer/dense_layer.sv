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
    input logic [15:0] reg_bcfg1_i,
    input logic [15:0] reg_bcfg2_i,
    input logic [15:0] reg_cprm1_i
);
  import aether_registers::*;

  logic [5:0] shift_amount;
  assign shift_amount = {Bcfg2ShiftHigh(reg_bcfg2_i), Bcfg1ShiftLow(reg_bcfg1_i)};

  generate
    genvar i;
    for (i = 0; i < EngineCount; i++) begin : g_dense
      logic [2*N-1:0] dense_output;

      mac_shifter #(
          .N(N)
      ) dense_mac_inst (
          .clk_i,
          .en_i((i < Bcfg1EngineCount(reg_bcfg1_i)) ? en_i : 1'b0),
          .value_i(value_i[i]),
          .mult_i(weight_i[i]),
          .add_i(Crpm1Accumulate(reg_cprm1_i) ? dense_output : {{2 * N} {1'b0}}),
          .shift_i(shift_amount),
          .mac_o(dense_output)
      );

      assign dense_o[i] = dense_output >>> N;
    end
  endgenerate
endmodule


