module shift_reg_with_store #(
    parameter N = 8, // Width of the data
    parameter Length = 3 // Number of registers
  ) (
    input logic clk_i, // clock
    input logic en_i, // enable shift
    input logic rst_i, //reset
    input logic [N-1:0] rst_val_i, //reset value (Every register will be initialized with this value)
    input logic [N-1:0] data_i, //data in
    output logic [N-1:0] data_o, //data out
    output logic [N-1:0] store_o [Length-1:0] //the register that holds the data
  );

  generate
    genvar i;
    for(i = 0; i < Length; i = i + 1)
    begin: shiftblock
      always_ff @(posedge clk_i or posedge rst_i)
      begin
        if(rst_i)
          store_o[i] <= rst_val_i;
        else
        begin
          if(en_i) // If enable is active then shift
          begin
            if(i == 0)
              store_o[i] <= data_i;
            else
              store_o[i] <= store_o[i-1];
          end
        end
      end
    end
  endgenerate
  assign data_o = store_o[Length-1];
endmodule

module parallel_to_serial #(
    parameter N = 8, // Width of the data
    parameter Length = 3 // Number of registers
  ) (
    input logic clk_i, // clock
    input logic en_i, // enable shift
    input logic rst_i,
    input wire [N-1:0] store_i [Length-1:0], //the reset register for every data
    input logic [$clog2(Length+1)-1:0] shift_count_i, //the number of shift
    output logic [N-1:0] data_o, //data out
    output logic done_o // last data, clk, then done
  );
  logic [N-1:0] store [Length-1:0];
  localparam CountSize = $clog2(Length+1);

  generate
    genvar i;
    for(i = 0; i < Length; i = i + 1)
    begin: shiftblock
      d_ff #(
             .Width(N)
           ) store_registers_inst (
             .clk_i,
             .rst_i(1'b0),
             .en_i(rst_i),
             .data_i(store_i[i]),
             .data_o(store[i])
           );
    end
  endgenerate

  logic [CountSize-1:0] position_count;

  increment_then_stop #(
                        .Bits(CountSize) // Number of bits in the counter, this can be found using $clog2(N+1) where N is the maximum value of the counter
                      ) output_position_count (
                        .clk_i, // Clock input
                        .en_i, // Run signal, when high the counter will increment, when low the counter will not change but will hold the current value
                        .rst_i, // Reset signal, when low the counter will be reset to the start value. Not tied to the clock
                        .start_val_i({CountSize{1'b0}}), // The value the counter will be set to when rst_i is high
                        .end_val_i(shift_count_i), // The value the counter will stop at
                        .count_o(position_count), // The current value of the counter, will start at start_val_i and increment until end_val_i
                        .assert_on_i(1'b1)
                      );

  d_ff #(
         .Width(1)
       ) done_inst (
         .clk_i,
         .rst_i(1'b0),
         .en_i(1'b1),
         .data_i(position_count == shift_count_i),
         .data_o(done_o)
       );
  assign data_o = store[position_count];
endmodule

