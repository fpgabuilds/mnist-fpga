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

// LDW Parameters
localparam [3:0] LDW_CWGT = 4'h1;
localparam [3:0] LDW_DWGT = 4'h2;

// LIP Parameters
localparam [3:0] LIP_STRT = 4'h1;
localparam [3:0] LIP_CONT = 4'h2;

// ROP Parameters
localparam [3:0] ROP_STRT = 4'h1;
localparam [3:0] ROP_CONT = 4'h2;

