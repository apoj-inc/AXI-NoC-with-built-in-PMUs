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

    axi_if master[2] ();
    axi_if ram_if[2] ();
    axi_if demux_out[2] ();

    always_comb begin
        master[0].AWVALID = a_awvalid;
        master[0].AWID    = a_awid;
        master[0].AWADDR  = a_awaddr;
        master[0].AWLEN   = a_awlen;
        master[0].AWSIZE  = a_awsize;
        master[0].AWBURST = a_awburst;
        a_awready         = master[0].AWREADY;

        master[0].WVALID = a_wvalid;
        master[0].WDATA  = a_wdata;
        master[0].WSTRB  = a_wstrb;
        master[0].WLAST  = a_wlast;
        a_wready         = master[0].WREADY;
        
        a_bvalid = master[0].BVALID;
        a_bid    = master[0].BID;
        master[0].BREADY = a_bready;
        
        master[0].ARVALID = a_arvalid;
        master[0].ARID    = a_arid;
        master[0].ARADDR  = a_araddr;
        master[0].ARLEN   = a_arlen;
        master[0].ARSIZE  = a_arsize;
        master[0].ARBURST = a_arburst;
        a_arready         = master[0].ARREADY;

        a_rvalid = master[0].RVALID;
        a_rid    = master[0].RID;
        a_rdata  = master[0].RDATA;
        a_rlast  = master[0].RLAST;
        master[0].RREADY = a_rready;
    end

    always_comb begin
        master[1].AWVALID = b_awvalid;
        master[1].AWID    = b_awid;
        master[1].AWADDR  = b_awaddr;
        master[1].AWLEN   = b_awlen;
        master[1].AWSIZE  = b_awsize;
        master[1].AWBURST = b_awburst;
        b_awready         = master[1].AWREADY;

        master[1].WVALID = b_wvalid;
        master[1].WDATA  = b_wdata;
        master[1].WSTRB  = b_wstrb;
        master[1].WLAST  = b_wlast;
        b_wready         = master[1].WREADY;
        
        b_bvalid = master[1].BVALID;
        b_bid    = master[1].BID;
        master[1].BREADY = b_bready;
        
        master[1].ARVALID = b_arvalid;
        master[1].ARID    = b_arid;
        master[1].ARADDR  = b_araddr;
        master[1].ARLEN   = b_arlen;
        master[1].ARSIZE  = b_arsize;
        master[1].ARBURST = b_arburst;
        b_arready         = master[1].ARREADY;

        b_rvalid = master[1].RVALID;
        b_rid    = master[1].RID;
        b_rdata  = master[1].RDATA;
        b_rlast  = master[1].RLAST;
        master[1].RREADY = b_rready;
    end

    always_comb begin
        
    end

    axi_demux #(
        .OUTPUT_NUM(2),
        .ID_ROUTING('{0, 0})
    ) axi_demux (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_in(master[0]),
        .m_axi_out(demux_out)
    );

    axi_mux #(
        .INPUT_NUM(2),
        .ID_ROUTING('{0, 0})
    ) axi_mux (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_in('{demux_out[0], master[1]}),
        .m_axi_out(ram_if[0])
    );

    axi_ram ram_close (
        .clk(aclk), .rst_n(aresetn),
        .axi_s(ram_if[0])
    );

    axi_ram ram_far (
        .clk(aclk), .rst_n(aresetn),
        .axi_s(demux_out[1])
    );
    
endmodule