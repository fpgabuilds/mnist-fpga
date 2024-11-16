module d_delay #(
    parameter Delay // In clock cycles
  ) (
    input logic clk_i,
    input logic rst_i,
    input logic en_i,
    input logic data_i,
    output logic data_o
  );
  logic store [Delay-1:0];

  always @(posedge clk_i)
  begin
    if (Delay == 0)
      assert (en_i) else
               $error("Can not have enable on a zero delay");
  end

  generate
    if (Delay == 0)
      assign data_o = data_i;
    else
    begin
      genvar i;
      for(i = 0; i < Delay; i = i + 1)
      begin: delayblock
        always_ff @(posedge clk_i or posedge rst_i)
        begin
          if(rst_i)
            store[i] <= 1'b0;
          else
          begin
            if(en_i)
            begin
              if(i == 0)
                store[i] <= data_i;
              else
                store[i] <= store[i-1];
            end
          end
        end
      end
      assign data_o = store[Delay-1];
    end
  endgenerate
endmodule


// d_delay_mult #(
//                  .Bits(),
//                  .Delay()
//                ) _inst (
//                  .clk_i,
//                  .rst_i,
//                  .en_i,
//                  .data_i,
//                  .data_o()
//                );
module d_delay_mult #(
    parameter Bits,
    parameter Delay // In clock cycles
  ) (
    input logic clk_i,
    input logic rst_i,
    input logic en_i,
    input logic [Bits-1:0] data_i,
    output logic [Bits-1:0] data_o
  );
  logic [Bits-1:0] store [Delay-1:0];

  always @(posedge clk_i)
  begin
    if (Delay == 0)
      assert (en_i) else
               $error("Can not have enable on a zero delay");
  end

  generate
    if (Delay == 0)
      assign data_o = data_i;
    else
    begin
      genvar i;
      for(i = 0; i < Delay; i = i + 1)
      begin: delayblock
        always_ff @(posedge clk_i or posedge rst_i)
        begin
          if(rst_i)
            store[i] <= {Bits{1'b0}};
          else
          begin
            if(en_i)
            begin
              if(i == 0)
                store[i] <= data_i;
              else
                store[i] <= store[i-1];
            end
          end
        end
      end
      assign data_o = store[Delay-1];
    end
  endgenerate
endmodule
