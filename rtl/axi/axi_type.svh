typedef struct packed {
    logic [DATA_WIDTH-1:0] TDATA;
    logic [(DATA_WIDTH/8)-1:0] TSTRB;
    logic [(DATA_WIDTH/8)-1:0] TKEEP;
    logic TLAST;
    logic [ID_WIDTH-1:0] TID;
    logic [DEST_WIDTH-1:0] TDEST;
    logic [USER_WIDTH-1:0] TUSER;
} axi_data_t;
