module tb_router (
    input aclk,
    input aresetn,

    output logic awready[5],
    input  logic awvalid[5],
    input  logic [3:0] awid[5],
    input  logic [15:0] awaddr[5],
    input  logic [7:0] awlen[5],
    input  logic [2:0] awsize[5],
    input  logic [1:0] awburst[5],

    output logic wready[5],
    input  logic wvalid[5],
    input  logic [31:0] wdata[5],
    input  logic [3:0] wstrb[5],
    input  logic wlast[5],

    output logic bvalid[5],
    output logic [3:0] bid[5],
    input  logic bready[5],

    output logic arready[5],
    input  logic arvalid[5],
    input  logic [3:0] arid[5],
    input  logic [15:0] araddr[5],
    input  logic [7:0] arlen[5],
    input  logic [2:0] arsize[5],
    input  logic [1:0] arburst[5],

    output logic rvalid[5],
    output logic [3:0] rid[5],
    output logic [31:0] rdata[5],
    output logic rlast[5],
    input  logic rready[5]
    
);
    axi_if axi[5](), axi_ram[5]();
    axis_if #(.DATA_WIDTH(40)) axis_to_q[5](), axis_from_q[5]();

    generate
        for (genvar i = 0; i < 5; i++) begin : map_wires
            always_comb begin
                axi[i].AWVALID = awvalid[i];
                axi[i].AWID    = awid[i];
                axi[i].AWADDR  = awaddr[i];
                axi[i].AWLEN   = awlen[i];
                axi[i].AWSIZE  = awsize[i];
                axi[i].AWBURST = awburst[i];
                awready[i]     = axi[i].AWREADY;

                axi[i].WVALID = wvalid[i];
                axi[i].WDATA  = wdata[i];
                axi[i].WSTRB  = wstrb[i];
                axi[i].WLAST  = wlast[i];
                wready[i]     = axi[i].WREADY;
                
                bvalid[i]     = axi[i].BVALID;
                bid[i]        = axi[i].BID;
                axi[i].BREADY = bready[i];
                
                axi[i].ARVALID = arvalid[i];
                axi[i].ARID    = arid[i];
                axi[i].ARADDR  = araddr[i];
                axi[i].ARLEN   = arlen[i];
                axi[i].ARSIZE  = arsize[i];
                axi[i].ARBURST = arburst[i];
                arready[i]     = axi[i].ARREADY;

                rvalid[i]     = axi[i].RVALID;
                rid[i]        = axi[i].RID;
                rdata[i]      = axi[i].RDATA;
                rlast[i]      = axi[i].RLAST;
                axi[i].RREADY = rready[i];
            end
        end
    endgenerate

    parameter integer kal_x[5] = '{1, 1, 2, 1, 0};
    parameter integer kal_y[5] = '{1, 0, 1, 2, 1};

    generate
        for (genvar i = 0; i < 5; i++) begin
            axi2axis_XY #(
                .ROUTER_X(kal_x[i]),
                .ROUTER_Y(kal_y[i]),
                .MAX_ROUTERS_X(3),
                .MAX_ROUTERS_Y(3)
            ) bridges (
                .ACLK(aclk),
                .ARESETn(aresetn),
                
                .s_axi_in(axi[i]),
                .m_axi_out(axi_ram[i]),
                
                .s_axis_in(axis_from_q[i]),
                .m_axis_out(axis_to_q[i])
            );
        end
    endgenerate

    axi_ram ram_left[5] (
        .clk({5{aclk}}),
        .rst_n({5{aresetn}}),
        .axi_s(axi_ram)
    );

    router #(
        .DATA_WIDTH(40),
        .ROUTER_X(1),
        .ROUTER_Y(1),
        .MAX_ROUTERS_X(3),
        .MAX_ROUTERS_Y(3)
    ) router (
        .clk(aclk),
        .rst_n(aresetn),

        .in(axis_to_q),
        .out(axis_from_q)
    );
    
endmodule