module tb_demux (

    input  logic ACLK,
    input  logic ARESETn,

    output logic AWREADY,
    input  logic AWVALID,
    input  logic [3:0] AWID,
    input  logic [11:0] AWADDR,
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
    input  logic [11:0] ARADDR,
    input  logic [7:0] ARLEN,
    input  logic [2:0] ARSIZE,
    input  logic [1:0] ARBURST,

    output logic RVALID,
    output logic [3:0] RID,
    output logic [31:0] RDATA,
    output logic RLAST,
    input  logic RREADY
);


    axi_if #(
        .AXI_DATA_WIDTH(32),
        .AXI_ADDR_WIDTH(16),
        .AXI_ID_W_WIDTH(4),
        .AXI_ID_R_WIDTH(4)
    ) axi_in(), axi_out[3]();

    always_comb begin
        axi_in.AWVALID = AWVALID;
        axi_in.AWID    = AWID;
        axi_in.AWADDR  = AWADDR;
        axi_in.AWLEN   = AWLEN;
        axi_in.AWSIZE  = AWSIZE;
        axi_in.AWBURST = AWBURST;
        AWREADY        = axi_in.AWREADY;

        axi_in.WVALID = WVALID;
        axi_in.WDATA  = WDATA;
        axi_in.WSTRB  = WSTRB;
        axi_in.WLAST  = WLAST;
        WREADY        = axi_in.WREADY;
        
        BVALID = axi_in.BVALID;
        BID    = axi_in.BID;
        axi_in.BREADY = BREADY;
        
        axi_in.ARVALID = ARVALID;
        axi_in.ARID    = ARID;
        axi_in.ARADDR  = ARADDR;
        axi_in.ARLEN   = ARLEN;
        axi_in.ARSIZE  = ARSIZE;
        axi_in.ARBURST = ARBURST;
        ARREADY        = axi_in.ARREADY;

        RVALID = axi_in.RVALID;
        RID    = axi_in.RID;
        RDATA  = axi_in.RDATA;
        RLAST  = axi_in.RLAST;
        axi_in.RREADY = RREADY;
    end

    axi_demux #(
        .AXI_ADDR_WIDTH(12),
        .OUTPUT_NUM(3),
        .ID_ROUTING('{0, 0, 0, 0})
    ) dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .s_axi_if_i(axi_in),
        .m_axi_if_o(axi_out)
    );

    axi_ram #(
        .AXI_ADDR_WIDTH(12)
    ) ram[3] (
        .clk_i(ACLK), .rst_n_i(ARESETn),
        .s_axi_i(axi_out)
    );
    
endmodule