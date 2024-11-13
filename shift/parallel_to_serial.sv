module parallel_to_serial #(
    parameter N = 8, // Width of the data
    parameter Length = 3 // Number of registers
  ) (
    input logic clk_i, // clock
    input logic run_i,
    input logic en_i, // enable shift
    input logic srst_i,
    input wire [N-1:0] store_i [Length-1:0], //the reset register for every data
    input logic [$clog2(Length+1)-1:0] shift_count_i, //the number of shift
    output logic [N-1:0] data_o, //data out
    output logic running_o,
    output logic done_o, // last data, clk, then done
    input logic assert_on_i
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
             .en_i(srst_i),
             .data_i(store_i[i]),
             .data_o(store[i])
           );
    end
  endgenerate

  logic running;

  d_ff_srst #(
              .Width(1)
            ) running_delay_inst (
              .clk_i,
              .srst_i,
              .en_i(run_i),
              .data_i(1'b1),
              .data_o(running)
            );

  assign running_o = running && !done_o;


  logic [CountSize-1:0] position_count;

  increment_then_stop_srts #(
                             .Bits(CountSize) // Number of bits in the counter, this can be found using $clog2(N+1) where N is the maximum value of the counter
                           ) output_position_count (
                             .clk_i, // Clock input
                             .en_i(en_i && running), // Run signal, when high the counter will increment, when low the counter will not change but will hold the current value
                             .srst_i, // Reset signal, when low the counter will be reset to the start value. tied to the clock
                             .start_val_i({{{CountSize-1}{1'b0}}, {1'b1}}), // The value the counter will be set to when rst_i is high
                             .end_val_i(shift_count_i), // The value the counter will stop at
                             .count_o(position_count), // The current value of the counter, will start at start_val_i and increment until end_val_i
                             .assert_on_i
                           );

  logic shift_buffer;
  d_ff_srst #(
              .Width(1)
            ) shift_buffer_inst (
              .clk_i,
              .srst_i,
              .en_i(1'b1),
              .data_i(shift_count_i),
              .data_o(shift_buffer)
            );

  d_ff_srst #(
              .Width(1)
            ) done_inst (
              .clk_i,
              .srst_i,
              .en_i(1'b1),
              .data_i((position_count == shift_buffer)),
              .data_o(done_o)
            );
  assign data_o = store[position_count - 1];
endmodule

