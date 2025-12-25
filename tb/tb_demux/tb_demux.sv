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

    axi_if master ();
    axi_if slave[3] ();

    always_comb begin
        master.AWVALID = AWVALID;
        master.AWID    = AWID;
        master.AWADDR  = AWADDR;
        master.AWLEN   = AWLEN;
        master.AWSIZE  = AWSIZE;
        master.AWBURST = AWBURST;
        AWREADY        = master.AWREADY;

        master.WVALID = WVALID;
        master.WDATA  = WDATA;
        master.WSTRB  = WSTRB;
        master.WLAST  = WLAST;
        WREADY        = master.WREADY;
        
        BVALID = master.BVALID;
        BID    = master.BID;
        master.BREADY = BREADY;
        
        master.ARVALID = ARVALID;
        master.ARID    = ARID;
        master.ARADDR  = ARADDR;
        master.ARLEN   = ARLEN;
        master.ARSIZE  = ARSIZE;
        master.ARBURST = ARBURST;
        ARREADY        = master.ARREADY;

        RVALID = master.RVALID;
        RID    = master.RID;
        RDATA  = master.RDATA;
        RLAST  = master.RLAST;
        master.RREADY = RREADY;
    end

    axi_demux dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .s_axi_in(master),
        .m_axi_out(slave)
    );

    axi_ram ram[3] (
        .clk(ACLK), .rst_n(ARESETn),
        .axi_s(slave)
    );
    
endmodule