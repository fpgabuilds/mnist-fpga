// D flip-flop with asynchronous reset and enable
module d_ff (
    input logic clk_i,
    input logic rst_i,
    input logic en_i,
    input logic data_i,
    output logic data_o
  );

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      data_o <= 1'b0;
    end
    else if (en_i)
    begin
      data_o <= data_i;
    end
  end
endmodule

// // D flip-flop with synchronous reset and enable
module d_ff_srst #(
    parameter Width = 1
  ) (
    input logic clk_i,
    input logic srst_i,
    input logic en_i,
    input logic data_i,
    output logic data_o
  );

  always_ff @(posedge clk_i)
  begin
    if (srst_i)
    begin
      data_o <= {Width{1'b0}};
    end
    else if (en_i)
    begin
      data_o <= data_i;
    end
  end
endmodule



// D flip-flop with asynchronous reset and enable
module d_ff_mult #(
    parameter Width = 1
  ) (
    input logic clk_i,
    input logic rst_i,
    input logic en_i,
    input logic [Width-1:0] data_i,
    output logic [Width-1:0] data_o
  );

  always_ff @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      data_o <= {Width{1'b0}};
    end
    else if (en_i)
    begin
      data_o <= data_i;
    end
  end
endmodule
