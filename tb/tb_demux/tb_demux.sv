module tb_demux (

    input  logic ACLK,
    input  logic ARESETn,

    output logic AWREADY,
    input  logic AWVALID,
    input  logic [3:0] AWID,
    input  logic [15:0] AWADDR,
    input  logic [7:0] AWLEN,
    input  logic [2:0] AWSIZE,
    input  logic [1:0] AWBURST,

    output logic WREADY,
    input  logic WVALID,
    input  logic [31:0] WDATA,
    input  logic [3:0] WSTRB,
    input  logic WLAST,

    output logic BVALID,
    output logic [3:0] BID,
    input  logic BREADY,

    output logic ARREADY,
    input  logic ARVALID,
    input  logic [3:0] ARID,
    input  logic [15:0] ARADDR,
    input  logic [7:0] ARLEN,
    input  logic [2:0] ARSIZE,
    input  logic [1:0] ARBURST,

    output logic RVALID,
    output logic [3:0] RID,
    output logic [31:0] RDATA,
    output logic RLAST,
    input  logic RREADY
);


    axi_miso_t axi_miso_master;
    axi_mosi_t axi_mosi_master;

    axi_miso_t axi_miso_slave[3];
    axi_mosi_t axi_mosi_slave[3];

    always_comb begin
        axi_mosi_master.AWVALID = AWVALID;
        axi_mosi_master.data.aw.AWID    = AWID;
        axi_mosi_master.data.aw.AWADDR  = AWADDR;
        axi_mosi_master.data.aw.AWLEN   = AWLEN;
        axi_mosi_master.data.aw.AWSIZE  = AWSIZE;
        axi_mosi_master.data.aw.AWBURST = AWBURST;
        AWREADY        = axi_miso_master.AWREADY;

        axi_mosi_master.WVALID = WVALID;
        axi_mosi_master.data.w.WDATA  = WDATA;
        axi_mosi_master.data.w.WSTRB  = WSTRB;
        axi_mosi_master.data.w.WLAST  = WLAST;
        WREADY        = axi_miso_master.WREADY;
        
        BVALID = axi_miso_master.BVALID;
        BID    = axi_miso_master.data.b.BID;
        axi_mosi_master.BREADY = BREADY;
        
        axi_mosi_master.ARVALID = ARVALID;
        axi_mosi_master.data.ar.ARID    = ARID;
        axi_mosi_master.data.ar.ARADDR  = ARADDR;
        axi_mosi_master.data.ar.ARLEN   = ARLEN;
        axi_mosi_master.data.ar.ARSIZE  = ARSIZE;
        axi_mosi_master.data.ar.ARBURST = ARBURST;
        ARREADY        = axi_miso_master.ARREADY;

        RVALID = axi_miso_master.RVALID;
        RID    = axi_miso_master.data.r.RID;
        RDATA  = axi_miso_master.data.r.RDATA;
        RLAST  = axi_miso_master.data.r.RLAST;
        axi_mosi_master.RREADY = RREADY;
    end

    axi_demux #(
        .OUTPUT_NUM(3),
        .ID_ROUTING('{0, 0, 0, 0})
        ) dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .s_axi_i(axi_mosi_master),
        .s_axi_o(axi_miso_master),

        .m_axi_i(axi_miso_slave),
        .m_axi_o(axi_mosi_slave)
    );

    axi_ram ram[3] (
        .clk_i(ACLK), .rst_n_i(ARESETn),
        .in_mosi_i(axi_mosi_slave),
        .in_miso_o(axi_miso_slave)
    );
    
endmodule