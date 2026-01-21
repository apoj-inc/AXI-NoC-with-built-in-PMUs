module tb_axi_ram (

    input  logic aclk,
    input  logic aresetn,

    output logic awready,
    input  logic awvalid,
    input  logic [3:0] awid,
    input  logic [15:0] awaddr,
    input  logic [7:0] awlen,
    input  logic [2:0] awsize,
    input  logic [1:0] awburst,

    output logic wready,
    input  logic wvalid,
    input  logic [31:0] wdata,
    input  logic [3:0] kalstrb,
    input  logic wlast,

    output logic bvalid,
    output logic [3:0] bid,
    input  logic bready,

    output logic arready,
    input  logic arvalid,
    input  logic [3:0] arid,
    input  logic [15:0] araddr,
    input  logic [7:0] arlen,
    input  logic [2:0] arsize,
    input  logic [1:0] arburst,

    output logic rvalid,
    output logic [3:0] rid,
    output logic [31:0] rdata,
    output logic rlast,
    input  logic rready
);

    axi_miso_t axi_miso_master;
    axi_mosi_t axi_mosi_master;

    always_comb begin
        axi_mosi_master.AWVALID = awvalid;
        axi_mosi_master.data.aw.AWID    = awid;
        axi_mosi_master.data.aw.AWADDR  = awaddr;
        axi_mosi_master.data.aw.AWLEN   = awlen;
        axi_mosi_master.data.aw.AWSIZE  = awsize;
        axi_mosi_master.data.aw.AWBURST = awburst;
        awready        = axi_miso_master.AWREADY;

        axi_mosi_master.WVALID = wvalid;
        axi_mosi_master.data.w.WDATA  = wdata;
        axi_mosi_master.data.w.WSTRB  = kalstrb;
        axi_mosi_master.data.w.WLAST  = wlast;
        wready        = axi_miso_master.WREADY;
        
        bvalid = axi_miso_master.BVALID;
        bid    = axi_miso_master.data.b.BID;
        axi_mosi_master.BREADY = bready;
        
        axi_mosi_master.ARVALID = arvalid;
        axi_mosi_master.data.ar.ARID    = arid;
        axi_mosi_master.data.ar.ARADDR  = araddr;
        axi_mosi_master.data.ar.ARLEN   = arlen;
        axi_mosi_master.data.ar.ARSIZE  = arsize;
        axi_mosi_master.data.ar.ARBURST = arburst;
        arready        = axi_miso_master.ARREADY;

        rvalid = axi_miso_master.RVALID;
        rid    = axi_miso_master.data.r.RID;
        rdata  = axi_miso_master.data.r.RDATA;
        rlast  = axi_miso_master.data.r.RLAST;
        axi_mosi_master.RREADY = rready;
    end

    axi_ram ram (
        .clk_i(aclk), .rst_n_i(rst_n),

        .in_mosi_i(axi_mosi_master),
        .in_miso_o(axi_miso_master)
    );
    
endmodule