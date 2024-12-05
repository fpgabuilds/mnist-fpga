module activation_layer #(
    parameter unsigned Bits,
    parameter logic [11:0] EngineCount
) (
    input logic clk_i,
    input logic en_i,
    input logic [2:0] activation_function_i,

    input  wire signed  [Bits-1:0] value_i[EngineCount-1:0],
    output logic signed [Bits-1:0] value_o[EngineCount-1:0]
);
  localparam logic [2:0] ActivFBits_Bitsone = 0;
  localparam logic [2:0] ActivFBits_Relu = 1;

  logic signed [Bits-1:0] next_outputs_relu[EngineCount-1:0];

  generate
    genvar i;
    for (i = 0; i < EngineCount; i++) begin : g_activation
      activation_relu #(
          .Bits(Bits)
      ) relu_inst (
          .clk_i(clk_i),
          .en_i(en_i),
          .value_i(value_i[i]),
          .value_o(next_outputs_relu[i])
      );
    end
  endgenerate



  always_ff @(posedge clk_i) begin
    if (en_i) begin
      for (int i = 0; i < EngineCount; i = i + 1) begin
        case (activation_function_i)
          ActivFBits_Bitsone: value_o[i] <= value_i[i];
          ActivFBits_Relu: value_o[i] <= next_outputs_relu[i];
          default: value_o[i] <= value_i[i];
        endcase
      end
    end else for (int i = 0; i < EngineCount; i = i + 1) value_o[i] <= {Bits{1'b0}};
  end


endmodule
