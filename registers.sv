// Register: 0x1
// Direction: read
// Description: Version Register
interface IVersn #(
    parameter logic [15:0] ResetValue = 16'h0000
  );
  logic [15:0] register_o;

  logic [7:0] chip_id_o;
  logic [4:0] major_o;
  logic [2:0] minor_o;

  modport read (output chip_id_o, major_o, minor_o);
  modport read_full (output register_o);

  assign register_o = ResetValue;

  assign chip_id = register_o[15:8];
  assign major = register_o[7:3];
  assign minor = register_o[2:0];

endinterface

// Register: 0x1
// Direction: read
// Description: Hardware ID Register
interface IHwrid #(
    parameter logic [15:0] ResetValue = 16'h0000
  );
  logic [15:0] register_o;

  logic [15:0] uid_o;

  modport read (output uid_o);
  modport read_full (output register_o);

  assign register_o = ResetValue;

  assign uid = register_o;
endinterface

// Register: 0x2
// Description: Memory Upper Register
interface IMemup #(
    parameter logic [15:0] ResetValue = 16'h0000
  );
  logic clk_i;
  logic rst_i;

  logic [15:0] register_i;
  logic we_i;

  logic [15:0] register_o;

  logic [15:0] mem_upper_o;

  modport read (output mem_upper_o);
  modport read_full (output register_o);
  modport write_ext (input register_o, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  d_ff_rst #(
             .Width(16)
           ) memup_ff (
             .clk_i,
             .rst_i,
             .en_i(we_i),
             .rst_val_i(ResetValue),
             .data_i(register_i),
             .data_o(register_o)
           );

  assign mem_upper_o = register_o;
endinterface

// Register: 0x3
// Description: Start Memory Address Register
interface IMstrt #(
    parameter logic [15:0] ResetValue = 16'h0000
  );
  logic clk_i;
  logic rst_i;

  logic [15:0] register_i;
  logic we_i;

  logic [15:0] register_o;

  logic [15:0] mem_start_o;

  modport read (output mem_start_o);
  modport read_full (output register_o);
  modport write_ext (input register_o, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  d_ff_rst #(
             .Width(16)
           ) mstrt_ff (
             .clk_i,
             .rst_i,
             .en_i(we_i),
             .rst_val_i(ResetValue),
             .data_i(register_i),
             .data_o(register_o)
           );

  assign mem_start_o = register_o;
endinterface

// Register: 0x4
// Description: End Memory Address Register
interface IMendd #(
    parameter logic [15:0] ResetValue = 16'h0000
  );
  logic clk_i;
  logic rst_i;

  logic [15:0] register_i;
  logic we_i;

  logic [15:0] register_o;

  logic [15:0] mem_end_o;

  modport read (output mem_end_o);
  modport read_full (output register_o);
  modport write_ext (input register_o, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  d_ff_rst #(
             .Width(16)
           ) mendd_ff (
             .clk_i,
             .rst_i,
             .en_i(we_i),
             .rst_val_i(ResetValue),
             .data_i(register_i),
             .data_o(register_o)
           );

  assign mem_end_o = register_o;
endinterface

// Register: 0x5
// Description: Base Config 1 Register
interface IBcfg1 #(
    parameter logic [15:0] ResetValue = 16'h0000
  );
  logic clk_i;
  logic rst_i;

  logic [15:0] register_i;
  logic we_i;

  logic [15:0] register_o;

  logic [3:0] shift_low_o;
  logic [11:0] engine_count_o;

  modport read (output shift_low_o, engine_count_o);
  modport read_full (output register_o);
  modport write_ext (input register_i, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  d_ff_rst #(
             .Width(16)
           ) bcfg1_ff (
             .clk_i,
             .rst_i,
             .en_i(we_i),
             .rst_val_i(ResetValue),
             .data_i(register_i),
             .data_o(register_o)
           );

  assign shift_low_o = register_o[15:12];
  assign engine_count_o = register_o[11:0];
endinterface

// Register: 0x6
// Description: Base Config 2 Register
interface IBcfg2 #(
    parameter logic [15:0] ResetValue = 16'h0000
  );
  logic clk_i;
  logic rst_i;

  logic [15:0] register_i;
  logic we_i;

  logic [15:0] register_o;

  logic [1:0] shift_high_o;
  logic [13:0] matrix_size_o;

  modport read (output shift_high_o, matrix_size_o);
  modport read_full (output register_o);
  modport write_ext (input register_i, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  d_ff_rst #(
             .Width(16)
           ) bcfg2_ff (
             .clk_i,
             .rst_i,
             .en_i(we_i),
             .rst_val_i(ResetValue),
             .data_i(register_i),
             .data_o(register_o)
           );

  assign shift_high_o = register_o[15:14];
  assign matrix_size_o = register_o[13:0];
endinterface

// Register: 0x7
// Description: Base Config 3 Register
interface IBcfg3 #(
    parameter logic [15:0] ResetValue = 16'h0000
  );
  logic clk_i;
  logic rst_i;

  logic [15:0] register_i;
  logic we_i;

  logic [15:0] register_o;

  logic [15:14] load_from_o;

  modport read (output load_from_o);
  modport read_full (output register_o);
  modport write_ext (input register_i, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  assign register_o[13:0] = ResetValue[13:0];
  d_ff_rst #(
             .Width(2)
           ) bcfg3_ff (
             .clk_i,
             .rst_i,
             .en_i(we_i),
             .rst_val_i(ResetValue[15:14]),
             .data_i(register_i[15:14]),
             .data_o(register_o[15:14])
           );

  assign load_from_o = register_o[15:14];
endinterface

// Register: 0x8
// Description: Conv Run Param 1 Register
interface ICprm1 #(
    parameter logic [15:0] ResetValue = 16'h0000
  );
  logic clk_i;
  logic rst_i;

  logic [15:0] register_i;
  logic we_i;

  logic [15:0] register_o;

  logic [2:0] padding_o;
  logic padding_fill_o;
  logic [5:0] stride_o;
  logic [1:0] activation_function_o;
  logic activation_fn_enable_o;
  logic accumulate_o;
  logic save_to_ram_o;
  logic save_to_buffer_o;

  modport read (output padding_o, padding_fill_o, stride_o, activation_function_o, activation_fn_enable_o, accumulate_o, save_to_ram_o, save_to_buffer_o);
  modport read_full (output register_o);
  modport write_ext (input register_o, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  d_ff_rst #(
             .Width(16)
           ) cprm1_ff (
             .clk_i,
             .rst_i,
             .en_i(we_i),
             .rst_val_i(ResetValue),
             .data_i(register_i),
             .data_o(register_o)
           );

  assign padding_o = register_o[15:13];
  assign padding_fill_o = register_o[12];
  assign stride_o = register_o[11:6];
  assign activation_function_o = register_o[5:4];
  assign activation_fn_enable_o = register_o[3];
  assign accumulate_o = register_o[2];
  assign save_to_ram_o = register_o[1];
  assign save_to_buffer_o = register_o[0];
endinterface



// Register: 0x9
// Description: Device Status Register and Interrupt
interface IStats #(
    parameter logic [15:0] ResetValue = 16'h0000
  );
  logic clk_i;
  logic rst_i;

  logic [15:0] register_i;
  logic we_i;
  logic we_int_i;
  logic we_int2_i;

  logic conv_done_i;
  logic conv_running_i;
  logic dense_done_i;
  logic dense_running_i;
  logic [4:0] error_code_i;

  logic conv_intrr_ac_i;
  logic dense_intrr_ac_i;
  logic error_intrr_ac_i;

  logic [15:0] register_o;

  logic conv_done_o;
  logic conv_running_o;
  logic conv_intrr_en_o;
  logic conv_intrr_ac_o;
  logic dense_done_o;
  logic dense_running_o;
  logic dense_intrr_en_o;
  logic dense_intrr_ac_o;
  logic error_intrr_ac_o;
  logic error_intrr_en_o;
  logic [4:0] error_code_o;

  modport read (output conv_done_o, conv_running_o, conv_intrr_en_o, dense_done_o, dense_running_o, dense_intrr_en_o, error_intrr_en_o, error_code_o);
  modport read_full (output register_o);
  modport write_int (input conv_done_i, conv_running_i, dense_done_i, dense_running_i, error_code_i, we_int_i);
  modport write_int2 (input conv_intrr_ac_i, dense_intrr_ac_i, error_intrr_ac_i, we_int2_i);
  modport write_ext (input register_i, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  assign register_o[5] = ResetValue[5];
  d_ff_rst #(
             .Width(9)
           ) bcfg1_ff (
             .clk_i,
             .rst_i,
             .en_i(we_i),
             .rst_val_i({ResetValue[15], ResetValue[14], ResetValue[11], ResetValue[10], ResetValue[4:0]}),
             .data_i({conv_done_i, conv_running_i, dense_done_i, dense_running_i, error_code_i}),
             .data_o({conv_done_o, conv_running_o, dense_done_o, dense_running_o, error_code_o})
           );

  d_ff_rst #(
             .Width(3)
           ) stats_int2_ff (
             .clk_i,
             .rst_i,
             .en_i(we_int2_i),
             .rst_val_i({ResetValue[12], ResetValue[8], ResetValue[7]}),
             .data_i({conv_intrr_ac_i, dense_intrr_ac_i, error_intrr_ac_i}),
             .data_o({conv_intrr_ac_o, dense_intrr_ac_o, error_intrr_ac_o})
           );

  d_ff_rst #(
             .Width(3)
           ) stats_ff (
             .clk_i,
             .rst_i,
             .en_i(we_i),
             .rst_val_i({ResetValue[13], ResetValue[9], ResetValue[6]}),
             .data_i({register_i[13], register_i[9], register_i[6]}),
             .data_o({conv_intrr_en_o, dense_intrr_en_o, error_intrr_en_o})
           );

  assign conv_done_o = register_o[15];
  assign conv_running_o = register_o[14];
  assign conv_intrr_en_o = register_o[13];
  assign conv_intrr_ac_o = register_o[12];
  assign dense_done_o = register_o[11];
  assign dense_running_o = register_o[10];
  assign dense_intrr_en_o = register_o[9];
  assign dense_intrr_ac_o = register_o[8];
  assign error_intrr_ac_o = register_o[7];
  assign error_intrr_en_o = register_o[6];
  assign error_code_o = register_o[4:0];
endinterface




