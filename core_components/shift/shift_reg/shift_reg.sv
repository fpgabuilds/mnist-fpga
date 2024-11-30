module shift_reg #(
    parameter unsigned N,  // Width of the data
    parameter unsigned Length  // Number of registers
) (
    input clk_i,  // clock
    input en_i,  // enable shift
    input rst_i,  //reset active low
    input [N-1:0] rst_val_i,  //reset value (Every register will be initialized with this value)
    input [N-1:0] data_i,  //data in
    output [N-1:0] data_o  //data out
);

  reg [N-1:0] store[Length-1:0];  //the register that holds the data

  generate
    genvar i;
    for (i = 0; i < Length; i = i + 1) begin : g_shiftblock
      always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) store[i] <= rst_val_i;
        else begin
          if(en_i) // If enable is active then shift
          begin
            if (i == 0) store[i] <= data_i;
            else store[i] <= store[i-1];
          end
        end
      end
    end
  endgenerate
  assign data_o = store[Length-1];
endmodule

