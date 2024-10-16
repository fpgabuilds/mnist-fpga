module weight_writer #(
    parameter N = 10, // total bit width
    parameter Size = 8 // size of the weight matrix
  ) (
    input wire clk_i,
    input wire rst_ni,
    input wire write_en_i,
    input wire [$clog2(N)*8:0] data_i, // $clog2(N) bytes of data
    output wire loaded_o,
    output wire [N*Size*Size-1:0] weights_o
  );
  localparam RawBitsWidth = (N*Size*Size);
  localparam LoadCountWidth = $clog2((RawBitsWidth + 7)) + 1; // Required number of bits to load all the weights and some extra bits just in case



  reg [RawBitsWidth+6:0] raw_bytes; // 7 extra bits to ensure we have a full byte because $ceil doesn't work
  assign weights_o = raw_bytes[RawBitsWidth-1:0];

  wire [LoadCountWidth-1:0] load_count;
  assign loaded_o = (load_count >= RawBitsWidth);

  counter #(
            .Size(LoadCountWidth)
          ) load_counter ( // Counts bytes of the file
            .clk_i(clk_i),
            .en_i(write_en_i),
            .rst_ni(rst_ni),
            .start_val_i('b0),
            .end_val_i({LoadCountWidth{1'b1}}),
            .count_by_i({LoadCountWidth{1'b0}} + 4'd8),
            .count_o(load_count)
          );

  single_port_bram #(
                     .DataWidth(12),
                     .Depth(64)
                   ) weight_ram (
                     .clk_i(clk_i),
                     .write_en_i(1'b0),
                     .addr_i(),
                     .data_i(),
                     .data_o()
                   );


  always @ (posedge clk_i or negedge rst_ni)
  begin
    if (!rst_ni)
      raw_bytes <= {RawBitsWidth{1'b0}};
    else if (write_en_i)
      raw_bytes[load_count +: 8] <= data_i;
  end
endmodule


module weight_loader #(
    parameter N = 10, // total bit width
    parameter KernelSize = 8, // size of the weight matrix
    parameter AddrSize = 10 // size of the address (bits)
  ) (
    input wire clk_i,
    input wire load_en_i,
    input wire [AddrSize-1:0] data_pos_0_i,
    input wire update_i, // Update the weights and biases

    output reg [2*N*KernelSize*KernelSize-1:0] weights_o, // Contains both weights and biases
    output wire loaded_o,

    // RAM interface
    input wire [N-1:0] data_i,
    output wire [AddrSize-1:0] addr_o
  );
  localparam [AddrSize-1:0] MaxAddress = (2*N*KernelSize*KernelSize); // Maximum address that the current weights and bias are stored in

  reg [N-1:0] weights_new [2*KernelSize*KernelSize-1:0]; // Contains weights and biases being loaded from ram, not the current weights and biases
  //reg [2*N*KernelSize*KernelSize-1:0] weights_new; // Contains weights and biases being loaded from ram, not the current weights and biases

  wire [AddrSize-1:0] end_val = (data_pos_0_i + MaxAddress);

  increment_then_stop #(
                        .Bits(AddrSize)
                      ) load_counter ( // Counts bytes of the file
                        .clk_i(clk_i),
                        .run_i(load_en_i),
                        .rst_i(1'b0),
                        .start_val_i(data_pos_0_i),
                        .end_val_i(end_val),
                        .count_o(addr_o)
                      );


  always @ (posedge clk_i)
    weights_new[addr_o-data_pos_0_i] <= data_i;

  always @ (posedge clk_i)
    if (update_i)
    begin : update_weights
      integer i;
      for (i = 0; i < 2*KernelSize*KernelSize; i = i + 1)
      begin
        weights_o[i*N +: N] <= weights_new[i];
      end
    end

  assign loaded_o = (addr_o == end_val);
endmodule
