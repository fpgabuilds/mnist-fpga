module sim_ddr_64_bit #(
    parameter ReadLatency = 16
  ) (
    input logic clk_i,
    input logic [31:0] addr_i,
    input logic [63:0] data_i,
    input logic write_en_i,
    input logic read_en_i,
    input logic [7:0] byte_en_i,
    output logic [63:0] data_o,
    output logic data_valid_o
  );

  always @(posedge clk_i)
  begin
    assert(addr_i[2:0] == 3'b000) else
            $error("Unaligned access detected at address %h, align with start of word", addr_i);
  end

  localparam RamSize = 32'h00000FF; // 512MB per BRAM (4GB total)

  logic [64:0] bram_data_reg;
  logic [64:0] bram_data_shifted;
  logic [28:0] bram_addr;

  assign bram_addr = addr_i[31:3];

  shift_reg #(
              .N(65),
              .Length(ReadLatency)
            ) read_shift_reg_inst (
              .clk_i(clk_i),
              .en_i(1'b1),
              .rst_i(1'b0),
              .rst_val_i(65'h0),
              .data_i(read_en_i ? bram_data_reg : 65'h0),
              .data_o(bram_data_shifted)
            );

  genvar i;
  generate
    for (i = 0; i < 8; i++)
    begin : bram_inst
      dual_port_bram #(
                       .DataWidth(8),
                       .Depth(RamSize)
                     ) ram (
                       .clk_i(clk_i),
                       .a_write_en_i(write_en_i & byte_en_i[i]),
                       .a_addr_i(bram_addr),
                       .a_data_i(data_i[8*i +: 8]),
                       .a_data_o(),
                       .b_write_en_i(1'b0),
                       .b_addr_i(bram_addr),
                       .b_data_i(8'b0),
                       .b_data_o(bram_data_reg[8*i +: 8])
                     );
    end
  endgenerate

  assign bram_data_reg[64] = 1'b1; // Data valid signal, always high because we pass zero into shift reg when not reading

  assign data_o = bram_data_shifted[63:0];
  assign data_valid_o = bram_data_shifted[64];

endmodule
