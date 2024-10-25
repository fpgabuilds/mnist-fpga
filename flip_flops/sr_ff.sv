module sr_ff #(
    parameter Width = 1
  ) (
    input logic clk_i,
    input logic rst_i,
    input logic en_i,
    input logic [Width-1:0] s,
    input logic r,
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
      if (r)
        data_o <= {Width{1'b0}};
      else if (s)
        data_o <= data_o | s;
    end
  end

endmodule

