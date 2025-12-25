module tb_axi_ram (

    input  logic aclk,
    input  logic aresetn,

    output logic awready,
    input  logic awvalid,
    input  logic [3:0] awid,
    input  logic [15:0] awaddr,
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
    input  logic [15:0] araddr,
    input  logic [7:0] arlen,
    input  logic [2:0] arsize,
    input  logic [1:0] arburst,

    output logic rvalid,
    output logic [3:0] rid,
    output logic [31:0] rdata,
    output logic rlast,
    input  logic rready
);

    axi_if master ();

    always_comb begin
        master.AWVALID = awvalid;
        master.AWID    = awid;
        master.AWADDR  = awaddr;
        master.AWLEN   = awlen;
        master.AWSIZE  = awsize;
        master.AWBURST = awburst;
        awready        = master.AWREADY;

        master.WVALID = wvalid;
        master.WDATA  = wdata;
        master.WSTRB  = kalstrb;
        master.WLAST  = wlast;
        wready        = master.WREADY;
        
        bvalid = master.BVALID;
        bid    = master.BID;
        master.BREADY = bready;
        
        master.ARVALID = arvalid;
        master.ARID    = arid;
        master.ARADDR  = araddr;
        master.ARLEN   = arlen;
        master.ARSIZE  = arsize;
        master.ARBURST = arburst;
        arready        = master.ARREADY;

        rvalid = master.RVALID;
        rid    = master.RID;
        rdata  = master.RDATA;
        rlast  = master.RLAST;
        master.RREADY = rready;
    end

    axi_ram ram (
        .clk(aclk), .rst_n(rst_n),
        .axi_s(master)
    );
    
endmodule