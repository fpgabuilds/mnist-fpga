module aether_engine_decoder (
    input logic clk_i,

    // Control Signals
    input logic [23:0] cmd_i, // command input
    output logic [15:0] data_o, // data output

    // Register Variables
    IVersion version,
    IRamAddrLow ram_addr_low,
    IRamAddrHigh ram_addr_high,

    IConvConfig1 conv_config_1,
    IConvConfig2 conv_config_2,
    IConvConfig3 conv_config_3,
    IConvConfig4 conv_config_4,

    IConvStatus conv_status,

    IWriteToMem write_to_mem,
    IReadFromMem read_from_mem,


    // Reset Variables
    output logic rst_cwgt_o,
    output logic rst_conv_o,
    output logic rst_dwgt_o,
    output logic rst_dens_o,

    // Load Weights Variables
    output logic ldw_cwgt_o,
    output logic ldw_dwgt_o,

    // Convolution Variables
    output logic cnv_run_o,
    output logic [3:0] cnv_count_o,

    // Dense Variables
    output logic dns_run_o,
    output logic [3:0] dns_count_o,

    // Memory Variables
    output logic [31:0] mem_addr_start_o,
    output logic mem_load_enable_o
  );

  //------------------------------------------------------------------------------------
  // Instruction Definitions
  //------------------------------------------------------------------------------------
  localparam INST_NOP = 4'd0; // No Operation
  localparam INST_RST = 4'd1; // Reset
  localparam INST_RDR = 4'd2; // Read Register
  localparam INST_WRR = 4'd3; // Write Register
  localparam INST_LDW = 4'd4; // Load Weights
  localparam INST_CNV = 4'd5; // Run Convolution
  localparam INST_DNS = 4'd6; // Run Dense Layer


  //------------------------------------------------------------------------------------
  // Split Input Commands
  //------------------------------------------------------------------------------------

  logic [3:0] instruction;
  logic [3:0] param_1;
  logic [15:0] param_2;

  assign instruction = cmd_i[23:20];
  assign param_1 = cmd_i[19:16];
  assign param_2 = cmd_i[15:0];


  //------------------------------------------------------------------------------------
  // No Operation Instruction
  //------------------------------------------------------------------------------------

  // This is a NOP instruction, do nothing


  //------------------------------------------------------------------------------------
  // Reset Instruction Instruction
  //------------------------------------------------------------------------------------
  localparam RST_FULL = 4'd0;
  localparam RST_CWGT = 4'd1;
  localparam RST_CONV = 4'd2;
  localparam RST_DWGT = 4'd3;
  localparam RST_DENS = 4'd4;

  always_comb
  begin
    rst_cwgt_o = 1'b0;
    rst_conv_o = 1'b0;
    rst_dwgt_o = 1'b0;
    rst_dens_o = 1'b0;

    if (instruction == INST_RST)
    begin
      case (param_1)
        RST_FULL:
        begin
          rst_cwgt_o = 1'b1;
          rst_conv_o = 1'b1;
          rst_dwgt_o = 1'b1;
          rst_dens_o = 1'b1;
        end
        RST_CWGT:
          rst_cwgt_o = 1'b1;
        RST_CONV:
          rst_conv_o = 1'b1;
        RST_DWGT:
          rst_dwgt_o = 1'b1;
        RST_DENS:
          rst_dens_o = 1'b1;
        default:
        begin
          $error("Invalid reset command, consider using full reset instead");
          rst_cwgt_o = 1'b1;
          rst_conv_o = 1'b1;
          rst_dwgt_o = 1'b1;
          rst_dens_o = 1'b1;
        end
      endcase
    end
  end


  //------------------------------------------------------------------------------------
  // Read Reset Instruction
  //------------------------------------------------------------------------------------
  always_comb
  begin
    data_o = 16'h0000;

    if (instruction == INST_RDR)
    begin
      case (param_1)
        4'h0 :
          data_o = version.full_register;
        4'h1 :
          data_o = ram_addr_low.full_register;
        4'h2 :
          data_o = ram_addr_high.full_register;
        4'h3 :
          data_o = conv_config_1.full_register;
        4'h4 :
          data_o = conv_config_2.full_register;
        4'h5 :
          data_o = conv_config_3.full_register;
        4'h6 :
          data_o = conv_config_4.full_register;
        4'h7 :
          data_o = conv_status.full_register;
        4'hE :
          $error("Cannot read from write to memory register");
        4'hF :
          data_o = read_from_mem.full_register; // TODO: implement shifting into the register
        default:
          $error("Invalid register read");
      endcase
    end
  end

  //------------------------------------------------------------------------------------
  // Write Register Instruction
  //------------------------------------------------------------------------------------
  always_comb
  begin
    if (instruction == INST_WRR)
    begin
      case (param_1)
        4'h0 :
          $error("Cannot write to version register");
        4'h1 :
          ram_addr_low.full_register = param_2;
        4'h2 :
          ram_addr_high.full_register = param_2;
        4'h3 :
          conv_config_1.full_register = param_2;
        4'h4 :
          conv_config_2.full_register = param_2;
        4'h5 :
          conv_config_3.full_register = param_2;
        4'h6 :
          conv_config_4.full_register = param_2;
        4'h7 :
          $error("Cannot write to status register");
        4'hE :
          write_to_mem.full_register = param_2;
        4'hF :
          $error("Cannot write to read from memory register");
        default:
          $error("Invalid register write");
      endcase
    end
  end

  //------------------------------------------------------------------------------------
  // Load Weights Instruction
  //------------------------------------------------------------------------------------
  localparam LDW_CWGT = 4'd1; // Load Convolution Weights
  localparam LDW_DWGT = 4'd2; // Load Dense Weights

  // ram_addr_high.full_register;


  always_comb
  begin
    ldw_cwgt_o = 1'b0;
    ldw_dwgt_o = 1'b0;

    if (instruction == INST_LDW)
    begin
      case (param_1)
        LDW_CWGT:
          ldw_cwgt_o = 1'b1;
        LDW_DWGT:
          ldw_dwgt_o = 1'b1;
        default:
        begin
          $error("Invalid task command");
          ldw_cwgt_o = 1'b0;
          ldw_dwgt_o = 1'b0;
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
    cnv_count_o = 4'h0;

    if (instruction == INST_CNV)
    begin
      if (param_1 == 4'h0)
      begin
        $error("Invalid convolution count, must be greater than 0. Preforming a nop instead");
      end
      else
      begin
        cnv_run_o = 1'b1;
        cnv_count_o = param_1;
      end
    end
  end

  //------------------------------------------------------------------------------------
  // Dense Instruction
  //------------------------------------------------------------------------------------

  always_comb
  begin
    dns_run_o = 1'b0;
    dns_count_o = 4'h0;

    if (instruction == INST_DNS)
    begin
      if (param_1 == 4'h0)
      begin
        $error("Invalid dense count, must be greater than 0. Preforming a nop instead");
      end
      else
      begin
        dns_run_o = 1'b1;
        dns_count_o = param_1;
      end
    end
  end


  //------------------------------------------------------------------------------------
  // Memory Management
  //------------------------------------------------------------------------------------

  assign mem_load_enable_o = (instruction == INST_LDW || instruction == INST_CNV || instruction == INST_DNS);
  assign mem_addr_start_o = mem_load_enable_o? {{ram_addr_high.full_register},{param_2}} : 32'h0000;

endmodule
