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

    axi_if master[3] ();
    axi_if slave ();

    always_comb begin
        master[0].AWVALID = a_AWVALID;
        master[0].AWID    = a_AWID;
        master[0].AWADDR  = a_AWADDR;
        master[0].AWLEN   = a_AWLEN;
        master[0].AWSIZE  = a_AWSIZE;
        master[0].AWBURST = a_AWBURST;
        a_AWREADY         = master[0].AWREADY;

        master[0].WVALID = a_WVALID;
        master[0].WDATA  = a_WDATA;
        master[0].WSTRB  = a_WSTRB;
        master[0].WLAST  = a_WLAST;
        a_WREADY         = master[0].WREADY;
        
        a_BVALID = master[0].BVALID;
        a_BID    = master[0].BID;
        master[0].BREADY = a_BREADY;
        
        master[0].ARVALID = a_ARVALID;
        master[0].ARID    = a_ARID;
        master[0].ARADDR  = a_ARADDR;
        master[0].ARLEN   = a_ARLEN;
        master[0].ARSIZE  = a_ARSIZE;
        master[0].ARBURST = a_ARBURST;
        a_ARREADY         = master[0].ARREADY;

        a_RVALID = master[0].RVALID;
        a_RID    = master[0].RID;
        a_RDATA  = master[0].RDATA;
        a_RLAST  = master[0].RLAST;
        master[0].RREADY = a_RREADY;
    end

    always_comb begin
        master[1].AWVALID = b_AWVALID;
        master[1].AWID    = b_AWID;
        master[1].AWADDR  = b_AWADDR;
        master[1].AWLEN   = b_AWLEN;
        master[1].AWSIZE  = b_AWSIZE;
        master[1].AWBURST = b_AWBURST;
        b_AWREADY         = master[1].AWREADY;

        master[1].WVALID = b_WVALID;
        master[1].WDATA  = b_WDATA;
        master[1].WSTRB  = b_WSTRB;
        master[1].WLAST  = b_WLAST;
        b_WREADY         = master[1].WREADY;
        
        b_BVALID = master[1].BVALID;
        b_BID    = master[1].BID;
        master[1].BREADY = b_BREADY;
        
        master[1].ARVALID = b_ARVALID;
        master[1].ARID    = b_ARID;
        master[1].ARADDR  = b_ARADDR;
        master[1].ARLEN   = b_ARLEN;
        master[1].ARSIZE  = b_ARSIZE;
        master[1].ARBURST = b_ARBURST;
        b_ARREADY         = master[1].ARREADY;

        b_RVALID = master[1].RVALID;
        b_RID    = master[1].RID;
        b_RDATA  = master[1].RDATA;
        b_RLAST  = master[1].RLAST;
        master[1].RREADY = b_RREADY;
    end

    always_comb begin
        master[2].AWVALID = c_AWVALID;
        master[2].AWID    = c_AWID;
        master[2].AWADDR  = c_AWADDR;
        master[2].AWLEN   = c_AWLEN;
        master[2].AWSIZE  = c_AWSIZE;
        master[2].AWBURST = c_AWBURST;
        c_AWREADY         = master[2].AWREADY;

        master[2].WVALID = c_WVALID;
        master[2].WDATA  = c_WDATA;
        master[2].WSTRB  = c_WSTRB;
        master[2].WLAST  = c_WLAST;
        c_WREADY         = master[2].WREADY;
        
        c_BVALID = master[2].BVALID;
        c_BID    = master[2].BID;
        master[2].BREADY = c_BREADY;
        
        master[2].ARVALID = c_ARVALID;
        master[2].ARID    = c_ARID;
        master[2].ARADDR  = c_ARADDR;
        master[2].ARLEN   = c_ARLEN;
        master[2].ARSIZE  = c_ARSIZE;
        master[2].ARBURST = c_ARBURST;
        c_ARREADY         = master[2].ARREADY;

        c_RVALID = master[2].RVALID;
        c_RID    = master[2].RID;
        c_RDATA  = master[2].RDATA;
        c_RLAST  = master[2].RLAST;
        master[2].RREADY = c_RREADY;
    end

    axi_mux dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .s_axi_in(master),
        .m_axi_out(slave)
    );

    axi_ram ram (
        .clk(ACLK), .rst_n(ARESETn),
        .axi_s(slave)
    );
    
endmodule