`timescale 1ns/1ps

module throughput_wrapper (
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

    logic aclk;

    always #1 aclk = ~aclk;

    initial begin
        aclk = 1;
    end

    axi_if #(
        .DATA_WIDTH(8),
        .ID_W_WIDTH(5),
        .ID_R_WIDTH(5)
    ) axi[16](), axi_ram[16]();

    generate
        for (genvar i = 0; i < 16; i++) begin : map_wires
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

            axi_pmu pmu (
                .aclk    (aclk),
                .aresetn (aresetn),
                .mon_axi (axi[i])
            );
        end
    endgenerate

    XY_mesh_dual_parallel dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_in(axi),
        .m_axi_out(axi_ram)
    );

    generate
        for (genvar i = 0; i < 16; i++) begin : map_rams
            axi_ram #(
                .DATA_WIDTH(8),
                .ID_W_WIDTH(5),
                .ID_R_WIDTH(5)
            ) ram (
                .clk(aclk),
                .rst_n(aresetn),
                .axi_s(axi_ram[i])
            );
            
            initial begin
                for (int j = 0; j < 2**16; j++) begin
                    ram.generate_rams[0].coupled_ram.ram[j] = $urandom();
                end
            end
        end

    endgenerate
    
endmodule