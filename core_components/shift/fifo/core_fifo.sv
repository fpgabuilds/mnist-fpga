module core_fifo #(
    parameter unsigned InputBits,
    parameter unsigned OutputBits,
    parameter unsigned Depth
) (
    input logic clk_i,
    input logic rst_i,
    input logic write_en_i,
    input logic read_en_i,
    input logic [InputBits-1:0] data_i,
    output logic [OutputBits-1:0] data_o,
    output logic full_o,
    output logic empty_o
);

  // Local parameters
  localparam unsigned AddrBits = $clog2(Depth + 1);
  localparam unsigned Ratio = InputBits / OutputBits;
  localparam unsigned RatioBits = $clog2(Ratio + 1);

  // Internal signals
  logic [InputBits-1:0] store[Depth-1:0];

  logic [AddrBits-1:0] write_ptr, read_ptr;
  logic [ AddrBits-1:0] count;
  logic [RatioBits-1:0] out_offset;

  // Write operation
  always_ff @(posedge clk_i or posedge rst_i) begin : fifo_write
    if (rst_i) begin
      write_ptr <= {AddrBits{1'b0}};
    end else if (write_en_i && !full_o) begin
      store[write_ptr] <= data_i;
      write_ptr <= write_ptr + 1'b1;
    end
  end

  // Read operation
  always_ff @(posedge clk_i or posedge rst_i) begin : fifo_read
    if (rst_i) begin
      read_ptr   <= {AddrBits{1'b0}};
      out_offset <= {RatioBits{1'b0}};
    end else if (read_en_i && !empty_o) begin
      data_o <= store[read_ptr][OutputBits*out_offset+:OutputBits];
      if (out_offset == Ratio - 1) begin
        read_ptr   <= read_ptr + 1'b1;
        out_offset <= {RatioBits{1'b0}};
      end else begin
        out_offset <= out_offset + 1'b1;
      end
    end
  end

  // FIFO count logic
  always_ff @(posedge clk_i or posedge rst_i) begin : fifo_count
    if (rst_i) begin
      count <= {AddrBits{1'b0}};
    end else begin
      case ({
        write_en_i & ~full_o, read_en_i & ~empty_o
      })
        2'b10:   count <= count + 1'b1;
        2'b01:   count <= count - 1'b1;
        default: count <= count;
      endcase
    end
  end

  // Full and empty flags
  assign full_o  = (count == Depth);
  assign empty_o = (count == 0);

endmodule
