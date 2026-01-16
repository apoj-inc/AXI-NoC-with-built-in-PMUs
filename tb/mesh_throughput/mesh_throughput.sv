`timescale 1ns/1ps

module mesh_throughput (
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

    `include "axi_type.svh"

    logic aclk;

    always #1 aclk = ~aclk;

    initial begin
        aclk = 1;
    end

    axi_mosi_t mosi[16], mosi_ram[16];
    axi_miso_t miso[16], miso_ram[16];

    generate
        for (genvar i = 0; i < 16; i++) begin : map_wires
            always_comb begin
                mosi[i].AWVALID         = awvalid[i];
                mosi[i].data.aw.AWID    = awid[i];
                mosi[i].data.aw.AWADDR  = awaddr[i];
                mosi[i].data.aw.AWLEN   = awlen[i];
                mosi[i].data.aw.AWSIZE  = awsize[i];
                mosi[i].data.aw.AWBURST = awburst[i];
                awready[i]              = miso[i].AWREADY;

                mosi[i].WVALID        = wvalid[i];
                mosi[i].data.w.WDATA  = wdata[i];
                mosi[i].data.w.WSTRB  = wstrb[i];
                mosi[i].data.w.WLAST  = wlast[i];
                wready[i]             = miso[i].WREADY;

                bvalid[i]      = miso[i].BVALID;
                bid[i]         = miso[i].data.b.BID;
                mosi[i].BREADY = bready[i];
                
                mosi[i].ARVALID         = arvalid[i];
                mosi[i].data.ar.ARID    = arid[i];
                mosi[i].data.ar.ARADDR  = araddr[i];
                mosi[i].data.ar.ARLEN   = arlen[i];
                mosi[i].data.ar.ARSIZE  = arsize[i];
                mosi[i].data.ar.ARBURST = arburst[i];
                arready[i]              = miso[i].ARREADY;

                rvalid[i]      = miso[i].RVALID;
                rid[i]         = miso[i].data.r.RID;
                rdata[i]       = miso[i].data.r.RDATA;
                rlast[i]       = miso[i].data.r.RLAST;
                mosi[i].RREADY = rready[i];

            end

            axi_pmu pmu (
                .aclk         (aclk),
                .aresetn      (aresetn),
                .mon_axi_miso (miso[i]),
                .mon_axi_mosi (mosi[i])
            );
        end
    endgenerate

    XY_mesh_dual_parallel dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_i(mosi),
        .s_axi_o(miso),
        .m_axi_i(miso_ram),
        .m_axi_o(mosi_ram)
    );

    generate
        for (genvar i = 0; i < 16; i++) begin : map_rams
            axi_ram #(
                .AXI_DATA_WIDTH(32),
                .ID_W_WIDTH(5),
                .ID_R_WIDTH(5)
            ) ram (
                .clk_i     (aclk),
                .rst_n_i   (aresetn),
                .in_mosi_i (mosi_ram[i]),
                .in_miso_o (miso_ram[i])
            );
            
            initial begin
                for (int j = 0; j < 2**16; j++) begin
                    ram.coupled_ram.ram[j] = $urandom();
                end
            end
        end

    endgenerate
    
endmodule