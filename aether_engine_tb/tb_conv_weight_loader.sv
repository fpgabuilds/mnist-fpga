module tb_conv_weight_loader ();
  // First 4 bits
  localparam NOP = 4'b0000;
  localparam RESET = 4'b0001;
  localparam WRITE_REG = 4'b0010;
  localparam READ_REG = 4'b0011;
  localparam START_TASK = 4'b0100;

  // Next 4 bits (instruction task)
  localparam LOAD_CONV_WEIGHTS = 4'b0000;
  localparam LOAD_CONV_DATA = 4'b0001;
  localparam START_CONV = 4'b0010;
  localparam LOAD_DENSE_WEIGHTS = 4'b0011;
  localparam LOAD_DENSE_DATA = 4'b0100;
  localparam START_DENSE = 4'b0101;
  localparam WRITE_TO_MEM = 4'b0110;
  localparam READ_FROM_MEM = 4'b0111;

  // Instruction reset
  localparam RST_ALL = 4'b0000;
  localparam RST_CONV = 4'b0001;
  localparam RST_CONV_WEIGHTS = 4'b0010;
  localparam TASK_RAM = 4'b0011;


  logic clk;
  logic [23:0] cmd;

  aether_engine #(
                  .DataWidth(8),
                  .MaxMatrixSize(4),
                  .KernelSize(3),
                  .ConvEngineCount(8)
                ) dut (
                  .clk_i(clk),

                  .cmd_i(cmd),
                  .data_o(),

                  .buffer_full_o(),
                  .interrupt_o()
                );

  // Clock generation
  always #5 clk = ~clk;

  // Define a task to execute a command on the positive edge of the clock
  task execute_cmd(input [23:0] command);
    @(posedge clk);
    cmd = command;
  endtask

  logic [23:0] commands[] = '{
          {RESET, RST_ALL, 16'b0},                // Reset Everything
          {START_TASK, WRITE_TO_MEM, 16'd0},      // Write to memory 0
          {START_TASK, WRITE_TO_MEM, 16'd8},      // Write to memory 1
          {START_TASK, WRITE_TO_MEM, 16'd16},      // Write to memory 2
          {START_TASK, WRITE_TO_MEM, 16'd24},      // Write to memory 3
          {START_TASK, WRITE_TO_MEM, 16'd32},      // Write to memory 4
          {START_TASK, WRITE_TO_MEM, 16'd40},      // Write to memory 5
          {START_TASK, WRITE_TO_MEM, 16'd48},      // Write to memory 6
          {START_TASK, WRITE_TO_MEM, 16'd56},      // Write to memory 7
          {START_TASK, WRITE_TO_MEM, 16'd64},      // Write to memory 8
          {START_TASK, LOAD_CONV_WEIGHTS, 16'd0}, // Load Convolution Weights Addr: 0
          {START_TASK, LOAD_CONV_WEIGHTS, 16'd8}, // Load Convolution Weights Addr: 1
          {START_TASK, LOAD_CONV_WEIGHTS, 16'd16}, // Load Convolution Weights Addr: 2
          {START_TASK, LOAD_CONV_WEIGHTS, 16'd24}, // Load Convolution Weights Addr: 3
          {START_TASK, LOAD_CONV_WEIGHTS, 16'd32}, // Load Convolution Weights Addr: 4
          {START_TASK, LOAD_CONV_WEIGHTS, 16'd40}, // Load Convolution Weights Addr: 5
          {START_TASK, LOAD_CONV_WEIGHTS, 16'd48}, // Load Convolution Weights Addr: 6
          {START_TASK, LOAD_CONV_WEIGHTS, 16'd56}, // Load Convolution Weights Addr: 7
          {START_TASK, LOAD_CONV_WEIGHTS, 16'd64}  // Load Convolution Weights Addr: 8
        };

  initial
  begin
    clk = 1'b0;
    cmd = 24'b0;



    // Execute all commands in the array
    foreach (commands[i])
    begin
      begin
        execute_cmd(commands[i]);
      end
    end
  end
endmodule
