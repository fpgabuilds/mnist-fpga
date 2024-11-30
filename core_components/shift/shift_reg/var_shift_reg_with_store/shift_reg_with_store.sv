module shift_reg_with_store #(
    parameter unsigned N = 8,  // Width of the data
    parameter unsigned Length = 3  // Number of registers
) (
    input logic clk_i,  // clock
    input logic en_i,  // enable shift
    input logic rst_i,  //reset
    input logic [N-1:0] rst_val_i, //reset value (Every register will be initialized with this value)
    input logic [N-1:0] data_i,  //data in
    output logic [N-1:0] data_o,  //data out
    output logic [N-1:0] store_o[Length-1:0]  //the register that holds the data
);

  generate
    genvar i;
    for (i = 0; i < Length; i = i + 1) begin : g_shiftblock
      always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) store_o[i] <= rst_val_i;
        else begin
          if(en_i) // If enable is active then shift
          begin
            if (i == 0) store_o[i] <= data_i;
            else store_o[i] <= store_o[i-1];
          end
        end
      end
    end
  endgenerate
  assign data_o = store_o[Length-1];
endmodule
