module tb_bridgeless (

    input  logic aclk,
    input  logic aresetn,

    output logic a_awready,
    input  logic a_awvalid,
    input  logic [3:0] a_awid,
    input  logic [11:0] a_awaddr,
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
    input  logic [11:0] a_araddr,
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
    input  logic [11:0] b_awaddr,
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
    input  logic [11:0] b_araddr,
    input  logic [7:0] b_arlen,
    input  logic [2:0] b_arsize,
    input  logic [1:0] b_arburst,

    output logic b_rvalid,
    output logic [3:0] b_rid,
    output logic [31:0] b_rdata,
    output logic b_rlast,
    input  logic b_rready
);

    
    axi_if #(
        .AXI_DATA_WIDTH(32),
        .AXI_ADDR_WIDTH(16),
        .AXI_ID_W_WIDTH(4),
        .AXI_ID_R_WIDTH(4)
    ) axi_master[2](), axi_ram_if[2](), axi_demux_if[2]();

    always_comb begin
        axi_master[0].AWVALID = a_awvalid;
        axi_master[0].AWID    = a_awid;
        axi_master[0].AWADDR  = a_awaddr;
        axi_master[0].AWLEN   = a_awlen;
        axi_master[0].AWSIZE  = a_awsize;
        axi_master[0].AWBURST = a_awburst;
        a_awready                = axi_master[0].AWREADY;

        axi_master[0].WVALID = a_wvalid;
        axi_master[0].WDATA  = a_wdata;
        axi_master[0].WSTRB  = a_wstrb;
        axi_master[0].WLAST  = a_wlast;
        a_wready                = axi_master[0].WREADY;

        a_rvalid                 = axi_master[0].RVALID;
        a_rid                    = axi_master[0].RID;
        a_rdata                  = axi_master[0].RDATA;
        a_rlast                  = axi_master[0].RLAST;
        axi_master[0].RREADY       = a_rready;
        
        axi_master[0].ARVALID = a_arvalid;
        axi_master[0].ARID    = a_arid;
        axi_master[0].ARADDR  = a_araddr;
        axi_master[0].ARLEN   = a_arlen;
        axi_master[0].ARSIZE  = a_arsize;
        axi_master[0].ARBURST = a_arburst;
        a_arready                = axi_master[0].ARREADY;
        
        a_bvalid                 = axi_master[0].BVALID;
        a_bid                    = axi_master[0].BID;
        axi_master[0].BREADY       = a_bready;
    end

    always_comb begin
        axi_master[1].AWVALID = b_awvalid;
        axi_master[1].AWID    = b_awid;
        axi_master[1].AWADDR  = b_awaddr;
        axi_master[1].AWLEN   = b_awlen;
        axi_master[1].AWSIZE  = b_awsize;
        axi_master[1].AWBURST = b_awburst;
        b_awready                = axi_master[1].AWREADY;

        axi_master[1].WVALID = b_wvalid;
        axi_master[1].WDATA  = b_wdata;
        axi_master[1].WSTRB  = b_wstrb;
        axi_master[1].WLAST  = b_wlast;
        b_wready                = axi_master[1].WREADY;

        b_rvalid                 = axi_master[1].RVALID;
        b_rid                    = axi_master[1].RID;
        b_rdata                  = axi_master[1].RDATA;
        b_rlast                  = axi_master[1].RLAST;
        axi_master[1].RREADY       = b_rready;
        
        axi_master[1].ARVALID = b_arvalid;
        axi_master[1].ARID    = b_arid;
        axi_master[1].ARADDR  = b_araddr;
        axi_master[1].ARLEN   = b_arlen;
        axi_master[1].ARSIZE  = b_arsize;
        axi_master[1].ARBURST = b_arburst;
        b_arready                = axi_master[1].ARREADY;
        
        b_bvalid                 = axi_master[1].BVALID;
        b_bid                    = axi_master[1].BID;
        axi_master[1].BREADY       = b_bready;
    end

    always_comb begin
        
    end

    axi_demux #(
        .AXI_ADDR_WIDTH(12),
        .OUTPUT_NUM(2),
        .ID_ROUTING('{0, 0})
    ) axi_demux (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_if_i(axi_master[0]),
        .m_axi_if_o(axi_demux_if)
    );

    axi_mux #(
        .AXI_ADDR_WIDTH(12),
        .INPUT_NUM(2),
        .ID_ROUTING('{0, 0})
    ) axi_mux (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_if_i('{axi_demux_if[0], axi_master[1]}),
        .m_axi_if_o(axi_ram_if[0])
    );

    axi_ram #(
        .AXI_ADDR_WIDTH(12)
    ) ram_close (
        .clk_i(aclk), .rst_n_i(aresetn),
        .s_axi_i(axi_ram_if[0])
    );

    axi_ram #(
        .AXI_ADDR_WIDTH(12)
    ) ram_far (
        .clk_i(aclk), .rst_n_i(aresetn),
        .s_axi_i(axi_demux_if[1])
    );

endmodule