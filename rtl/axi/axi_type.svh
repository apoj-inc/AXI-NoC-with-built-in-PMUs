typedef struct packed {
    // AW channel 
    logic [ID_W_WIDTH-1:0] AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0] AWLEN;
    logic [2:0] AWSIZE;
    logic [1:0] AWBURST;

    // W channel
    logic [DATA_WIDTH-1:0] WDATA;
    logic [(DATA_WIDTH/8)-1:0] WSTRB;
    logic WLAST;

    // AR channel 
    logic [ID_R_WIDTH-1:0] ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0] ARLEN;
    logic [2:0] ARSIZE;
    logic [1:0] ARBURST;
} axi_data_aw_t;

typedef struct packed {
    // B channel
    logic [ID_W_WIDTH-1:0] BID;

    // R channel
    logic [ID_R_WIDTH-1:0] RID;
    logic [DATA_WIDTH-1:0] RDATA;
    logic RLAST;
} axi_data_br_t;
