package axi2axis_XY_pkg;

    import axi_type_pkg::*;
    import axis_type_pkg::*;
    
    parameter MAX_ROUTERS_X       = 4;
    parameter MAX_ROUTERS_Y       = 4;
    parameter MAX_ROUTERS_X_WIDTH = $clog2(MAX_ROUTERS_X);
    parameter MAX_ROUTERS_Y_WIDTH = $clog2(MAX_ROUTERS_Y);
    parameter CORE_COUNT          = MAX_ROUTERS_X * MAX_ROUTERS_Y;

    parameter PACKET_TYPE_WIDTH = 3;
    typedef enum logic [2:0] { 
        ROUTING_HEADER = 3'b000,
        AW_SUBHEADER   = 3'b001,
        AR_SUBHEADER   = 3'b010,
        B_SUBHEADER    = 3'b011,
        R_DATA         = 3'b100,
        W_DATA         = 3'b101
    } packet_type;

    typedef struct packed {
        logic [AXIS_DATA_WIDTH - (8 + (MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH) * 2) - 1:0] RESERVED;
        logic [7:0] PACKET_COUNT;
        logic [MAX_ROUTERS_X_WIDTH-1:0] SOURCE_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] SOURCE_Y;
        logic [MAX_ROUTERS_X_WIDTH-1:0] DESTINATION_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] DESTINATION_Y;
    } routing_header;

    typedef struct packed {
        logic [AXIS_DATA_WIDTH - (ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2) - 1:0] RESERVED;
        logic [ID_W_WIDTH-1:0] ID;
        logic [ADDR_WIDTH-1:0] ADDR;
        logic [7:0] LEN;
        logic [2:0] SIZE;
        logic [1:0] BURST;
    } aw_subheader;

    typedef struct packed {
        logic [AXIS_DATA_WIDTH - (ID_W_WIDTH) - 1:0] RESERVED;
        logic [ID_W_WIDTH-1:0] ID;
    } b_subheader;

    typedef struct packed {
        logic [AXIS_DATA_WIDTH - (AXI_DATA_WIDTH) - 1:0] RESERVED;
        logic [AXI_DATA_WIDTH-1:0] DATA;
    } w_data;

    typedef struct packed {
        logic [AXIS_DATA_WIDTH - (ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2) - 1:0] RESERVED;
        logic [ID_R_WIDTH-1:0] ID;
        logic [ADDR_WIDTH-1:0] ADDR;
        logic [7:0] LEN;
        logic [2:0] SIZE;
        logic [1:0] BURST;
    } ar_subheader;

    typedef struct packed {
        logic [AXIS_DATA_WIDTH - (ID_R_WIDTH + AXI_DATA_WIDTH) - 1:0] RESERVED;
        logic [ID_R_WIDTH-1:0] ID;
        logic [AXI_DATA_WIDTH-1:0] DATA;
    } r_data;

endpackage