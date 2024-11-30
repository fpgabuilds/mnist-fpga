// D flip-flop with asynchronous reset and enable
module d_ff (
    input  logic clk_i,
    input  logic rst_i,
    input  logic en_i,
    input  logic data_i,
    output logic data_o
);

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      data_o <= 1'b0;
    end else if (en_i) begin
      data_o <= data_i;
    end
  end
endmodule

// D flip-flop with synchronous reset and enable
module d_ff_srst #(
    /// Bit width of the data, default is 1
    parameter unsigned Bits = 1
) (
    input  logic clk_i,
    input  logic srst_i,
    input  logic en_i,
    input  logic data_i,
    output logic data_o
);

  always_ff @(posedge clk_i) begin
    if (srst_i) begin
      data_o <= {Bits{1'b0}};
    end else if (en_i) begin
      data_o <= data_i;
    end
  end
endmodule


// d_ff_mult #(
//             .Bits()
//           ) _inst (
//             .clk_i,
//             .rst_i,
//             .en_i,
//             .data_i,
//             .data_o()
//           );

// D flip-flop with asynchronous reset and enable
module d_ff_mult #(
    parameter unsigned Bits
) (
    input logic clk_i,
    input logic rst_i,
    input logic en_i,
    input logic [Bits-1:0] data_i,
    output logic [Bits-1:0] data_o
);

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      data_o <= {Bits{1'b0}};
    end else if (en_i) begin
      data_o <= data_i;
    end
  end
endmodule
