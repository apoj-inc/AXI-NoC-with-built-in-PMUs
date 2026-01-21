`include "defines.svh"
`include "axi2axis_typedef.svh"

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

    axi_mosi_t axi_mosi[5], axi_ram_mosi[5];
    axi_miso_t axi_miso[5], axi_ram_miso[5];

    axis_miso_t axis_miso_to_q[5], axis_miso_from_q[5];
    axis_mosi_t axis_mosi_to_q[5], axis_mosi_from_q[5];

    generate
        for (genvar i = 0; i < 5; i++) begin : map_wires
            always_comb begin
                axi_mosi[i].AWVALID = awvalid[i];
                axi_mosi[i].data.aw.AWID    = awid[i];
                axi_mosi[i].data.aw.AWADDR  = awaddr[i];
                axi_mosi[i].data.aw.AWLEN   = awlen[i];
                axi_mosi[i].data.aw.AWSIZE  = awsize[i];
                axi_mosi[i].data.aw.AWBURST = awburst[i];
                awready[i]     = axi_miso[i].AWREADY;

                axi_mosi[i].WVALID = wvalid[i];
                axi_mosi[i].data.w.WDATA  = wdata[i];
                axi_mosi[i].data.w.WSTRB  = wstrb[i];
                axi_mosi[i].data.w.WLAST  = wlast[i];
                wready[i]     = axi_miso[i].WREADY;
                
                bvalid[i]     = axi_miso[i].BVALID;
                bid[i]        = axi_miso[i].data.b.BID;
                axi_mosi[i].BREADY = bready[i];
                
                axi_mosi[i].ARVALID = arvalid[i];
                axi_mosi[i].data.ar.ARID    = arid[i];
                axi_mosi[i].data.ar.ARADDR  = araddr[i];
                axi_mosi[i].data.ar.ARLEN   = arlen[i];
                axi_mosi[i].data.ar.ARSIZE  = arsize[i];
                axi_mosi[i].data.ar.ARBURST = arburst[i];
                arready[i]     = axi_miso[i].ARREADY;

                rvalid[i]     = axi_miso[i].RVALID;
                rid[i]        = axi_miso[i].data.r.RID;
                rdata[i]      = axi_miso[i].data.r.RDATA;
                rlast[i]      = axi_miso[i].data.r.RLAST;
                axi_mosi[i].RREADY = rready[i];
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

                .s_axi_i(axi_mosi[i]),
                .s_axi_o(axi_miso[i]),

                .m_axi_i(axi_ram_miso[i]),
                .m_axi_o(axi_ram_mosi[i]),

                .s_axis_req_i(axis_mosi_from_q[i]),
                .s_axis_req_o(axis_miso_from_q[i]),

                .m_axis_req_i(axis_miso_to_q[i]),
                .m_axis_req_o(axis_mosi_to_q[i])
            );
        end
    endgenerate

    axi_ram ram_left[5] (
        .clk_i({5{aclk}}),
        .rst_n_i({5{aresetn}}),
        
        .in_mosi_i(axi_ram_mosi),
        .in_miso_o(axi_ram_miso)
    );

    router #(
        .ROUTER_X(1),
        .ROUTER_Y(1),
        .MAX_ROUTERS_X(3),
        .MAX_ROUTERS_Y(3)
    ) router (
        .clk_i(aclk),
        .rst_n_i(aresetn),

        .in_mosi_i(axis_mosi_to_q),
        .in_miso_o(axis_miso_to_q),

        .out_miso_i(axis_miso_from_q),
        .out_mosi_o(axis_mosi_from_q)
    );
    
endmodule