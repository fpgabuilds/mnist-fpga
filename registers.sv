// Register: 0x01
// Direction: read
// Description: Version Register
// Initial Value: 0x0001
interface IVersion;
  logic [15:0] full_register;
  logic [5:0] major;
  logic [7:0] minor;
  logic [3:0] patch;

  modport read (output major, minor, patch);
  modport read_full (output full_register);

  assign major = full_register[15:11];
  assign minor = full_register[10:3];
  assign patch = full_register[2:0];
  assign full_register = 16'h0001;
endinterface

// Register: 0x01
// Direction: read/write
// Description: Ram Address Lower Register
// Initial Value: 0x0000
interface IRamAddrLow;
  logic [15:0] full_register;
  logic [15:0] address;

  modport read (output address);
  modport read_full (output full_register);
  modport write (input full_register);

  assign address = full_register;
endinterface

// Register: 0x02
// Direction: read/write
// Description: Ram Address Upper Register
// Initial Value: 0x0000
interface IRamAddrHigh;
  logic [15:0] full_register;
  logic [15:0] address;

  modport read (output address);
  modport read_full (output full_register);
  modport write (input full_register);

  assign address = full_register;
endinterface

// Register: 0x03
// Direction: read/write
// Description: Convolution Configuration Register 1
// Initial Value: 0x0401
interface IConvConfig1;
  logic [15:0] full_register;
  logic [5:0] stride;
  logic [9:0] engine_count;

  modport read (output stride, engine_count);
  modport read_full (output full_register);
  modport write (input full_register);

  assign stride = full_register[15:10];
  assign engine_count = full_register[9:0];
endinterface

// Register: 0x04
// Direction: read/write
// Description: Convolution Configuration Register 2
// Initial Value: 0x0000
interface IConvConfig2;
  logic [15:0] full_register;
  logic accumulate;
  logic save_to_ram;
  logic [13:0] matrix_size;

  modport read (output accumulate, save_to_ram, matrix_size);
  modport read_full (output full_register);
  modport write (input full_register);

  assign accumulate = full_register[15];
  assign save_to_ram = full_register[14];
  assign matrix_size = full_register[13:0];
endinterface

// Register: 0x05
// Direction: read/write
// Description: Convolution Configuration Register 3
// Initial Value: 0x0000
interface IConvConfig3;
  logic [15:0] full_register;
  logic [8:0] padding;
  logic padding_fill;
  logic [5:0] shift_amount;

  modport read (output padding, padding_fill, shift_amount);
  modport read_full (output full_register);
  modport write (input full_register);

  assign padding = full_register[15:7];
  assign padding_fill = full_register[6];
  assign shift_amount = full_register[5:0];
endinterface

// Register: 0x06
// Direction: read/write
// Description: Convolution Configuration Register 4
// Initial Value: 0x0000
interface IConvConfig4;
  logic [15:0] full_register;
  logic [3:0] activation_function;
  logic [11:0] activation_function_param;

  modport read (output activation_function, activation_function_param);
  modport read_full (output full_register);
  modport write (input full_register);

  assign activation_function = full_register[15:12];
  assign activation_function_param = full_register[11:0];
endinterface

// Register: 0x07
// Direction: read
// Description: Convolution Status Register
// Initial Value: 0x0000
interface IConvStatus;
  logic [15:0] full_register;
  logic done;
  logic running;
  logic [14:0] count;

  modport read (output done, running, count);
  modport read_full (output full_register);
  modport write (input done, running, count);

  assign full_register[15] = done;
  assign full_register[14] = running;
  assign full_register[13:0] = count;
endinterface

// Register: 0x08
// Direction: read/write  (On most)
// Description: Interrupt Enable and Active Register
// Initial Value: 0x0000
interface IInterrupt;
  logic [15:0] full_register;
  logic [15:0] write_enable_temp;
  logic mem_load_enable;
  logic mem_load_active; // Read only, clears on read
  logic conv_enable;
  logic conv_active; // Read only, clears on read
  logic dense_enable;
  logic dense_active; // Read only, clears on read

  modport read (output mem_load_enable, mem_load_active, conv_enable, dense_enable, dense_active);
  modport read_enable (output mem_load_enable, conv_enable, dense_enable);
  modport read_active (output mem_load_active, conv_active, dense_active);
  modport read_full (output full_register);
  modport write_enable (input write_enable_temp);
  modport write_active (input mem_load_active, conv_active, dense_active);

  // Allow user to write only to the enable bits
  assign mem_load_enable = write_enable_temp[15];
  assign conv_enable = write_enable_temp[13];
  assign dense_enable = write_enable_temp[11];

  assign full_register[15] = mem_load_enable;
  assign full_register[14] = mem_load_active;
  assign full_register[13] = conv_enable;
  assign full_register[12] = conv_active;
  assign full_register[11] = dense_enable;
  assign full_register[10] = dense_active;
  assign full_register[9:0] = 10'h000; // Reserved
endinterface



// Register: 0x0E
// Direction: write
// Description: Write to Memory Shift Register. Each write shifts
//              the data in the register into a 1 word buffer.
//              Can be written to ram with the start task.
// Initial Value: 0x0000
interface IWriteToMem;
  logic [15:0] full_register;
  logic [15:0] data;

  modport read (output data);
  modport read_full (output full_register); // Not to be accessed by the user
  modport write (input data);

  assign data = full_register;
endinterface

// Register: 0x0F
// Direction: read
// Description: Read from Memory Shift Register. Each read shifts
//              the data in the 1 word buffer into the register.
// Initial Value: 0x0000
interface IReadFromMem;
  logic [15:0] full_register;
  logic [15:0] data;

  modport read (output data);
  modport read_full (output full_register);
  modport write (input data); // Not to be accessed by the user

  assign data = full_register;
endinterface





