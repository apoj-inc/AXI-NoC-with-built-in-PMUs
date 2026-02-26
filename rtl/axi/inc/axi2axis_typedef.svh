`ifndef __AXI2AXIS_TYPEDEF__SVH__
`define __AXI2AXIS_TYPEDEF__SVH__

// --- primary header datatypes ---
parameter PACKET_TYPE_WIDTH = 3;
typedef enum logic [2:0] { 
    ROUTING_HEADER = 3'b000,
    AW_SUBHEADER   = 3'b001,
    AR_SUBHEADER   = 3'b010,
    B_SUBHEADER    = 3'b011,
    R_DATA         = 3'b100,
    W_DATA         = 3'b101
} packet_type;

`endif