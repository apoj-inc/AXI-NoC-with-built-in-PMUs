interface axi_if #(
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter ADDR_WIDTH = 16,
    parameter AXI_DATA_WIDTH = 32
) ();

    // AW channel 
    logic AWVALID;
    logic AWREADY;
    logic [ID_W_WIDTH-1:0] AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0] AWLEN;
    logic [2:0] AWSIZE;
    logic [1:0] AWBURST;

    // W channel
    logic WVALID;
    logic WREADY;
    logic [AXI_DATA_WIDTH-1:0] WDATA;
    logic [(AXI_DATA_WIDTH/8)-1:0] WSTRB;
    logic WLAST;

    // B channel
    logic BVALID;
    logic BREADY;
    logic [ID_W_WIDTH-1:0] BID;

    // AR channel 
    logic ARVALID;
    logic ARREADY;
    logic [ID_R_WIDTH-1:0] ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0] ARLEN;
    logic [2:0] ARSIZE;
    logic [1:0] ARBURST;

    // R channel
    logic RVALID;
    logic RREADY;
    logic [ID_R_WIDTH-1:0] RID;
    logic [AXI_DATA_WIDTH-1:0] RDATA;
    logic RLAST;

    modport m (
        input AWREADY,
        output AWVALID, AWID, AWADDR, AWLEN, AWSIZE, AWBURST,

        input WREADY,
        output WVALID, WDATA, WSTRB, WLAST,

        input BVALID, BID,
        output BREADY,

        input ARREADY,
        output ARVALID, ARID, ARADDR, ARLEN, ARSIZE, ARBURST,

        input RVALID, RID, RDATA, RLAST,
        output RREADY
    );

    modport s (
        output AWREADY,
        input AWVALID, AWID, AWADDR, AWLEN, AWSIZE, AWBURST,

        output WREADY,
        input WVALID, WDATA, WSTRB, WLAST,

        output BVALID, BID,
        input BREADY,

        output ARREADY,
        input ARVALID, ARID, ARADDR, ARLEN, ARSIZE, ARBURST,

        output RVALID, RID, RDATA, RLAST,
        input RREADY
    );

    modport mon (
        input AWREADY,
        input AWVALID, AWID, AWADDR, AWLEN, AWSIZE, AWBURST,

        input WREADY,
        input WVALID, WDATA, WSTRB, WLAST,

        input BVALID, BID,
        input BREADY,

        input ARREADY,
        input ARVALID, ARID, ARADDR, ARLEN, ARSIZE, ARBURST,

        input RVALID, RID, RDATA, RLAST,
        input RREADY
    );
    
    
endinterface