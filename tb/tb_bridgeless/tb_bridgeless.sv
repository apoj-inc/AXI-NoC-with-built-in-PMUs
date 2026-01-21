module tb_bridgeless (

    input  logic aclk,
    input  logic aresetn,

    output logic a_awready,
    input  logic a_awvalid,
    input  logic [3:0] a_awid,
    input  logic [15:0] a_awaddr,
    input  logic [7:0] a_awlen,
    input  logic [2:0] a_awsize,
    input  logic [1:0] a_awburst,

    output logic a_wready,
    input  logic a_wvalid,
    input  logic [31:0] a_wdata,
    input  logic [3:0] a_wstrb,
    input  logic a_wlast,

    output logic a_bvalid,
    output logic [3:0] a_bid,
    input  logic a_bready,

    output logic a_arready,
    input  logic a_arvalid,
    input  logic [3:0] a_arid,
    input  logic [15:0] a_araddr,
    input  logic [7:0] a_arlen,
    input  logic [2:0] a_arsize,
    input  logic [1:0] a_arburst,

    output logic a_rvalid,
    output logic [3:0] a_rid,
    output logic [31:0] a_rdata,
    output logic a_rlast,
    input  logic a_rready,

    output logic b_awready,
    input  logic b_awvalid,
    input  logic [3:0] b_awid,
    input  logic [15:0] b_awaddr,
    input  logic [7:0] b_awlen,
    input  logic [2:0] b_awsize,
    input  logic [1:0] b_awburst,

    output logic b_wready,
    input  logic b_wvalid,
    input  logic [31:0] b_wdata,
    input  logic [3:0] b_wstrb,
    input  logic b_wlast,

    output logic b_bvalid,
    output logic [3:0] b_bid,
    input  logic b_bready,

    output logic b_arready,
    input  logic b_arvalid,
    input  logic [3:0] b_arid,
    input  logic [15:0] b_araddr,
    input  logic [7:0] b_arlen,
    input  logic [2:0] b_arsize,
    input  logic [1:0] b_arburst,

    output logic b_rvalid,
    output logic [3:0] b_rid,
    output logic [31:0] b_rdata,
    output logic b_rlast,
    input  logic b_rready
);


    axi_miso_t axi_miso_master[2];
    axi_mosi_t axi_mosi_master[2];

    axi_miso_t axi_miso_ram[2];
    axi_mosi_t axi_mosi_ram[2];

    axi_miso_t axi_miso_demux[2];
    axi_mosi_t axi_mosi_demux[2];

    always_comb begin
        axi_mosi_master[0].AWVALID = a_awvalid;
        axi_mosi_master[0].data.aw.AWID    = a_awid;
        axi_mosi_master[0].data.aw.AWADDR  = a_awaddr;
        axi_mosi_master[0].data.aw.AWLEN   = a_awlen;
        axi_mosi_master[0].data.aw.AWSIZE  = a_awsize;
        axi_mosi_master[0].data.aw.AWBURST = a_awburst;
        a_awready                = axi_miso_master[0].AWREADY;

        axi_mosi_master[0].WVALID = a_wvalid;
        axi_mosi_master[0].data.w.WDATA  = a_wdata;
        axi_mosi_master[0].data.w.WSTRB  = a_wstrb;
        axi_mosi_master[0].data.w.WLAST  = a_wlast;
        a_wready                = axi_miso_master[0].WREADY;

        a_rvalid                 = axi_miso_master[0].RVALID;
        a_rid                    = axi_miso_master[0].data.r.RID;
        a_rdata                  = axi_miso_master[0].data.r.RDATA;
        a_rlast                  = axi_miso_master[0].data.r.RLAST;
        axi_mosi_master[0].RREADY       = a_rready;
        
        axi_mosi_master[0].ARVALID = a_arvalid;
        axi_mosi_master[0].data.ar.ARID    = a_arid;
        axi_mosi_master[0].data.ar.ARADDR  = a_araddr;
        axi_mosi_master[0].data.ar.ARLEN   = a_arlen;
        axi_mosi_master[0].data.ar.ARSIZE  = a_arsize;
        axi_mosi_master[0].data.ar.ARBURST = a_arburst;
        a_arready                = axi_miso_master[0].ARREADY;
        
        a_bvalid                 = axi_miso_master[0].BVALID;
        a_bid                    = axi_miso_master[0].data.b.BID;
        axi_mosi_master[0].BREADY       = a_bready;
    end

    always_comb begin
        axi_mosi_master[1].AWVALID = b_awvalid;
        axi_mosi_master[1].data.aw.AWID    = b_awid;
        axi_mosi_master[1].data.aw.AWADDR  = b_awaddr;
        axi_mosi_master[1].data.aw.AWLEN   = b_awlen;
        axi_mosi_master[1].data.aw.AWSIZE  = b_awsize;
        axi_mosi_master[1].data.aw.AWBURST = b_awburst;
        b_awready                = axi_miso_master[1].AWREADY;

        axi_mosi_master[1].WVALID = b_wvalid;
        axi_mosi_master[1].data.w.WDATA  = b_wdata;
        axi_mosi_master[1].data.w.WSTRB  = b_wstrb;
        axi_mosi_master[1].data.w.WLAST  = b_wlast;
        b_wready                = axi_miso_master[1].WREADY;

        b_rvalid                 = axi_miso_master[1].RVALID;
        b_rid                    = axi_miso_master[1].data.r.RID;
        b_rdata                  = axi_miso_master[1].data.r.RDATA;
        b_rlast                  = axi_miso_master[1].data.r.RLAST;
        axi_mosi_master[1].RREADY       = b_rready;
        
        axi_mosi_master[1].ARVALID = b_arvalid;
        axi_mosi_master[1].data.ar.ARID    = b_arid;
        axi_mosi_master[1].data.ar.ARADDR  = b_araddr;
        axi_mosi_master[1].data.ar.ARLEN   = b_arlen;
        axi_mosi_master[1].data.ar.ARSIZE  = b_arsize;
        axi_mosi_master[1].data.ar.ARBURST = b_arburst;
        b_arready                = axi_miso_master[1].ARREADY;
        
        b_bvalid                 = axi_miso_master[1].BVALID;
        b_bid                    = axi_miso_master[1].data.b.BID;
        axi_mosi_master[1].BREADY       = b_bready;
    end

    always_comb begin
        
    end

    axi_demux #(
        .OUTPUT_NUM(2),
        .ID_ROUTING('{0, 0})
    ) axi_demux (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_i(axi_mosi_master[0]),
        .s_axi_o(axi_miso_master[0]),

        .m_axi_i(axi_miso_demux),
        .m_axi_o(axi_mosi_demux)
    );

    axi_mux #(
        .INPUT_NUM(2),
        .ID_ROUTING('{0, 0})
    ) axi_mux (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_i('{axi_mosi_demux[0], axi_mosi_master[1]}),
        .s_axi_o('{axi_miso_demux[0], axi_miso_master[1]}),
        
        .m_axi_i(axi_miso_ram[0]),
        .m_axi_o(axi_mosi_ram[0])
    );

    axi_ram ram_close (
        .clk_i(aclk), .rst_n_i(aresetn),
        .in_mosi_i(axi_mosi_ram[0]),
        .in_miso_o(axi_miso_ram[0])
    );

    axi_ram ram_far (
        .clk_i(aclk), .rst_n_i(aresetn),
        .in_mosi_i(axi_mosi_demux[1]),
        .in_miso_o(axi_miso_demux[1])
    );
    
endmodule