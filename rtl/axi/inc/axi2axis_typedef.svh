`ifndef __AXI2AXIS_TYPEDEF__SVH__
`define __AXI2AXIS_TYPEDEF__SVH__

// --- primary header datatypes ---
parameter PACKET_TYPE_WIDTH = 1;
typedef enum logic [2:0] {
    ROUTING_HEADER_WRITE,
    ROUTING_HEADER_READ,
    WRITE_REQUEST,
    READ_REQUEST,
    WRITE_RESPONSE,
    READ_RESPONSE
} packet_t;


typedef enum logic [2:0] { 
    AW,
    W,
    B,
    AR,
    R
} channel_arbiterer_t;

`endif