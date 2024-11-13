module aether_engine_decoder (
    input logic clk_i,

    // Control Signals
    input logic [3:0] instruction_i, // instruction input
    input logic [3:0] param_1_i, // parameter 1 input
    input logic [15:0] param_2_i, // parameter 2 input
    output logic [15:0] data_o, // data output

    // Register Variables
    IVersn.read_full reg_versn_i,
    IHwrid.read_full reg_hwrid_i,
    IMemup.read_full reg_memup_i,
    IMstrt.read_full reg_mstrt_i,
    IMendd.read_full reg_mendd_i,
    IBcfg1.read_full reg_bcfg1_i,
    IBcfg2.read_full reg_bcfg2_i,
    IBcfg3.read_full reg_bcfg3_i,
    ICprm1.read_full reg_cprm1_i,
    ICprm1.read reg_cprm1_ind_i,
    IStats.read_full reg_stats_i,

    IMemup.write_ext reg_memup_o,
    IMstrt.write_ext reg_mstrt_o,
    IMendd.write_ext reg_mendd_o,
    IBcfg1.write_ext reg_bcfg1_o,
    IBcfg2.write_ext reg_bcfg2_o,
    IBcfg3.write_ext reg_bcfg3_o,
    ICprm1.write_ext reg_cprm1_o,
    IStats.write_ext reg_stats_o,


    // Reset Variables
    output logic rst_cwgt_o,
    output logic rst_conv_o,
    output logic rst_dwgt_o,
    output logic rst_dens_o,
    output logic rst_regs_o,
    output logic rst_full_o,

    // Load Weights Variables
    output logic ldw_cwgt_o,
    output logic ldw_dwgt_o,
    output logic ldw_strt_o,
    output logic ldw_cont_o,
    output logic ldw_move_o,

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

`include "aether_constants.sv"

  //------------------------------------------------------------------------------------
  // No Operation Instruction
  //------------------------------------------------------------------------------------

  // This is a NOP instruction, do nothing


  //------------------------------------------------------------------------------------
  // Reset Instruction Instruction
  //------------------------------------------------------------------------------------

  always_comb
  begin
    rst_cwgt_o = 1'b0;
    rst_conv_o = 1'b0;
    rst_dwgt_o = 1'b0;
    rst_dens_o = 1'b0;
    rst_regs_o = 1'b0;
    rst_full_o = 1'b0;

    if (instruction_i == RST)
    begin
      case (param_1_i)
        RST_FULL:
        begin
          rst_cwgt_o = 1'b1;
          rst_conv_o = 1'b1;
          rst_dwgt_o = 1'b1;
          rst_dens_o = 1'b1;
          rst_regs_o = 1'b1;
          rst_full_o = 1'b1;
        end
        RST_CWGT:
          rst_cwgt_o = 1'b1;
        RST_CONV:
          rst_conv_o = 1'b1;
        RST_DWGT:
          rst_dwgt_o = 1'b1;
        RST_DENS:
          rst_dens_o = 1'b1;
        RST_REGS:
          rst_regs_o = 1'b1;
        default:
        begin
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
  // Read Reset Instruction
  //------------------------------------------------------------------------------------

  always_comb
  begin
    data_o = reg_stats_i.register_o;
    reg_stats_i.read_full_i = 1'b0; // Clear interrupts on read

    if (instruction_i == RDR)
    begin
      case (param_1_i)
        REG_VERSN:
          data_o = reg_versn_i.register_o;
        REG_HWRID:
          data_o = reg_hwrid_i.register_o;
        REG_MEMUP:
          data_o = reg_memup_i.register_o;
        REG_MSTRT:
          data_o = reg_mstrt_i.register_o;
        REG_MENDD:
          data_o = reg_mendd_i.register_o;
        REG_BCFG1:
          data_o = reg_bcfg1_i.register_o;
        REG_BCFG2:
          data_o = reg_bcfg2_i.register_o;
        REG_BCFG3:
          data_o = reg_bcfg3_i.register_o;
        REG_CPRM1:
          data_o = reg_cprm1_i.register_o;
        REG_STATS:
        begin
          data_o = reg_stats_i.register_o;
          reg_stats_i.read_full_i = 1'b1;
        end
        default:
          $error("Invalid register read of register {%h}", param_1_i);
      endcase
    end
  end

  //------------------------------------------------------------------------------------
  // Write Register Instruction
  //------------------------------------------------------------------------------------
  always_comb
  begin
    reg_memup_o.register_i = 16'h0000;
    reg_memup_o.we_i = 1'b0;
    reg_mstrt_o.register_i = 16'h0000;
    reg_mstrt_o.we_i = 1'b0;
    reg_mendd_o.register_i = 16'h0000;
    reg_mendd_o.we_i = 1'b0;
    reg_bcfg1_o.register_i = 16'h0000;
    reg_bcfg1_o.we_i = 1'b0;
    reg_bcfg2_o.register_i = 16'h0000;
    reg_bcfg2_o.we_i = 1'b0;
    reg_bcfg3_o.register_i = 16'h0000;
    reg_bcfg3_o.we_i = 1'b0;
    reg_cprm1_o.register_i = 16'h0000;
    reg_cprm1_o.we_i = 1'b0;
    reg_stats_o.register_i = 16'h0000;
    reg_stats_o.we_i = 1'b0;


    if (instruction_i == WRR)
    begin
      case (param_1_i)
        REG_VERSN:
          $error("Cannot write to version register");
        REG_HWRID:
          $error("Cannot write to hardware ID register");
        REG_MEMUP:
        begin
          reg_memup_o.register_i = param_2_i;
          reg_memup_o.we_i = 1'b1;
        end
        REG_MSTRT:
        begin
          reg_mstrt_o.register_i = param_2_i;
          reg_mstrt_o.we_i = 1'b1;
        end
        REG_MENDD:
        begin
          reg_mendd_o.register_i = param_2_i;
          reg_mendd_o.we_i = 1'b1;
        end
        REG_BCFG1:
        begin
          reg_bcfg1_o.register_i = param_2_i;
          reg_bcfg1_o.we_i = 1'b1;
        end
        REG_BCFG2:
        begin
          reg_bcfg2_o.register_i = param_2_i;
          reg_bcfg2_o.we_i = 1'b1;
        end
        REG_BCFG3:
        begin
          reg_bcfg3_o.register_i = param_2_i;
          reg_bcfg3_o.we_i = 1'b1;
        end
        REG_CPRM1:
        begin
          reg_cprm1_o.register_i = param_2_i;
          reg_cprm1_o.we_i = 1'b1;
        end
        REG_STATS:
        begin
          reg_stats_o.register_i = param_2_i;
          reg_stats_o.we_i = 1'b1;
        end
        default:
          $error("Invalid register write of register {%h}", param_1_i);
      endcase
    end
  end

  //------------------------------------------------------------------------------------
  // Load Weights Instruction
  //------------------------------------------------------------------------------------
  logic ldw_mem_read;
  logic ldw_mem_write;

  always_comb
  begin
    ldw_cwgt_o = 1'b0;
    ldw_dwgt_o = 1'b0;
    ldw_strt_o = 1'b0;
    ldw_cont_o = 1'b0;
    ldw_move_o = 1'b0;
    ldw_mem_read = 1'b0;
    ldw_mem_write = 1'b0;

    if (instruction_i == LDW)
    begin
      case (param_1_i)
        LDW_CWGT:
        begin
          ldw_cwgt_o = 1'b1;
          ldw_mem_read = 1'b1;
        end
        LDW_DWGT:
        begin
          ldw_dwgt_o = 1'b1;
          ldw_mem_read = 1'b1;
        end
        LDW_STRT:
        begin
          ldw_strt_o = 1'b1;
        end
        LDW_CONT:
        begin
          ldw_cont_o = 1'b1;
        end
        LDW_MOVE:
        begin
          ldw_mem_write = 1'b1;
          ldw_move_o = 1'b1;
        end
        default:
        begin
          $error("Invalid task command on LDW");
        end
      endcase
    end
  end



  //------------------------------------------------------------------------------------
  // Convolve Instruction
  //------------------------------------------------------------------------------------

  always_comb
  begin
    cnv_run_o = 1'b0;
    cnv_save_addr_o = 20'h0;

    if (instruction_i == CNV)
    begin
      cnv_run_o = 1'b1;
      cnv_save_addr_o = {param_1_i, param_2_i};
    end
  end


  //------------------------------------------------------------------------------------
  // Dense Instruction
  //------------------------------------------------------------------------------------

  always_comb
  begin
    dns_run_o = 1'b0;
    dns_save_addr_o = 20'h0;

    if (instruction_i == DNS)
    begin
      if (param_1_i == 4'h0)
      begin
        dns_run_o = 1'b1;
        dns_save_addr_o = {param_1_i, param_2_i};
      end
    end
  end


  //------------------------------------------------------------------------------------
  // Load Input Data Instruction
  //------------------------------------------------------------------------------------

  always_comb
  begin
    lip_strt_o = 1'b0;
    lip_cont_o = 1'b0;

    if (instruction_i == LIP)
    begin
      case (param_1_i)
        LIP_STRT:
          lip_strt_o = 1'b1;
        LIP_CONT:
          lip_cont_o = 1'b1;
        default:
        begin
          $error("Invalid task command on LIP");
        end
      endcase
    end
  end


  //------------------------------------------------------------------------------------
  // Memory Management
  //------------------------------------------------------------------------------------

  localparam MEM_IDLE = 2'b00;
  localparam MEM_WRITE = 2'b01;
  localparam MEM_READ = 2'b10;

  always_comb
  begin
    if (ldw_mem_write || (instruction_i == CNV && reg_cprm1_ind_i.save_to_ram_o) || instruction_i == DNS)
      mem_command_o = MEM_WRITE;
    else if (ldw_mem_read)
      mem_command_o = MEM_READ;
    else
      mem_command_o = MEM_IDLE;
  end
endmodule
