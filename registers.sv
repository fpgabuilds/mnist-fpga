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

  assign chip_id_o = register_o[15:8];
  assign major_o = register_o[7:3];
  assign minor_o = register_o[2:0];

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

  assign uid_o = register_o;
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
  modport write_ext (input register_i, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      register_o <= ResetValue;
    end
    else if (we_i)
    begin
      register_o <= register_i;
    end
  end

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
  modport write_ext (input register_i, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      register_o <= ResetValue;
    end
    else if (we_i)
    begin
      register_o <= register_i;
    end
  end

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
  modport write_ext (input register_i, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      register_o <= ResetValue;
    end
    else if (we_i)
    begin
      register_o <= register_i;
    end
  end

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

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      register_o <= ResetValue;
    end
    else if (we_i)
    begin
      register_o <= register_i;
    end
  end

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

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      register_o <= ResetValue;
    end
    else if (we_i)
    begin
      register_o <= register_i;
    end
  end

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
  logic [13:8] shift_final_o;

  modport read (output load_from_o, shift_final_o);
  modport read_full (output register_o);
  modport write_ext (input register_i, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  assign register_o[7:0] = ResetValue[7:0];

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      register_o[15:8] <= ResetValue[15:8];
    end
    else if (we_i)
    begin
      register_o[15:8] <= register_i[15:8];
    end
  end

  assign load_from_o = register_o[15:14];
  assign shift_final_o = register_o[13:8];
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
  logic [2:0] activation_function_o;
  logic accumulate_o;
  logic save_to_ram_o;
  logic save_to_buffer_o;

  modport read (output padding_o, padding_fill_o, stride_o, activation_function_o, accumulate_o, save_to_ram_o, save_to_buffer_o);
  modport read_full (output register_o);
  modport write_ext (input register_i, we_i);
  modport reg_ctrl (input clk_i, rst_i);

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      register_o <= ResetValue;
    end
    else if (we_i)
    begin
      register_o <= register_i;
    end
  end

  assign padding_o = register_o[15:13];
  assign padding_fill_o = register_o[12];
  assign stride_o = register_o[11:6];
  assign activation_function_o = register_o[5:3];
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

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      {conv_done_o, conv_running_o, dense_done_o, dense_running_o, error_code_o} <= {ResetValue[15], ResetValue[14], ResetValue[11], ResetValue[10], ResetValue[4:0]};
    end
    else if (we_int_i)
    begin
      {conv_done_o, conv_running_o, dense_done_o, dense_running_o, error_code_o} <= {conv_done_i, conv_running_i, dense_done_i, dense_running_i, error_code_i};
    end
  end


  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      {conv_intrr_ac_o, dense_intrr_ac_o, error_intrr_ac_o} <= {ResetValue[12], ResetValue[8], ResetValue[7]};
    end
    else if (we_int2_i)
    begin
      {conv_intrr_ac_o, dense_intrr_ac_o, error_intrr_ac_o} <= {conv_intrr_ac_i, dense_intrr_ac_i, error_intrr_ac_i};
    end
  end

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      {conv_intrr_en_o, dense_intrr_en_o, error_intrr_en_o} <= {ResetValue[13], ResetValue[9], ResetValue[6]};
    end
    else if (we_i)
    begin
      {conv_intrr_en_o, dense_intrr_en_o, error_intrr_en_o} <= {register_i[13], register_i[9], register_i[6]};
    end
  end

  assign register_o[15] = conv_done_o;
  assign register_o[14] = conv_running_o;
  assign register_o[13] = conv_intrr_en_o;
  assign register_o[12] = conv_intrr_ac_o;
  assign register_o[11] = dense_done_o;
  assign register_o[10] = dense_running_o;
  assign register_o[9] = dense_intrr_en_o;
  assign register_o[8] = dense_intrr_ac_o;
  assign register_o[7] = error_intrr_ac_o;
  assign register_o[6] = error_intrr_en_o;
  assign register_o[4:0] = error_code_o;
endinterface




