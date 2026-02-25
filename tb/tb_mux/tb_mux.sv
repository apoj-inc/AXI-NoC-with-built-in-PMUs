module tb_mux (

    input  logic ACLK,
    input  logic ARESETn,

    output logic a_AWREADY,
    input  logic a_AWVALID,
    input  logic [3:0] a_AWID,
    input  logic [11:0] a_AWADDR,
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
    input  logic [11:0] a_ARADDR,
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
    input  logic [11:0] b_AWADDR,
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
    input  logic [11:0] b_ARADDR,
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
    input  logic [11:0] c_AWADDR,
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
    input  logic [11:0] c_ARADDR,
    input  logic [7:0] c_ARLEN,
    input  logic [2:0] c_ARSIZE,
    input  logic [1:0] c_ARBURST,

    output logic c_RVALID,
    output logic [3:0] c_RID,
    output logic [31:0] c_RDATA,
    output logic c_RLAST,
    input  logic c_RREADY
);


    axi_if #(
        .AXI_DATA_WIDTH(32),
        .AXI_ADDR_WIDTH(16),
        .AXI_ID_W_WIDTH(4),
        .AXI_ID_R_WIDTH(4)
    ) axi_in[3](), axi_out();

    always_comb begin
        axi_in[0].AWVALID = a_AWVALID;
        axi_in[0].AWID    = a_AWID;
        axi_in[0].AWADDR  = a_AWADDR;
        axi_in[0].AWLEN   = a_AWLEN;
        axi_in[0].AWSIZE  = a_AWSIZE;
        axi_in[0].AWBURST = a_AWBURST;
        a_AWREADY         = axi_in[0].AWREADY;

        axi_in[0].WVALID = a_WVALID;
        axi_in[0].WDATA  = a_WDATA;
        axi_in[0].WSTRB  = a_WSTRB;
        axi_in[0].WLAST  = a_WLAST;
        a_WREADY         = axi_in[0].WREADY;
        
        a_BVALID = axi_in[0].BVALID;
        a_BID    = axi_in[0].BID;
        axi_in[0].BREADY = a_BREADY;
        
        axi_in[0].ARVALID = a_ARVALID;
        axi_in[0].ARID    = a_ARID;
        axi_in[0].ARADDR  = a_ARADDR;
        axi_in[0].ARLEN   = a_ARLEN;
        axi_in[0].ARSIZE  = a_ARSIZE;
        axi_in[0].ARBURST = a_ARBURST;
        a_ARREADY         = axi_in[0].ARREADY;

        a_RVALID = axi_in[0].RVALID;
        a_RID    = axi_in[0].RID;
        a_RDATA  = axi_in[0].RDATA;
        a_RLAST  = axi_in[0].RLAST;
        axi_in[0].RREADY = a_RREADY;
    end

    always_comb begin
        axi_in[1].AWVALID = b_AWVALID;
        axi_in[1].AWID    = b_AWID;
        axi_in[1].AWADDR  = b_AWADDR;
        axi_in[1].AWLEN   = b_AWLEN;
        axi_in[1].AWSIZE  = b_AWSIZE;
        axi_in[1].AWBURST = b_AWBURST;
        b_AWREADY         = axi_in[1].AWREADY;

        axi_in[1].WVALID = b_WVALID;
        axi_in[1].WDATA  = b_WDATA;
        axi_in[1].WSTRB  = b_WSTRB;
        axi_in[1].WLAST  = b_WLAST;
        b_WREADY         = axi_in[1].WREADY;
        
        b_BVALID = axi_in[1].BVALID;
        b_BID    = axi_in[1].BID;
        axi_in[1].BREADY = b_BREADY;
        
        axi_in[1].ARVALID = b_ARVALID;
        axi_in[1].ARID    = b_ARID;
        axi_in[1].ARADDR  = b_ARADDR;
        axi_in[1].ARLEN   = b_ARLEN;
        axi_in[1].ARSIZE  = b_ARSIZE;
        axi_in[1].ARBURST = b_ARBURST;
        b_ARREADY         = axi_in[1].ARREADY;

        b_RVALID = axi_in[1].RVALID;
        b_RID    = axi_in[1].RID;
        b_RDATA  = axi_in[1].RDATA;
        b_RLAST  = axi_in[1].RLAST;
        axi_in[1].RREADY = b_RREADY;
    end

    always_comb begin
        axi_in[2].AWVALID = c_AWVALID;
        axi_in[2].AWID    = c_AWID;
        axi_in[2].AWADDR  = c_AWADDR;
        axi_in[2].AWLEN   = c_AWLEN;
        axi_in[2].AWSIZE  = c_AWSIZE;
        axi_in[2].AWBURST = c_AWBURST;
        c_AWREADY         = axi_in[2].AWREADY;

        axi_in[2].WVALID = c_WVALID;
        axi_in[2].WDATA  = c_WDATA;
        axi_in[2].WSTRB  = c_WSTRB;
        axi_in[2].WLAST  = c_WLAST;
        c_WREADY         = axi_in[2].WREADY;
        
        c_BVALID = axi_in[2].BVALID;
        c_BID    = axi_in[2].BID;
        axi_in[2].BREADY = c_BREADY;
        
        axi_in[2].ARVALID = c_ARVALID;
        axi_in[2].ARID    = c_ARID;
        axi_in[2].ARADDR  = c_ARADDR;
        axi_in[2].ARLEN   = c_ARLEN;
        axi_in[2].ARSIZE  = c_ARSIZE;
        axi_in[2].ARBURST = c_ARBURST;
        c_ARREADY         = axi_in[2].ARREADY;

        c_RVALID = axi_in[2].RVALID;
        c_RID    = axi_in[2].RID;
        c_RDATA  = axi_in[2].RDATA;
        c_RLAST  = axi_in[2].RLAST;
        axi_in[2].RREADY = c_RREADY;
    end

    axi_mux  #(
        .INPUT_NUM(3),
        .AXI_ADDR_WIDTH(12)
    ) dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .s_axi_if_i(axi_in),
        .m_axi_if_o(axi_out)
    );

    axi_ram #(
        .AXI_ADDR_WIDTH(12)
    ) ram (
        .clk_i(ACLK), .rst_n_i(ARESETn),
        .s_axi_i(axi_out)
    );
    
endmodule