`timescale 1ns/1ps

module tb_torus_parallel (
    input aresetn,

    output logic awready[25],
    input  logic awvalid[25],
    input  logic [4:0] awid[25],
    input  logic [11:0] awaddr[25],
    input  logic [7:0] awlen[25],
    input  logic [2:0] awsize[25],
    input  logic [1:0] awburst[25],

    output logic wready[25],
    input  logic wvalid[25],
    input  logic [7:0] wdata[25],
    input  logic wstrb[25],
    input  logic wlast[25],

    output logic bvalid[25],
    output logic [4:0] bid[25],
    input  logic bready[25],

    output logic arready[25],
    input  logic arvalid[25],
    input  logic [4:0] arid[25],
    input  logic [11:0] araddr[25],
    input  logic [7:0] arlen[25],
    input  logic [2:0] arsize[25],
    input  logic [1:0] arburst[25],

    output logic rvalid[25],
    output logic [4:0] rid[25],
    output logic [7:0] rdata[25],
    output logic rlast[25],
    input  logic rready[25]
    
);

    axi_if axi_if[25](), axi_if_ram[25]();

    logic aclk;

    always #1 aclk = ~aclk;

    initial begin
        aclk = 1;
    end

    generate
        for (genvar i = 0; i < 25; i++) begin : map_wires
            always_comb begin
                axi_if[i].AWVALID = awvalid[i];
                axi_if[i].AWID    = awid[i];
                axi_if[i].AWADDR  = awaddr[i];
                axi_if[i].AWLEN   = awlen[i];
                axi_if[i].AWSIZE  = awsize[i];
                axi_if[i].AWBURST = awburst[i];
                awready[i]     = axi_if[i].AWREADY;

                axi_if[i].WVALID = wvalid[i];
                axi_if[i].WDATA  = wdata[i];
                axi_if[i].WSTRB  = wstrb[i];
                axi_if[i].WLAST  = wlast[i];
                wready[i]     = axi_if[i].WREADY;
                
                bvalid[i]     = axi_if[i].BVALID;
                bid[i]        = axi_if[i].BID;
                axi_if[i].BREADY = bready[i];
                
                axi_if[i].ARVALID = arvalid[i];
                axi_if[i].ARID    = arid[i];
                axi_if[i].ARADDR  = araddr[i];
                axi_if[i].ARLEN   = arlen[i];
                axi_if[i].ARSIZE  = arsize[i];
                axi_if[i].ARBURST = arburst[i];
                arready[i]     = axi_if[i].ARREADY;

                rvalid[i]     = axi_if[i].RVALID;
                rid[i]        = axi_if[i].RID;
                rdata[i]      = axi_if[i].RDATA;
                rlast[i]      = axi_if[i].RLAST;
                axi_if[i].RREADY = rready[i];
            end

            

        end
    endgenerate

    torus #(
        .AXI_ADDR_WIDTH(12),
        .BUFFER_DEPTH(4),

        .ALGORITHM("EWn_SNe"),
        .SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING(1)
    ) dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_i(axi_if),
        .m_axi_o(axi_if_ram)
    );

    
    generate
        for (genvar i = 0; i < 25; i++) begin : map_rams
            axi_ram #(.AXI_ADDR_WIDTH(12)) ram (
                .clk_i     (aclk),
                .rst_n_i   (aresetn),
                .s_axi_i   (axi_if_ram[i])
            );
            
            initial begin
                for (int j = 0; j < 2**16; j++) begin
                    ram.coupled_ram.ram[j] = $urandom();
                end
            end
        end

    endgenerate

endmodule