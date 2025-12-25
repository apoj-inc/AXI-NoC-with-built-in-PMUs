module tb_loader (
    input  logic        clk_i,
    input  logic        arstn_i,

    input  logic        awready,
    output logic        awvalid,
    output logic [4:0]  awid,
    output logic [15:0] awaddr,
    output logic [7:0]  awlen,
    output logic [2:0]  awsize,
    output logic [1:0]  awburst,

    input  logic        wready,
    output logic        wvalid,
    output logic [7:0]  wdata,
    output logic        wstrb,
    output logic        wlast,

    input  logic        bvalid,
    input  logic [4:0]  bid,
    output logic        bready,

    input  logic        arready,
    output logic        arvalid,
    output logic [4:0]  arid,
    output logic [15:0] araddr,
    output logic [7:0]  arlen,
    output logic [2:0]  arsize,
    output logic [1:0]  arburst,

    input  logic        rvalid,
    input  logic [4:0]  rid,
    input  logic [7:0]  rdata,
    input  logic        rlast,
    output logic        rready,

    input  logic [7:0]  req_depth_i,
    input  logic [4:0]  id_i,
    input  logic        write_i,
    input  logic [7:0]  axlen_i,
    input  logic        fifo_push_i,
    input  logic        start_i,
    output logic        idle_o
);

    axi_if #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(16),
        .ID_W_WIDTH(5),
        .ID_R_WIDTH(5)
    ) axi_if();

    always_comb begin
        awvalid        = axi_if.AWVALID;
        awid           = axi_if.AWID;
        awaddr         = axi_if.AWADDR;
        awlen          = axi_if.AWLEN;
        awsize         = axi_if.AWSIZE;
        awburst        = axi_if.AWBURST;
        axi_if.AWREADY = awready;

        wvalid        = axi_if.WVALID;
        wdata         = axi_if.WDATA;
        wstrb         = axi_if.WSTRB;
        wlast         = axi_if.WLAST;
        axi_if.WREADY = wready;
        
        axi_if.BVALID = bvalid;
        axi_if.BID    = bid;
        bready        = axi_if.BREADY;
        
        arvalid        = axi_if.ARVALID;
        arid           = axi_if.ARID;
        araddr         = axi_if.ARADDR;
        arlen          = axi_if.ARLEN;
        arsize         = axi_if.ARSIZE;
        arburst        = axi_if.ARBURST;
        axi_if.ARREADY = arready;

        axi_if.RVALID = rvalid;
        axi_if.RID    = rid;
        axi_if.RDATA  = rdata;
        axi_if.RLAST  = rlast;
        rready        = axi_if.RREADY;
    end

    axi_master_loader #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(16),
        .ID_W_WIDTH(5),
        .ID_R_WIDTH(5),
        .FIFO_DEPTH(32),
        .LOADER_ID(1)
    ) dut (
        .clk_i       (clk_i),
        .arstn_i     (arstn_i),

        .req_depth_i (req_depth_i ),

        .id_i        (id_i        ),
        .write_i     (write_i     ),
        .axlen_i     (axlen_i     ),
        .fifo_push_i (fifo_push_i ),

        .start_i     (start_i     ),
        .idle_o      (idle_o      ),

        .m_axi_o     (axi_if      )
    );
    
endmodule