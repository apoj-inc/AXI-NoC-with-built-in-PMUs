module tb_axi_loader (
    input  logic        clk_i,
    input  logic        arstn_i,

    input  logic        awready,
    output logic        awvalid,
    output logic [4:0]  awid,
    output logic [11:0] awaddr,
    output logic [7:0]  awlen,
    output logic [2:0]  awsize,
    output logic [1:0]  awburst,

    input  logic        wready,
    output logic        wvalid,
    output logic [31:0] wdata,
    output logic [3:0]  wstrb,
    output logic        wlast,

    input  logic        bvalid,
    input  logic [4:0]  bid,
    output logic        bready,

    input  logic        arready,
    output logic        arvalid,
    output logic [4:0]  arid,
    output logic [11:0] araddr,
    output logic [7:0]  arlen,
    output logic [2:0]  arsize,
    output logic [1:0]  arburst,

    input  logic        rvalid,
    input  logic [4:0]  rid,
    input  logic [31:0] rdata,
    input  logic        rlast,
    output logic        rready,

    input  logic        resp_wait_i,
    input  logic [4:0]  id_i,
    input  logic        write_i,
    input  logic [11:0] axaddr_i,
    input  logic [7:0]  axlen_i,
    input  logic [31:0] wdata_i,
    input  logic [3:0]  wstrb_i,
    input  logic        fifo_push_i,
    input  logic        start_i,
    output logic        idle_o,
    output logic [31:0] rdata_o,
    input  logic        inj_period_en_i,
    input  logic [31:0] inj_period_val_i
);



    axi_if axi_if();

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
        .AXI_DATA_WIDTH(32),
        .AXI_ADDR_WIDTH(12),
        .AXI_ID_W_WIDTH(5),
        .AXI_ID_R_WIDTH(5),
        .FIFO_DEPTH    (64),
        .LOADER_ID     (1)
    ) dut (
        .clk_i            (clk_i            ),
        .arstn_i          (arstn_i          ),

        .resp_wait_i      (resp_wait_i      ),
        .id_i             (id_i             ),
        .write_i          (write_i          ),
        .axaddr_i         (axaddr_i         ),
        .axlen_i          (axlen_i          ),
        .wdata_i          (wdata_i          ),
        .wstrb_i          (wstrb_i          ),
        .fifo_push_i      (fifo_push_i      ),

        .start_i          (start_i          ),
        .idle_o           (idle_o           ),

        .rdata_o          (rdata_o          ),

        .inj_period_en_i  (inj_period_en_i  ),
        .inj_period_val_i (inj_period_val_i ),

        .m_axi_if_o       (axi_if           )
    );
    
endmodule