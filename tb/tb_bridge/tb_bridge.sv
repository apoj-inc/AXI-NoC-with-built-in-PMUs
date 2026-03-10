module tb_bridge (
    input  logic aclk,
    input  logic aresetn,

    output logic a_awready,
    input  logic a_awvalid,
    input  logic [3:0] a_awid,
    input  logic [11:0] a_awaddr,
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
    input  logic [11:0] a_araddr,
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
    input  logic [11:0] b_awaddr,
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
    input  logic [11:0] b_araddr,
    input  logic [7:0] b_arlen,
    input  logic [2:0] b_arsize,
    input  logic [1:0] b_arburst,

    output logic b_rvalid,
    output logic [3:0] b_rid,
    output logic [31:0] b_rdata,
    output logic b_rlast,
    input  logic b_rready
);

    parameter AXI_DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 12;
    parameter ID_W_WIDTH = 5;
    parameter ID_R_WIDTH = 5;
    parameter AXIS_DATA_WIDTH = 40;
    parameter ID_WIDTH = 4;
    parameter DEST_WIDTH = 4;
    parameter USER_WIDTH = 4;

    axi_if #(
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH (ADDR_WIDTH),
        .AXI_ID_W_WIDTH (ID_W_WIDTH),
        .AXI_ID_R_WIDTH (ID_R_WIDTH)
    ) axi_to_bridge [2](), axi_to_ram[2]();

    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (ID_WIDTH),
        .AXIS_DEST_WIDTH (DEST_WIDTH),
        .AXIS_USER_WIDTH (USER_WIDTH)
    ) axis_ifs [4]();

    always_comb begin
        axi_to_bridge[0].AWVALID = a_awvalid;
        axi_to_bridge[0].AWID    = a_awid;
        axi_to_bridge[0].AWADDR  = a_awaddr;
        axi_to_bridge[0].AWLEN   = a_awlen;
        axi_to_bridge[0].AWSIZE  = a_awsize;
        axi_to_bridge[0].AWBURST = a_awburst;
        a_awready         = axi_to_bridge[0].AWREADY;

        axi_to_bridge[0].WVALID = a_wvalid;
        axi_to_bridge[0].WDATA  = a_wdata;
        axi_to_bridge[0].WSTRB  = a_kalstrb;
        axi_to_bridge[0].WLAST  = a_wlast;
        a_wready         = axi_to_bridge[0].WREADY;
        
        a_bvalid = axi_to_bridge[0].BVALID;
        a_bid    = axi_to_bridge[0].BID;
        axi_to_bridge[0].BREADY = a_bready;
        
        axi_to_bridge[0].ARVALID = a_arvalid;
        axi_to_bridge[0].ARID    = a_arid;
        axi_to_bridge[0].ARADDR  = a_araddr;
        axi_to_bridge[0].ARLEN   = a_arlen;
        axi_to_bridge[0].ARSIZE  = a_arsize;
        axi_to_bridge[0].ARBURST = a_arburst;
        a_arready         = axi_to_bridge[0].ARREADY;

        a_rvalid = axi_to_bridge[0].RVALID;
        a_rid    = axi_to_bridge[0].RID;
        a_rdata  = axi_to_bridge[0].RDATA;
        a_rlast  = axi_to_bridge[0].RLAST;
        axi_to_bridge[0].RREADY = a_rready;

        
        axi_to_bridge[1].AWVALID = b_awvalid;
        axi_to_bridge[1].AWID    = b_awid;
        axi_to_bridge[1].AWADDR  = b_awaddr;
        axi_to_bridge[1].AWLEN   = b_awlen;
        axi_to_bridge[1].AWSIZE  = b_awsize;
        axi_to_bridge[1].AWBURST = b_awburst;
        b_awready         = axi_to_bridge[1].AWREADY;

        axi_to_bridge[1].WVALID = b_wvalid;
        axi_to_bridge[1].WDATA  = b_wdata;
        axi_to_bridge[1].WSTRB  = b_kalstrb;
        axi_to_bridge[1].WLAST  = b_wlast;
        b_wready         = axi_to_bridge[1].WREADY;
        
        b_bvalid = axi_to_bridge[1].BVALID;
        b_bid    = axi_to_bridge[1].BID;
        axi_to_bridge[1].BREADY = b_bready;
        
        axi_to_bridge[1].ARVALID = b_arvalid;
        axi_to_bridge[1].ARID    = b_arid;
        axi_to_bridge[1].ARADDR  = b_araddr;
        axi_to_bridge[1].ARLEN   = b_arlen;
        axi_to_bridge[1].ARSIZE  = b_arsize;
        axi_to_bridge[1].ARBURST = b_arburst;
        b_arready         = axi_to_bridge[1].ARREADY;

        b_rvalid = axi_to_bridge[1].RVALID;
        b_rid    = axi_to_bridge[1].RID;
        b_rdata  = axi_to_bridge[1].RDATA;
        b_rlast  = axi_to_bridge[1].RLAST;
        axi_to_bridge[1].RREADY = b_rready;
    end

    axi2axis #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(ADDR_WIDTH),
        .AXI_ID_W_WIDTH(ID_W_WIDTH),
        .AXI_ID_R_WIDTH(ID_R_WIDTH),

        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH(ID_WIDTH),
        .AXIS_DEST_WIDTH(DEST_WIDTH),
        .AXIS_USER_WIDTH(USER_WIDTH)
    ) dut_left (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_if_i      (axi_to_bridge[0]),
        .m_axi_if_o      (axi_to_ram[0]),

        .s_axis_if_req_i (axis_ifs[1]),
        .m_axis_if_req_o (axis_ifs[0]),
        .s_axis_if_resp_i(axis_ifs[3]),
        .m_axis_if_resp_o(axis_ifs[2])
    ), dut_right (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_if_i      (axi_to_bridge[1]),
        .m_axi_if_o      (axi_to_ram[1]),

        .s_axis_if_req_i (axis_ifs[0]),
        .m_axis_if_req_o (axis_ifs[1]),
        .s_axis_if_resp_i(axis_ifs[2]),
        .m_axis_if_resp_o(axis_ifs[3])
    );

    axi_ram #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(ADDR_WIDTH),
        .AXI_ID_W_WIDTH(ID_W_WIDTH),
        .AXI_ID_R_WIDTH(ID_R_WIDTH)
    )   ram_left (
        .clk_i(aclk),
        .rst_n_i(aresetn),

        .s_axi_i(axi_to_ram[0])
    ),  ram_right (
        .clk_i(aclk),
        .rst_n_i(aresetn),

        .s_axi_i(axi_to_ram[1])
    );
    
endmodule