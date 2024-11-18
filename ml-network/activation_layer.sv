module activation_layer #(
    parameter N,
    parameter [11:0] EngineCount = 4095
  ) (
    input logic clk_i,
    input logic en_i,
    input logic [2:0] activation_function_i,

    input wire signed [N-1:0] value_i [EngineCount-1:0],
    output logic signed [N-1:0] value_o [EngineCount-1:0]
  );
  localparam ActivFN_None = 0;
  localparam ActivFN_Relu = 1;

  logic signed [N-1:0] next_outputs_relu [EngineCount-1:0];

  generate
    genvar i;
    for (i = 0; i < EngineCount; i++)
    begin : activation
      activation_relu #(
                        .N(N)
                      ) relu_inst (
                        .clk_i(clk_i),
                        .en_i(en_i),
                        .value_i(value_i[i]),
                        .value_o(next_outputs_relu[i])
                      );
    end
  endgenerate



  always_ff @(posedge clk_i)
  begin
    if (en_i)
    begin
      for (int i = 0; i < EngineCount; i = i + 1)
      begin
        case (activation_function_i)
          ActivFN_None:
            value_o[i] <= value_i[i];
          ActivFN_Relu:
            value_o[i] <= next_outputs_relu[i];
          default:
            value_o[i] <= value_i[i];
        endcase
      end
    end
    else
      for (int i = 0; i < EngineCount; i = i + 1)
        value_o[i] <= {N{1'b0}};
  end


endmodule

module activation_relu #(
    parameter N = 16
  ) (
    input logic clk_i,
    input logic en_i,
    input logic signed [N-1:0] value_i,
    output logic signed [N-1:0] value_o
  );

  always_comb
  begin
    value_o = (value_i > 0) ? value_i : 0;
  end
endmodule
