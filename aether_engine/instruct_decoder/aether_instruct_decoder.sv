module aether_instruct_decoder (
    input logic clk_i,

    // Control Signals
    input logic [3:0] instruction_i,  /// instruction input
    input logic [3:0] param_1_i,  /// parameter 1 input
    input logic [15:0] param_2_i,  /// parameter 2 input
    output logic [15:0] data_o,  /// data output

    input logic [7:0] reg_stats_i,  /// register stats input for device status
    input logic we_reg_stats_i,  /// write enable register stats input

    // Register Variables
    output logic [15:0] reg_versn_o,  /// version register
    output logic [15:0] reg_hwrid_o,  /// hardware ID register
    output logic [15:0] reg_memup_o,  /// upper memory address register
    output logic [15:0] reg_mstrt_o,  /// memory start address register
    output logic [15:0] reg_mendd_o,  /// memory end address register
    output logic [15:0] reg_bcfg1_o,  /// base configuration register 1
    output logic [15:0] reg_bcfg2_o,  /// base configuration register 2
    output logic [15:0] reg_bcfg3_o,  /// base configuration register 3
    output logic [15:0] reg_cprm1_o,  /// convolution parameters register 1
    output logic [15:0] reg_stats_o,  /// device status register

    // Reset Variables
    output logic rst_cwgt_o,  /// reset convolution weights
    output logic rst_conv_o,  /// reset convolution
    output logic rst_dwgt_o,  /// reset dense weights
    output logic rst_dens_o,  /// reset dense
    output logic rst_full_o,  /// reset all

    // Load Weights Variables
    output logic ldw_cwgt_o,  /// load convolution weights
    output logic ldw_dwgt_o,  /// load dense weights
    output logic ldw_strt_o,  /// start loading weights
    output logic ldw_cont_o,  /// continue loading weights
    output logic ldw_move_o,  /// move weights

    // Convolution Variables
    output logic cnv_run_o,
    output logic [19:0] cnv_save_addr_o,

    // Dense Variables
    output logic dns_run_o,
    output logic [19:0] dns_save_addr_o,

    // Load Input Data Variables
    output logic lip_strt_o,
    output logic lip_cont_o,

    // Memory Variables
    output logic [1:0] mem_command_o
);
  `include "../constants/aether_constants.sv"
  import aether_registers::*;

  //------------------------------------------------------------------------------------
  // Setup Register FFs
  //------------------------------------------------------------------------------------

  logic rst_regs_o;  /// reset all registers
  logic we_memup;  /// write enable memory upper address
  logic we_mstrt;  /// write enable memory start address
  logic we_mendd;  /// write enable memory end address
  logic we_bcfg1;  /// write enable base configuration 1
  logic we_bcfg2;  /// write enable base configuration 2
  logic we_bcfg3;  /// write enable base configuration 3
  logic we_cprm1;  /// write enable convolution parameters 1
  logic we_stats_upper;  /// write enable stats upper

  logic [15:0] temp_reg_memup;  /// temporary memory upper address for user input
  logic [15:0] temp_reg_mstrt;  /// temporary memory start address for user input
  logic [15:0] temp_reg_mendd;  /// temporary memory end address for user input
  logic [15:0] temp_reg_bcfg1;  /// temporary base configuration 1 for user input
  logic [15:0] temp_reg_bcfg2;  /// temporary base configuration 2 for user input
  logic [15:0] temp_reg_bcfg3;  /// temporary base configuration 3 for user input
  logic [15:0] temp_reg_cprm1;  /// temporary convolution parameters 1 for user input
  logic [7:0] temp_reg_stats_upper;  /// temporary stats upper for user input

  aether_register_ff #(
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
  ) registers (
      .clk_i,
      .rst_i(rst_regs_o),

      .reg_memup_i(temp_reg_memup),
      .we_memup_i(we_memup),
      .reg_mstrt_i(temp_reg_mstrt),
      .we_mstrt_i(we_mstrt),
      .reg_mendd_i(temp_reg_mendd),
      .we_mendd_i(we_mendd),
      .reg_bcfg1_i(temp_reg_bcfg1),
      .we_bcfg1_i(we_bcfg1),
      .reg_bcfg2_i(temp_reg_bcfg2),
      .we_bcfg2_i(we_bcfg2),
      .reg_bcfg3_i(temp_reg_bcfg3),
      .we_bcfg3_i(we_bcfg3),
      .reg_cprm1_i(temp_reg_cprm1),
      .we_cprm1_i(we_cprm1),
      .reg_stats_lower_i(reg_stats_i),
      .we_stats_lower_i(we_reg_stats_i),
      .reg_stats_upper_i(temp_reg_stats_upper),
      .we_stats_upper_i(we_stats_upper),

      .reg_versn_o,
      .reg_hwrid_o,
      .reg_memup_o,
      .reg_mstrt_o,
      .reg_mendd_o,
      .reg_bcfg1_o,
      .reg_bcfg2_o,
      .reg_bcfg3_o,
      .reg_cprm1_o,
      .reg_stats_o
  );



  //------------------------------------------------------------------------------------
  // No Operation Instruction
  //------------------------------------------------------------------------------------

  // This is a NOP instruction, do nothing


  //------------------------------------------------------------------------------------
  // Reset Instruction Instruction
  //------------------------------------------------------------------------------------

  always_comb begin : reset_instruction
    rst_cwgt_o = 1'b0;
    rst_conv_o = 1'b0;
    rst_dwgt_o = 1'b0;
    rst_dens_o = 1'b0;
    rst_regs_o = 1'b0;
    rst_full_o = 1'b0;

    if (instruction_i == RST) begin
      case (param_1_i)
        RST_FULL: begin
          rst_cwgt_o = 1'b1;
          rst_conv_o = 1'b1;
          rst_dwgt_o = 1'b1;
          rst_dens_o = 1'b1;
          rst_regs_o = 1'b1;
          rst_full_o = 1'b1;
        end
        RST_CWGT: rst_cwgt_o = 1'b1;
        RST_CONV: rst_conv_o = 1'b1;
        RST_DWGT: rst_dwgt_o = 1'b1;
        RST_DENS: rst_dens_o = 1'b1;
        RST_REGS: rst_regs_o = 1'b1;
        default: begin
          $error("Invalid reset command, consider using full reset instead");
          rst_cwgt_o = 1'b1;
          rst_conv_o = 1'b1;
          rst_dwgt_o = 1'b1;
          rst_dens_o = 1'b1;
          rst_regs_o = 1'b1;
          rst_full_o = 1'b1;
        end
      endcase
    end
  end


  //------------------------------------------------------------------------------------
  // Read Register Instruction
  //------------------------------------------------------------------------------------

  always_comb begin : read_instruction
    data_o = reg_stats_o;

    if (instruction_i == RDR) begin
      case (param_1_i)
        REG_VERSN: data_o = reg_versn_o;
        REG_HWRID: data_o = reg_hwrid_o;
        REG_MEMUP: data_o = reg_memup_o;
        REG_MSTRT: data_o = reg_mstrt_o;
        REG_MENDD: data_o = reg_mendd_o;
        REG_BCFG1: data_o = reg_bcfg1_o;
        REG_BCFG2: data_o = reg_bcfg2_o;
        REG_BCFG3: data_o = reg_bcfg3_o;
        REG_CPRM1: data_o = reg_cprm1_o;
        REG_STATS: begin
          data_o = reg_stats_o;
          //  reg_stats_i.read_full_i = 1'b1; // TODO: Fix this
        end
        default:   $error("Invalid register read of register {%h}", param_1_i);
      endcase
    end
  end

  //------------------------------------------------------------------------------------
  // Write Register Instruction
  //------------------------------------------------------------------------------------

  always_comb begin : write_instruction
    we_memup = 1'b0;
    we_mstrt = 1'b0;
    we_mendd = 1'b0;
    we_bcfg1 = 1'b0;
    we_bcfg2 = 1'b0;
    we_bcfg3 = 1'b0;
    we_cprm1 = 1'b0;
    we_stats_upper = 1'b0;

    temp_reg_memup = 16'h0000;
    temp_reg_mstrt = 16'h0000;
    temp_reg_mendd = 16'h0000;
    temp_reg_bcfg1 = 16'h0000;
    temp_reg_bcfg2 = 16'h0000;
    temp_reg_bcfg3 = 16'h0000;
    temp_reg_cprm1 = 16'h0000;
    temp_reg_stats_upper = 8'h00;

    if (instruction_i == WRR) begin
      case (param_1_i)
        REG_VERSN: $error("Cannot write to version register");
        REG_HWRID: $error("Cannot write to hardware ID register");
        REG_MEMUP: begin
          temp_reg_memup = param_2_i;
          we_memup = 1'b1;
        end
        REG_MSTRT: begin
          temp_reg_mstrt = param_2_i;
          we_mstrt = 1'b1;
        end
        REG_MENDD: begin
          temp_reg_mendd = param_2_i;
          we_mendd = 1'b1;
        end
        REG_BCFG1: begin
          temp_reg_bcfg1 = param_2_i;
          we_bcfg1 = 1'b1;
        end
        REG_BCFG2: begin
          temp_reg_bcfg2 = param_2_i;
          we_bcfg2 = 1'b1;
        end
        REG_BCFG3: begin
          temp_reg_bcfg3 = param_2_i;
          we_bcfg3 = 1'b1;
        end
        REG_CPRM1: begin
          temp_reg_cprm1 = param_2_i;
          we_cprm1 = 1'b1;
        end
        REG_STATS: begin
          temp_reg_stats_upper = param_2_i[15:8];
          we_stats_upper = 1'b1;
        end
        default:   $error("Invalid register write of register {%h}", param_1_i);
      endcase
    end
  end

  //------------------------------------------------------------------------------------
  // Load Weights Instruction
  //------------------------------------------------------------------------------------
  logic ldw_mem_read;
  logic ldw_mem_write;

  always_comb begin : load_weights_instruction
    ldw_cwgt_o = 1'b0;
    ldw_dwgt_o = 1'b0;
    ldw_strt_o = 1'b0;
    ldw_cont_o = 1'b0;
    ldw_move_o = 1'b0;
    ldw_mem_read = 1'b0;
    ldw_mem_write = 1'b0;

    if (instruction_i == LDW) begin
      case (param_1_i)
        LDW_CWGT: begin
          ldw_cwgt_o   = 1'b1;
          ldw_mem_read = 1'b1;
        end
        LDW_DWGT: begin
          ldw_dwgt_o   = 1'b1;
          ldw_mem_read = 1'b1;
        end
        LDW_STRT: begin
          ldw_strt_o = 1'b1;
        end
        LDW_CONT: begin
          ldw_cont_o = 1'b1;
        end
        LDW_MOVE: begin
          ldw_mem_write = 1'b1;
          ldw_move_o = 1'b1;
        end
        default: begin
          $error("Invalid task command on LDW");
        end
      endcase
    end
  end



  //------------------------------------------------------------------------------------
  // Convolve Instruction
  //------------------------------------------------------------------------------------

  always_comb begin : convolve_instruction
    cnv_run_o = 1'b0;
    cnv_save_addr_o = 20'h0;

    if (instruction_i == CNV) begin
      cnv_run_o = 1'b1;
      cnv_save_addr_o = {param_1_i, param_2_i};
    end
  end


  //------------------------------------------------------------------------------------
  // Dense Instruction
  //------------------------------------------------------------------------------------

  always_comb begin : dense_instruction
    dns_run_o = 1'b0;
    dns_save_addr_o = 20'h0;

    if (instruction_i == DNS) begin
      if (param_1_i == 4'h0) begin
        dns_run_o = 1'b1;
        dns_save_addr_o = {param_1_i, param_2_i};
      end
    end
  end


  //------------------------------------------------------------------------------------
  // Load Input Data Instruction
  //------------------------------------------------------------------------------------

  always_comb begin : load_input_data_instruction
    lip_strt_o = 1'b0;
    lip_cont_o = 1'b0;

    if (instruction_i == LIP) begin
      case (param_1_i)
        LIP_STRT: lip_strt_o = 1'b1;
        LIP_CONT: lip_cont_o = 1'b1;
        default: begin
          $error("Invalid task command on LIP");
        end
      endcase
    end
  end


  //------------------------------------------------------------------------------------
  // Memory Management
  //------------------------------------------------------------------------------------

  localparam logic [1:0] MEM_IDLE = 2'b00;
  localparam logic [1:0] MEM_WRITE = 2'b01;
  localparam logic [1:0] MEM_READ = 2'b10;

  always_comb begin : memory_management
    if (ldw_mem_write || (instruction_i == CNV && Crpm1SaveToRam(
            reg_cprm1_o
        )) || instruction_i == DNS)
      mem_command_o = MEM_WRITE;
    else if (ldw_mem_read) mem_command_o = MEM_READ;
    else mem_command_o = MEM_IDLE;
  end
endmodule
