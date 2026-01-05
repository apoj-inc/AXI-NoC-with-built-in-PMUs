typedef struct packed {
    logic [DATA_WIDTH-1:0] TDATA;
    logic [(DATA_WIDTH/8)-1:0] TSTRB;
    logic [(DATA_WIDTH/8)-1:0] TKEEP;
    logic TLAST;
    logic [ID_WIDTH-1:0] TID;
    logic [DEST_WIDTH-1:0] TDEST;
    logic [USER_WIDTH-1:0] TUSER;
} axis_data_t;

typedef struct packed {
    axis_data_t axis_data;
    logic TVALID;
} axis_mosi_t;

typedef struct packed {
    logic TREADY;
} axis_miso_t;
