module tb_axi_loader (
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

    `include "axi_type.svh"

    axi_miso_t axi_miso;
    axi_mosi_t axi_mosi;

    always_comb begin
        awvalid        = axi_mosi.AWVALID;
        awid           = axi_mosi.data.aw.AWID;
        awaddr         = axi_mosi.data.aw.AWADDR;
        awlen          = axi_mosi.data.aw.AWLEN;
        awsize         = axi_mosi.data.aw.AWSIZE;
        awburst        = axi_mosi.data.aw.AWBURST;
        axi_miso.AWREADY = awready;

        wvalid        = axi_mosi.WVALID;
        wdata         = axi_mosi.data.w.WDATA;
        wstrb         = axi_mosi.data.w.WSTRB;
        wlast         = axi_mosi.data.w.WLAST;
        axi_miso.WREADY = wready;
        
        axi_miso.BVALID = bvalid;
        axi_miso.data.b.BID    = bid;
        bready        = axi_mosi.BREADY;
        
        arvalid        = axi_mosi.ARVALID;
        arid           = axi_mosi.data.ar.ARID;
        araddr         = axi_mosi.data.ar.ARADDR;
        arlen          = axi_mosi.data.ar.ARLEN;
        arsize         = axi_mosi.data.ar.ARSIZE;
        arburst        = axi_mosi.data.ar.ARBURST;
        axi_miso.ARREADY = arready;

        axi_miso.RVALID = rvalid;
        axi_miso.data.r.RID    = rid;
        axi_miso.data.r.RDATA  = rdata;
        axi_miso.data.r.RLAST  = rlast;
        rready        = axi_mosi.RREADY;
    end

    axi_master_loader #(
        .AXI_DATA_WIDTH(8),
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

        .m_axi_i     (axi_miso    ),
        .m_axi_o     (axi_mosi    )
    );
    
endmodule