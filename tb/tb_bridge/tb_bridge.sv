module tb_bridge (
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
    input  logic [3:0] a_kalstrb,
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
    input  logic [3:0] b_kalstrb,
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

    axi_if axi[2](), axi_ram[2]();
    axis_if #(.DATA_WIDTH(40)) axis[4]();

    always_comb begin
        axi[0].AWVALID = a_awvalid;
        axi[0].AWID    = a_awid;
        axi[0].AWADDR  = a_awaddr;
        axi[0].AWLEN   = a_awlen;
        axi[0].AWSIZE  = a_awsize;
        axi[0].AWBURST = a_awburst;
        a_awready         = axi[0].AWREADY;

        axi[0].WVALID = a_wvalid;
        axi[0].WDATA  = a_wdata;
        axi[0].WSTRB  = a_kalstrb;
        axi[0].WLAST  = a_wlast;
        a_wready         = axi[0].WREADY;
        
        a_bvalid = axi[0].BVALID;
        a_bid    = axi[0].BID;
        axi[0].BREADY = a_bready;
        
        axi[0].ARVALID = a_arvalid;
        axi[0].ARID    = a_arid;
        axi[0].ARADDR  = a_araddr;
        axi[0].ARLEN   = a_arlen;
        axi[0].ARSIZE  = a_arsize;
        axi[0].ARBURST = a_arburst;
        a_arready         = axi[0].ARREADY;

        a_rvalid = axi[0].RVALID;
        a_rid    = axi[0].RID;
        a_rdata  = axi[0].RDATA;
        a_rlast  = axi[0].RLAST;
        axi[0].RREADY = a_rready;

        
        axi[1].AWVALID = b_awvalid;
        axi[1].AWID    = b_awid;
        axi[1].AWADDR  = b_awaddr;
        axi[1].AWLEN   = b_awlen;
        axi[1].AWSIZE  = b_awsize;
        axi[1].AWBURST = b_awburst;
        b_awready         = axi[1].AWREADY;

        axi[1].WVALID = b_wvalid;
        axi[1].WDATA  = b_wdata;
        axi[1].WSTRB  = b_kalstrb;
        axi[1].WLAST  = b_wlast;
        b_wready         = axi[1].WREADY;
        
        b_bvalid = axi[1].BVALID;
        b_bid    = axi[1].BID;
        axi[1].BREADY = b_bready;
        
        axi[1].ARVALID = b_arvalid;
        axi[1].ARID    = b_arid;
        axi[1].ARADDR  = b_araddr;
        axi[1].ARLEN   = b_arlen;
        axi[1].ARSIZE  = b_arsize;
        axi[1].ARBURST = b_arburst;
        b_arready         = axi[1].ARREADY;

        b_rvalid = axi[1].RVALID;
        b_rid    = axi[1].RID;
        b_rdata  = axi[1].RDATA;
        b_rlast  = axi[1].RLAST;
        axi[1].RREADY = b_rready;
    end

    axi2axis_XY dut_left (
        .ACLK(aclk),
        .ARESETn(aresetn),
        
        .s_axi_in(axi[0]),
        .m_axi_out(axi_ram[0]),
        
        .s_axis_req_in(axis[1]),
        .m_axis_req_out(axis[0]),
        
        .s_axis_resp_in(axis[3]),
        .m_axis_resp_out(axis[2])
    );

    axi2axis_XY dut_right (
        .ACLK(aclk),
        .ARESETn(aresetn),
        
        .s_axi_in(axi[1]),
        .m_axi_out(axi_ram[1]),
        
        .s_axis_req_in(axis[0]),
        .m_axis_req_out(axis[1]),
        
        .s_axis_resp_in(axis[2]),
        .m_axis_resp_out(axis[3])
    );

    axi_ram ram_left (
        .clk(aclk),
        .rst_n(aresetn),
        .axi_s(axi_ram[0])
    );
    axi_ram ram_right (
        .clk(aclk),
        .rst_n(aresetn),
        .axi_s(axi_ram[1])
    );
    
endmodule