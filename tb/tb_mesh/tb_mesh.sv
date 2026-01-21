`timescale 1ns/1ps

module tb_mesh (
    input aresetn,

    output logic awready[16],
    input  logic awvalid[16],
    input  logic [4:0] awid[16],
    input  logic [15:0] awaddr[16],
    input  logic [7:0] awlen[16],
    input  logic [2:0] awsize[16],
    input  logic [1:0] awburst[16],

    output logic wready[16],
    input  logic wvalid[16],
    input  logic [7:0] wdata[16],
    input  logic wstrb[16],
    input  logic wlast[16],

    output logic bvalid[16],
    output logic [4:0] bid[16],
    input  logic bready[16],

    output logic arready[16],
    input  logic arvalid[16],
    input  logic [4:0] arid[16],
    input  logic [15:0] araddr[16],
    input  logic [7:0] arlen[16],
    input  logic [2:0] arsize[16],
    input  logic [1:0] arburst[16],

    output logic rvalid[16],
    output logic [4:0] rid[16],
    output logic [7:0] rdata[16],
    output logic rlast[16],
    input  logic rready[16]
    
);

    axi_miso_t axi_miso_mesh[16];
    axi_mosi_t axi_mosi_mesh[16];

    axi_miso_t axi_miso_ram[16];
    axi_mosi_t axi_mosi_ram[16];

    logic aclk;

    always #1 aclk = ~aclk;

    initial begin
        aclk = 1;
    end

    generate
        for (genvar i = 0; i < 16; i++) begin : map_wires
            always_comb begin
                axi_mosi_mesh[i].AWVALID = awvalid[i];
                axi_mosi_mesh[i].data.aw.AWID    = awid[i];
                axi_mosi_mesh[i].data.aw.AWADDR  = awaddr[i];
                axi_mosi_mesh[i].data.aw.AWLEN   = awlen[i];
                axi_mosi_mesh[i].data.aw.AWSIZE  = awsize[i];
                axi_mosi_mesh[i].data.aw.AWBURST = awburst[i];
                awready[i]     = axi_miso_mesh[i].AWREADY;

                axi_mosi_mesh[i].WVALID = wvalid[i];
                axi_mosi_mesh[i].data.w.WDATA  = wdata[i];
                axi_mosi_mesh[i].data.w.WSTRB  = wstrb[i];
                axi_mosi_mesh[i].data.w.WLAST  = wlast[i];
                wready[i]     = axi_miso_mesh[i].WREADY;
                
                bvalid[i]     = axi_miso_mesh[i].BVALID;
                bid[i]        = axi_miso_mesh[i].data.b.BID;
                axi_mosi_mesh[i].BREADY = bready[i];
                
                axi_mosi_mesh[i].ARVALID = arvalid[i];
                axi_mosi_mesh[i].data.ar.ARID    = arid[i];
                axi_mosi_mesh[i].data.ar.ARADDR  = araddr[i];
                axi_mosi_mesh[i].data.ar.ARLEN   = arlen[i];
                axi_mosi_mesh[i].data.ar.ARSIZE  = arsize[i];
                axi_mosi_mesh[i].data.ar.ARBURST = arburst[i];
                arready[i]     = axi_miso_mesh[i].ARREADY;

                rvalid[i]     = axi_miso_mesh[i].RVALID;
                rid[i]        = axi_miso_mesh[i].data.r.RID;
                rdata[i]      = axi_miso_mesh[i].data.r.RDATA;
                rlast[i]      = axi_miso_mesh[i].data.r.RLAST;
                axi_mosi_mesh[i].RREADY = rready[i];
            end

            

        end
    endgenerate

    XY_mesh_dual dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_i(axi_mosi_mesh),
        .s_axi_o(axi_miso_mesh),

        .m_axi_i(axi_miso_ram),
        .m_axi_o(axi_mosi_ram)

    );

    axi_ram #(
        .ID_W_WIDTH(5),
        .ID_R_WIDTH(5),
        .AXI_DATA_WIDTH(8)
    ) ram[16] (
        .clk_i({16{aclk}}),
        .rst_n_i({16{aresetn}}),

        .in_mosi_i(axi_mosi_ram),
        .in_miso_o(axi_miso_ram)
        );
    
endmodule