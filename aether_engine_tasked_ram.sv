module aether_engine_tasked_ram (
    input logic clk_i,
    input logic rst_i,
    input logic [31:0] addr_i,

    // Read
    input read_en_i,
    input [3:0] task_i,
    output [63:0] data_o,
    output [3:0] task_o,
    output data_valid_o,

    // Write
    input [63:0] data_i,
    input write_en_i,
    input [7:0] byte_en_i
  );

  sim_ddr_64_bit #(
                   .ReadLatency(16)
                 ) ram_inst (
                   .clk_i,
                   .addr_i(addr_i),
                   .data_i,
                   .write_en_i,
                   .read_en_i,
                   .byte_en_i,
                   .data_o,
                   .data_valid_o
                 );

  fifo #(
         .InputWidth(4),
         .OutputWidth(4),
         .Depth(20) // Needs to be higher than the latency of the DDR
       ) fifo_inst (
         .clk_i,
         .rst_i,
         .write_en_i(read_en_i),
         .read_en_i(data_valid_o),
         .data_i(task_i),
         .data_o(task_o),
         .full_o(),
         .empty_o()
       );

endmodule
