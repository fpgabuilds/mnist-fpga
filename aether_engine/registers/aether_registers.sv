package aether_registers;
  //------------------------------------------------------------------------------------
  // Register: 0x1
  // Description: Version Register
  //------------------------------------------------------------------------------------
  function automatic logic [7:0] VersnChipId(input logic [15:0] register);
    return register[15:8];
  endfunction

  function automatic logic [4:0] VersnMajor(input logic [15:0] register);
    return register[7:3];
  endfunction

  function automatic logic [2:0] VersnMinor(input logic [15:0] register);
    return register[2:0];
  endfunction


  //------------------------------------------------------------------------------------
  // Register: 0x5
  // Description: Base Config 1 Register
  //------------------------------------------------------------------------------------
  function automatic logic [3:0] Bcfg1ShiftLow(input logic [15:0] register);
    return register[15:12];
  endfunction

  function automatic logic [11:0] Bcfg1EngineCount(input logic [15:0] register);
    return register[11:0];
  endfunction


  //------------------------------------------------------------------------------------
  // Register: 0x6
  // Description: Base Config 2 Register
  //------------------------------------------------------------------------------------
  function automatic logic [1:0] Bcfg2ShiftHigh(input logic [15:0] register);
    return register[15:14];
  endfunction

  function automatic logic [13:0] Bcfg2MatrixSize(input logic [15:0] register);
    return register[13:0];
  endfunction


  //------------------------------------------------------------------------------------
  // Register: 0x7
  // Description: Base Config 3 Register
  //------------------------------------------------------------------------------------
  function automatic logic [1:0] Bcfg3LoadFrom(input logic [15:0] register);
    return register[15:14];
  endfunction


  //------------------------------------------------------------------------------------
  // Register: 0x8
  // Description: Conv Run Param 1 Register
  //------------------------------------------------------------------------------------
  function automatic logic [2:0] Crpm1Padding(input logic [15:0] register);
    return register[15:13];
  endfunction

  function automatic logic Crpm1PaddingFill(input logic [15:0] register);
    return register[12];
  endfunction

  function automatic logic [5:0] Crpm1Stride(input logic [15:0] register);
    return register[11:6];
  endfunction

  function automatic logic [2:0] Crpm1ActivationFunction(input logic [15:0] register);
    return register[5:3];
  endfunction

  function automatic logic Crpm1Accumulate(input logic [15:0] register);
    return register[2];
  endfunction

  function automatic logic Crpm1SaveToRam(input logic [15:0] register);
    return register[1];
  endfunction

  function automatic logic Crpm1SaveToBuffer(input logic [15:0] register);
    return register[0];
  endfunction

endpackage




