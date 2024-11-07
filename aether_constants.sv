// Instructions

localparam [3:0] NOP = 4'h0;
localparam [3:0] RST = 4'h1;
localparam [3:0] RDR = 4'h2;
localparam [3:0] WRR = 4'h3;
localparam [3:0] LDW = 4'h4;
localparam [3:0] CNV = 4'h5;
localparam [3:0] DNS = 4'h6;
localparam [3:0] LIP = 4'h7;
localparam [3:0] ROP = 4'h8;
// localparam [3:0]  = 4'h9;
// localparam [3:0]  = 4'hA;
// localparam [3:0]  = 4'hB;
// localparam [3:0]  = 4'hC;
// localparam [3:0]  = 4'hD;
// localparam [3:0]  = 4'hE;
// localparam [3:0]  = 4'hF;


// RST Parameters
localparam [3:0] RST_FULL = 4'h0;
localparam [3:0] RST_CWGT = 4'h1;
localparam [3:0] RST_CONV = 4'h2;
localparam [3:0] RST_DWGT = 4'h3;
localparam [3:0] RST_DENS = 4'h4;
localparam [3:0] RST_REGS = 4'h5;

// LDW Parameters
localparam [3:0] LDW_CWGT = 4'h1;
localparam [3:0] LDW_DWGT = 4'h2;
localparam [3:0] LDW_STRT = 4'h3;
localparam [3:0] LDW_CONT = 4'h4;
localparam [3:0] LDW_MOVE = 4'h5;

// LIP Parameters
localparam [3:0] LIP_STRT = 4'h1;
localparam [3:0] LIP_CONT = 4'h2;

// ROP Parameters
localparam [3:0] ROP_STRT = 4'h1;
localparam [3:0] ROP_CONT = 4'h2;


// Register Addresses
localparam [3:0] REG_VERSN = 4'h0;
localparam [3:0] REG_HWRID = 4'h1;
localparam [3:0] REG_MEMUP = 4'h2;
localparam [3:0] REG_MSTRT = 4'h3;
localparam [3:0] REG_MENDD = 4'h4;
localparam [3:0] REG_BCFG1 = 4'h5;
localparam [3:0] REG_BCFG2 = 4'h6;
localparam [3:0] REG_BCFG3 = 4'h7;
localparam [3:0] REG_CPRM1 = 4'h8;
localparam [3:0] REG_STATS = 4'h9;
// localparam [3:0] REG_ = 4'hA;
// localparam [3:0] REG_ = 4'hB;
// localparam [3:0] REG_ = 4'hC;
// localparam [3:0] REG_ = 4'hD;
// localparam [3:0] REG_ = 4'hE;
// localparam [3:0] REG_ = 4'hF;



localparam [1:0] REG_BCFG3_LDFM_IDB = 2'h0;
localparam [1:0] REG_BCFG3_LDFM_MEM = 2'h1;
localparam [1:0] REG_BCFG3_LDFM_COP = 2'h2;
