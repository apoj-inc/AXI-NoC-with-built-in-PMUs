module tb_axi_ram (

    input  logic aclk,
    input  logic aresetn,

    output logic awready,
    input  logic awvalid,
    input  logic [3:0] awid,
    input  logic [11:0] awaddr,
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
    input  logic [11:0] araddr,
    input  logic [7:0] arlen,
    input  logic [2:0] arsize,
    input  logic [1:0] arburst,

    output logic rvalid,
    output logic [3:0] rid,
    output logic [31:0] rdata,
    output logic rlast,
    input  logic rready
);

    axi_if axi_if();

    always_comb begin
        axi_if.AWVALID = awvalid;
        axi_if.AWID    = awid;
        axi_if.AWADDR  = awaddr;
        axi_if.AWLEN   = awlen;
        axi_if.AWSIZE  = awsize;
        axi_if.AWBURST = awburst;
        awready        = axi_if.AWREADY;

        axi_if.WVALID = wvalid;
        axi_if.WDATA  = wdata;
        axi_if.WSTRB  = kalstrb;
        axi_if.WLAST  = wlast;
        wready        = axi_if.WREADY;
        
        bvalid = axi_if.BVALID;
        bid    = axi_if.BID;
        axi_if.BREADY = bready;
        
        axi_if.ARVALID = arvalid;
        axi_if.ARID    = arid;
        axi_if.ARADDR  = araddr;
        axi_if.ARLEN   = arlen;
        axi_if.ARSIZE  = arsize;
        axi_if.ARBURST = arburst;
        arready        = axi_if.ARREADY;

        rvalid = axi_if.RVALID;
        rid    = axi_if.RID;
        rdata  = axi_if.RDATA;
        rlast  = axi_if.RLAST;
        axi_if.RREADY = rready;
    end

    axi_ram #(
        .AXI_ADDR_WIDTH(12)
    ) ram (
        .clk_i(aclk), .rst_n_i(rst_n),

        .s_axi_i(axi_if)
    );
    
endmodule