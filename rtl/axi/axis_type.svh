typedef struct packed {
    logic [AXIS_DATA_WIDTH-1:0] TDATA;
    logic [(AXIS_DATA_WIDTH/8)-1:0] TSTRB;
    logic [(AXIS_DATA_WIDTH/8)-1:0] TKEEP;
    logic TLAST;
    `ifdef TID_PRESENT
    logic [ID_WIDTH-1:0] TID;
    `endif
    `ifdef TDEST_PRESENT
    logic [DEST_WIDTH-1:0] TDEST;
    `endif
    `ifdef TUSER_PRESENT
    logic [USER_WIDTH-1:0] TUSER;
    `endif
} axis_data_t;

typedef struct packed {
    axis_data_t data;
    logic TVALID;
} axis_mosi_t;

typedef struct packed {
    logic TREADY;
} axis_miso_t;
