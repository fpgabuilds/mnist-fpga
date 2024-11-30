module parallel_to_serial #(
    parameter unsigned N,  // Width of the data
    parameter unsigned Length  // Number of registers
) (
    input logic clk_i,  // clock
    input logic run_i,
    input logic en_i,  // enable shift
    input logic srst_i,
    input wire [N-1:0] store_i[Length-1:0],  //the reset register for every data
    input logic [$clog2(Length+1)-1:0] shift_count_i,  //the number of shift
    output logic [N-1:0] data_o,  //data out
    output logic running_o,
    output logic done_o,  // last data, clk, then done
    input logic assert_on_i
);
  logic [N-1:0] store[Length-1:0];
  localparam unsigned CountSize = $clog2(Length + 1);

  generate
    genvar i;
    for (i = 0; i < Length; i = i + 1) begin : g_shiftblock
      d_ff_mult #(
          .Width(N)
      ) store_registers_inst (
          .clk_i,
          .rst_i (1'b0),
          .en_i  (srst_i),
          .data_i(store_i[i]),
          .data_o(store[i])
      );
    end
  endgenerate

  logic running;

  sr_ff running_delay_inst (
      .clk_i,
      .rst_i (1'b0),
      .set_i (run_i),
      .srst_i,
      .data_o(running),
      .assert_on_i
  );

  assign running_o = running && !done_o;


  logic [CountSize-1:0] position_count;

  increment_then_stop_srts #(
      .Bits(CountSize)
  ) output_position_count (
      .clk_i,
      .en_i(en_i && running),
      .srst_i,
      .start_val_i({{{CountSize - 1} {1'b0}}, {1'b1}}),
      .end_val_i(shift_count_i),
      .count_o(position_count),
      .assert_on_i
  );

  logic shift_buffer;
  d_ff_srst shift_buffer_inst (  // Technically this a delay
      .clk_i,
      .srst_i,
      .en_i  (1'b1),
      .data_i(shift_count_i),
      .data_o(shift_buffer)
  );


  d_ff_srst done_inst (  // Technically this a delay
      .clk_i,
      .srst_i,
      .en_i  (1'b1),
      .data_i((position_count == shift_buffer)),
      .data_o(done_o)
  );
  assign data_o = store[position_count-1];
endmodule

