typedef struct packed {
    // AW channel 
    logic [ID_W_WIDTH-1:0] AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0] AWLEN;
    logic [2:0] AWSIZE;
    logic [1:0] AWBURST;
} axi_data_aw_t;

typedef struct packed {
     // W channel
    logic [AXI_DATA_WIDTH-1:0] WDATA;
    logic [(AXI_DATA_WIDTH/8)-1:0] WSTRB;
    logic WLAST;
} axi_data_w_t;

typedef struct packed {
    // AR channel 
    logic [ID_R_WIDTH-1:0] ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0] ARLEN;
    logic [2:0] ARSIZE;
    logic [1:0] ARBURST;
} axi_data_ar_t;

typedef struct packed {
    // B channel
    logic [ID_W_WIDTH-1:0] BID;
} axi_data_b_t;

typedef struct packed {
    // R channel
    logic [ID_R_WIDTH-1:0] RID;
    logic [AXI_DATA_WIDTH-1:0] RDATA;
    logic RLAST;
} axi_data_r_t;

typedef struct packed {
    axi_data_aw_t aw;
    axi_data_w_t  w;
    axi_data_ar_t ar;
} axi_data_mosi_t;

typedef struct packed {
    axi_data_b_t b;
    axi_data_r_t r;
} axi_data_miso_t;

typedef struct packed {
    axi_data_mosi_t data;

    logic AWVALID;
    logic WVALID;
    logic ARVALID;

    logic BREADY;
    logic RREADY;

} axi_mosi_t;

typedef struct packed {
    axi_data_miso_t data;

    logic AWREADY;
    logic WREADY;
    logic ARREADY;

    logic BVALID;
    logic RVALID;

} axi_miso_t;
