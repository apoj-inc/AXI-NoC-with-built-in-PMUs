module tb_mux (

    input  logic ACLK,
    input  logic ARESETn,

    output logic a_AWREADY,
    input  logic a_AWVALID,
    input  logic [3:0] a_AWID,
    input  logic [15:0] a_AWADDR,
    input  logic [7:0] a_AWLEN,
    input  logic [2:0] a_AWSIZE,
    input  logic [1:0] a_AWBURST,

    output logic a_WREADY,
    input  logic a_WVALID,
    input  logic [31:0] a_WDATA,
    input  logic [3:0] a_WSTRB,
    input  logic a_WLAST,

    output logic a_BVALID,
    output logic [3:0] a_BID,
    input  logic a_BREADY,

    output logic a_ARREADY,
    input  logic a_ARVALID,
    input  logic [3:0] a_ARID,
    input  logic [15:0] a_ARADDR,
    input  logic [7:0] a_ARLEN,
    input  logic [2:0] a_ARSIZE,
    input  logic [1:0] a_ARBURST,

    output logic a_RVALID,
    output logic [3:0] a_RID,
    output logic [31:0] a_RDATA,
    output logic a_RLAST,
    input  logic a_RREADY,

    output logic b_AWREADY,
    input  logic b_AWVALID,
    input  logic [3:0] b_AWID,
    input  logic [15:0] b_AWADDR,
    input  logic [7:0] b_AWLEN,
    input  logic [2:0] b_AWSIZE,
    input  logic [1:0] b_AWBURST,

    output logic b_WREADY,
    input  logic b_WVALID,
    input  logic [31:0] b_WDATA,
    input  logic [3:0] b_WSTRB,
    input  logic b_WLAST,

    output logic b_BVALID,
    output logic [3:0] b_BID,
    input  logic b_BREADY,

    output logic b_ARREADY,
    input  logic b_ARVALID,
    input  logic [3:0] b_ARID,
    input  logic [15:0] b_ARADDR,
    input  logic [7:0] b_ARLEN,
    input  logic [2:0] b_ARSIZE,
    input  logic [1:0] b_ARBURST,

    output logic b_RVALID,
    output logic [3:0] b_RID,
    output logic [31:0] b_RDATA,
    output logic b_RLAST,
    input  logic b_RREADY,

    output logic c_AWREADY,
    input  logic c_AWVALID,
    input  logic [3:0] c_AWID,
    input  logic [15:0] c_AWADDR,
    input  logic [7:0] c_AWLEN,
    input  logic [2:0] c_AWSIZE,
    input  logic [1:0] c_AWBURST,

    output logic c_WREADY,
    input  logic c_WVALID,
    input  logic [31:0] c_WDATA,
    input  logic [3:0] c_WSTRB,
    input  logic c_WLAST,

    output logic c_BVALID,
    output logic [3:0] c_BID,
    input  logic c_BREADY,

    output logic c_ARREADY,
    input  logic c_ARVALID,
    input  logic [3:0] c_ARID,
    input  logic [15:0] c_ARADDR,
    input  logic [7:0] c_ARLEN,
    input  logic [2:0] c_ARSIZE,
    input  logic [1:0] c_ARBURST,

    output logic c_RVALID,
    output logic [3:0] c_RID,
    output logic [31:0] c_RDATA,
    output logic c_RLAST,
    input  logic c_RREADY
);

    axi_miso_t axi_miso_master[3];
    axi_mosi_t axi_mosi_master[3];

    axi_miso_t axi_miso_slave;
    axi_mosi_t axi_mosi_slave;

    always_comb begin
        axi_mosi_master[0].AWVALID = a_AWVALID;
        axi_mosi_master[0].data.aw.AWID    = a_AWID;
        axi_mosi_master[0].data.aw.AWADDR  = a_AWADDR;
        axi_mosi_master[0].data.aw.AWLEN   = a_AWLEN;
        axi_mosi_master[0].data.aw.AWSIZE  = a_AWSIZE;
        axi_mosi_master[0].data.aw.AWBURST = a_AWBURST;
        a_AWREADY         = axi_miso_master[0].AWREADY;

        axi_mosi_master[0].WVALID = a_WVALID;
        axi_mosi_master[0].data.w.WDATA  = a_WDATA;
        axi_mosi_master[0].data.w.WSTRB  = a_WSTRB;
        axi_mosi_master[0].data.w.WLAST  = a_WLAST;
        a_WREADY         = axi_miso_master[0].WREADY;
        
        a_BVALID = axi_miso_master[0].BVALID;
        a_BID    = axi_miso_master[0].data.b.BID;
        axi_mosi_master[0].BREADY = a_BREADY;
        
        axi_mosi_master[0].ARVALID = a_ARVALID;
        axi_mosi_master[0].data.ar.ARID    = a_ARID;
        axi_mosi_master[0].data.ar.ARADDR  = a_ARADDR;
        axi_mosi_master[0].data.ar.ARLEN   = a_ARLEN;
        axi_mosi_master[0].data.ar.ARSIZE  = a_ARSIZE;
        axi_mosi_master[0].data.ar.ARBURST = a_ARBURST;
        a_ARREADY         = axi_miso_master[0].ARREADY;

        a_RVALID = axi_miso_master[0].RVALID;
        a_RID    = axi_miso_master[0].data.r.RID;
        a_RDATA  = axi_miso_master[0].data.r.RDATA;
        a_RLAST  = axi_miso_master[0].data.r.RLAST;
        axi_mosi_master[0].RREADY = a_RREADY;
    end

    always_comb begin
        axi_mosi_master[1].AWVALID = b_AWVALID;
        axi_mosi_master[1].data.aw.AWID    = b_AWID;
        axi_mosi_master[1].data.aw.AWADDR  = b_AWADDR;
        axi_mosi_master[1].data.aw.AWLEN   = b_AWLEN;
        axi_mosi_master[1].data.aw.AWSIZE  = b_AWSIZE;
        axi_mosi_master[1].data.aw.AWBURST = b_AWBURST;
        b_AWREADY         = axi_miso_master[1].AWREADY;

        axi_mosi_master[1].WVALID = b_WVALID;
        axi_mosi_master[1].data.w.WDATA  = b_WDATA;
        axi_mosi_master[1].data.w.WSTRB  = b_WSTRB;
        axi_mosi_master[1].data.w.WLAST  = b_WLAST;
        b_WREADY         = axi_miso_master[1].WREADY;
        
        b_BVALID = axi_miso_master[1].BVALID;
        b_BID    = axi_miso_master[1].data.b.BID;
        axi_mosi_master[1].BREADY = b_BREADY;
        
        axi_mosi_master[1].ARVALID = b_ARVALID;
        axi_mosi_master[1].data.ar.ARID    = b_ARID;
        axi_mosi_master[1].data.ar.ARADDR  = b_ARADDR;
        axi_mosi_master[1].data.ar.ARLEN   = b_ARLEN;
        axi_mosi_master[1].data.ar.ARSIZE  = b_ARSIZE;
        axi_mosi_master[1].data.ar.ARBURST = b_ARBURST;
        b_ARREADY         = axi_miso_master[1].ARREADY;

        b_RVALID = axi_miso_master[1].RVALID;
        b_RID    = axi_miso_master[1].data.r.RID;
        b_RDATA  = axi_miso_master[1].data.r.RDATA;
        b_RLAST  = axi_miso_master[1].data.r.RLAST;
        axi_mosi_master[1].RREADY = b_RREADY;
    end

    always_comb begin
        axi_mosi_master[2].AWVALID = c_AWVALID;
        axi_mosi_master[2].data.aw.AWID    = c_AWID;
        axi_mosi_master[2].data.aw.AWADDR  = c_AWADDR;
        axi_mosi_master[2].data.aw.AWLEN   = c_AWLEN;
        axi_mosi_master[2].data.aw.AWSIZE  = c_AWSIZE;
        axi_mosi_master[2].data.aw.AWBURST = c_AWBURST;
        c_AWREADY         = axi_miso_master[2].AWREADY;

        axi_mosi_master[2].WVALID = c_WVALID;
        axi_mosi_master[2].data.w.WDATA  = c_WDATA;
        axi_mosi_master[2].data.w.WSTRB  = c_WSTRB;
        axi_mosi_master[2].data.w.WLAST  = c_WLAST;
        c_WREADY         = axi_miso_master[2].WREADY;
        
        c_BVALID = axi_miso_master[2].BVALID;
        c_BID    = axi_miso_master[2].data.b.BID;
        axi_mosi_master[2].BREADY = c_BREADY;
        
        axi_mosi_master[2].ARVALID = c_ARVALID;
        axi_mosi_master[2].data.ar.ARID    = c_ARID;
        axi_mosi_master[2].data.ar.ARADDR  = c_ARADDR;
        axi_mosi_master[2].data.ar.ARLEN   = c_ARLEN;
        axi_mosi_master[2].data.ar.ARSIZE  = c_ARSIZE;
        axi_mosi_master[2].data.ar.ARBURST = c_ARBURST;
        c_ARREADY         = axi_miso_master[2].ARREADY;

        c_RVALID = axi_miso_master[2].RVALID;
        c_RID    = axi_miso_master[2].data.r.RID;
        c_RDATA  = axi_miso_master[2].data.r.RDATA;
        c_RLAST  = axi_miso_master[2].data.r.RLAST;
        axi_mosi_master[2].RREADY = c_RREADY;
    end

    axi_mux  #(
        .INPUT_NUM(3)
        ) dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .s_axi_i(axi_mosi_master),
        .s_axi_o(axi_miso_master),

        .m_axi_i(axi_miso_slave),
        .m_axi_o(axi_mosi_slave)
    );

    axi_ram ram (
        .clk_i(ACLK), .rst_n_i(ARESETn),
        .in_mosi_i(axi_mosi_slave),
        .in_miso_o(axi_miso_slave)
    );
    
endmodule