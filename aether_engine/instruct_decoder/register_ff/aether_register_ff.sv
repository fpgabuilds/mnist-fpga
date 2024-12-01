/*
aether_register_ff#(
    .RegVersnDefault(16'h6C00),
    .RegHwridDefault(16'hB2E9),
    .RegMemupDefault(16'h0000),
    .RegMstrtDefault(16'h0000),
    .RegMenddDefault(16'h0000),
    .RegBcfg1Default(16'h0000),
    .RegBcfg2Default(16'h0000),
    .RegBcfg3Default(16'h0000),
    .RegCprm1Default(16'h0040),
    .RegStatsDefault(16'h0000)
) (
    .clk_i,
    .rst_i,

    .reg_memup_i,
    .we_memup_i,
    .reg_mstrt_i,
    .we_mstrt_i,
    .reg_mendd_i,
    .we_mendd_i,
    .reg_bcfg1_i,
    .we_bcfg1_i,
    .reg_bcfg2_i,
    .we_bcfg2_i,
    .reg_bcfg3_i,
    .we_bcfg3_i,
    .reg_cprm1_i,
    .we_cprm1_i,
    .reg_stats_lower_i,
    .we_stats_lower_i,
    .reg_stats_upper_i,
    .we_stats_upper_i,

    .reg_versn_o(),
    .reg_hwrid_o(),
    .reg_memup_o(),
    .reg_mstrt_o(),
    .reg_mendd_o(),
    .reg_bcfg1_o(),
    .reg_bcfg2_o(),
    .reg_bcfg3_o(),
    .reg_cprm1_o(),
    .reg_stats_o()
);
*/


module aether_register_ff #(
    /// Version Register Value
    parameter logic [15:0] RegVersnDefault = 16'h6C00,

    /// Hardware ID Register Value
    parameter logic [15:0] RegHwridDefault = 16'hB2E9,

    /// Upper Memory Address Register Reset Value
    parameter logic [15:0] RegMemupDefault = 16'h0000,

    /// Memory Start Address Register Reset Value
    parameter logic [15:0] RegMstrtDefault = 16'h0000,

    /// Memory End Address Register Reset Value
    parameter logic [15:0] RegMenddDefault = 16'h0000,

    /// Base Configuration Register 1 Reset Value
    parameter logic [15:0] RegBcfg1Default = 16'h0000,

    /// Base Configuration Register 2 Reset Value
    parameter logic [15:0] RegBcfg2Default = 16'h0000,

    /// Base Configuration Register 3 Reset Value
    parameter logic [15:0] RegBcfg3Default = 16'h0000,

    /// Convolution Parameter Register 1 Reset Value
    parameter logic [15:0] RegCprm1Default = 16'h0040,

    /// Stats Register Reset Value
    parameter logic [15:0] RegStatsDefault = 16'h0000
) (
    input logic clk_i,
    input logic rst_i,

    //input logic [15:0] reg_versn_i, /// Version Register
    //input logic [15:0] reg_hwrid_i, /// Hardware ID Register
    input logic [15:0] reg_memup_i,  /// Upper Memory Address Register
    input logic we_memup_i,  /// Upper Memory Address Register Write Enable

    input logic [15:0] reg_mstrt_i,  /// Memory Start Address Register
    input logic we_mstrt_i,  /// Memory Start Address Register Write Enable

    input logic [15:0] reg_mendd_i,  /// Memory End Address Register
    input logic we_mendd_i,  /// Memory End Address Register Write Enable

    input logic [15:0] reg_bcfg1_i,  /// Base Configuration Register 1
    input logic we_bcfg1_i,  /// Base Configuration Register 1 Write Enable

    input logic [15:0] reg_bcfg2_i,  /// Base Configuration Register 2
    input logic we_bcfg2_i,  /// Base Configuration Register 2 Write Enable

    input logic [15:0] reg_bcfg3_i,  /// Base Configuration Register 3
    input logic we_bcfg3_i,  /// Base Configuration Register 3 Write Enable

    input logic [15:0] reg_cprm1_i,  /// Convolution Parameter Register 1
    input logic we_cprm1_i,  /// Convolution Parameter Register 1 Write Enable

    input logic [7:0] reg_stats_lower_i,  /// Stats Register, Lower 8 Bits (User Sets)
    input logic we_stats_lower_i,  /// Stats Register, Lower 8 Bits Write Enable (User Sets)

    input logic [7:0] reg_stats_upper_i,  /// Stats Register, Upper 8 Bits (User Sets)
    input logic we_stats_upper_i,  /// Stats Register, Upper 8 Bits Write Enable (User Sets)

    output logic [15:0] reg_versn_o,  /// Version Register
    output logic [15:0] reg_hwrid_o,  /// Hardware ID Register
    output logic [15:0] reg_memup_o,  /// Upper Memory Address Register
    output logic [15:0] reg_mstrt_o,  /// Memory Start Address Register
    output logic [15:0] reg_mendd_o,  /// Memory End Address Register
    output logic [15:0] reg_bcfg1_o,  /// Base Configuration Register 1
    output logic [15:0] reg_bcfg2_o,  /// Base Configuration Register 2
    output logic [15:0] reg_bcfg3_o,  /// Base Configuration Register 3
    output logic [15:0] reg_cprm1_o,  /// Convolution Parameter Register 1
    output logic [15:0] reg_stats_o   /// Stats Register
);

  assign reg_versn_o = RegVersnDefault;
  assign reg_hwrid_o = RegHwridDefault;

  core_d_ff #(
      .Bits(16),
      .ResetValue(RegMemupDefault)
  ) reg_memup_ff (
      .clk_i,
      .rst_i,
      .en_i  (we_memup_i),
      .data_i(reg_memup_i),
      .data_o(reg_memup_o)
  );

  core_d_ff #(
      .Bits(16),
      .ResetValue(RegMstrtDefault)
  ) reg_mstrt_ff (
      .clk_i,
      .rst_i,
      .en_i  (we_mstrt_i),
      .data_i(reg_mstrt_i),
      .data_o(reg_mstrt_o)
  );

  core_d_ff #(
      .Bits(16),
      .ResetValue(RegMenddDefault)
  ) reg_mendd_ff (
      .clk_i,
      .rst_i,
      .en_i  (we_mendd_i),
      .data_i(reg_mendd_i),
      .data_o(reg_mendd_o)
  );

  core_d_ff #(
      .Bits(16),
      .ResetValue(RegBcfg1Default)
  ) reg_bcfg1_ff (
      .clk_i,
      .rst_i,
      .en_i  (we_bcfg1_i),
      .data_i(reg_bcfg1_i),
      .data_o(reg_bcfg1_o)
  );

  core_d_ff #(
      .Bits(16),
      .ResetValue(RegBcfg2Default)
  ) reg_bcfg2_ff (
      .clk_i,
      .rst_i,
      .en_i  (we_bcfg2_i),
      .data_i(reg_bcfg2_i),
      .data_o(reg_bcfg2_o)
  );

  core_d_ff #(
      .Bits(16),
      .ResetValue(RegBcfg3Default)
  ) reg_bcfg3_ff (
      .clk_i,
      .rst_i,
      .en_i  (we_bcfg3_i),
      .data_i(reg_bcfg3_i),
      .data_o(reg_bcfg3_o)
  );

  core_d_ff #(
      .Bits(16),
      .ResetValue(RegCprm1Default)
  ) reg_cprm1_ff (
      .clk_i,
      .rst_i,
      .en_i  (we_cprm1_i),
      .data_i(reg_cprm1_i),
      .data_o(reg_cprm1_o)
  );

  core_d_ff #(
      .Bits(8),
      .ResetValue(RegStatsDefault[7:0])
  ) reg_stats_lower_ff (
      .clk_i,
      .rst_i,
      .en_i  (we_stats_lower_i),
      .data_i(reg_stats_lower_i),
      .data_o(reg_stats_o[7:0])
  );

  core_d_ff #(
      .Bits(8),
      .ResetValue(RegStatsDefault[15:8])
  ) reg_stats_upper_ff (
      .clk_i,
      .rst_i,
      .en_i  (we_stats_upper_i),
      .data_i(reg_stats_upper_i),
      .data_o(reg_stats_o[15:8])
  );

endmodule
