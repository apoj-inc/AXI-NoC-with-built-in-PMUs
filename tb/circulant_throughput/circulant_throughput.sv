`timescale 1ns/1ps

module circulant_throughput #(
    parameter     AXI_DATA_WIDTH               = 8 ,
    parameter     AXI_ADDR_WIDTH               = 12,
    parameter     ROUTERS_COUNT                = 9 ,
    parameter     GENERATICS_COUNT             = 2 ,
    parameter int GENERATICS[GENERATICS_COUNT] = '{3, 1},

    parameter AXI_MAX_ID_WIDTH = $clog2(ROUTERS_COUNT+1),
    parameter AXI_DATA_BYTES   = AXI_DATA_WIDTH / 8         
) (
    input aresetn,

    output logic                        awready[ROUTERS_COUNT],
    input  logic                        awvalid[ROUTERS_COUNT],
    input  logic [AXI_MAX_ID_WIDTH-1:0] awid   [ROUTERS_COUNT],
    input  logic [AXI_ADDR_WIDTH-1:0]   awaddr [ROUTERS_COUNT],
    input  logic [7:0]                  awlen  [ROUTERS_COUNT],
    input  logic [2:0]                  awsize [ROUTERS_COUNT],
    input  logic [1:0]                  awburst[ROUTERS_COUNT],

    output logic                        wready [ROUTERS_COUNT],
    input  logic                        wvalid [ROUTERS_COUNT],
    input  logic [AXI_DATA_WIDTH-1:0]   wdata  [ROUTERS_COUNT],
    input  logic [AXI_DATA_BYTES-1:0]   wstrb  [ROUTERS_COUNT],
    input  logic                        wlast  [ROUTERS_COUNT],

    output logic                        bvalid [ROUTERS_COUNT],
    output logic [AXI_MAX_ID_WIDTH-1:0] bid    [ROUTERS_COUNT],
    input  logic                        bready [ROUTERS_COUNT],

    output logic                        arready[ROUTERS_COUNT],
    input  logic                        arvalid[ROUTERS_COUNT],
    input  logic [AXI_MAX_ID_WIDTH-1:0] arid   [ROUTERS_COUNT],
    input  logic [AXI_ADDR_WIDTH-1:0]   araddr [ROUTERS_COUNT],
    input  logic [7:0]                  arlen  [ROUTERS_COUNT],
    input  logic [2:0]                  arsize [ROUTERS_COUNT],
    input  logic [1:0]                  arburst[ROUTERS_COUNT],

    output logic                        rvalid [ROUTERS_COUNT],
    output logic [AXI_MAX_ID_WIDTH-1:0] rid    [ROUTERS_COUNT],
    output logic [AXI_DATA_WIDTH-1:0]   rdata  [ROUTERS_COUNT],
    output logic                        rlast  [ROUTERS_COUNT],
    input  logic                        rready [ROUTERS_COUNT]
    
);

    logic aclk;

    always #10 aclk = ~aclk;

    initial begin
        aclk = 1;
    end

    axi_if #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH  ),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH  ),
        .AXI_ID_R_WIDTH(AXI_MAX_ID_WIDTH),
        .AXI_ID_W_WIDTH(AXI_MAX_ID_WIDTH)
    ) axi_if[ROUTERS_COUNT](), axi_if_ram[ROUTERS_COUNT]();

    generate
        for (genvar i = 0; i < ROUTERS_COUNT; i++) begin : map_wires
            always_comb begin
                axi_if[i].AWVALID = awvalid[i];
                axi_if[i].AWID    = awid[i];
                axi_if[i].AWADDR  = awaddr[i];
                axi_if[i].AWLEN   = awlen[i];
                axi_if[i].AWSIZE  = awsize[i];
                axi_if[i].AWBURST = awburst[i];
                awready[i]        = axi_if[i].AWREADY;

                axi_if[i].WVALID  = wvalid[i];
                axi_if[i].WDATA   = wdata[i];
                axi_if[i].WSTRB   = wstrb[i];
                axi_if[i].WLAST   = wlast[i];
                wready[i]         = axi_if[i].WREADY;

                bvalid[i]         = axi_if[i].BVALID;
                bid[i]            = axi_if[i].BID;
                axi_if[i].BREADY  = bready[i];
                
                axi_if[i].ARVALID = arvalid[i];
                axi_if[i].ARID    = arid[i];
                axi_if[i].ARADDR  = araddr[i];
                axi_if[i].ARLEN   = arlen[i];
                axi_if[i].ARSIZE  = arsize[i];
                axi_if[i].ARBURST = arburst[i];
                arready[i]        = axi_if[i].ARREADY;

                rvalid[i]         = axi_if[i].RVALID;
                rid[i]            = axi_if[i].RID;
                rdata[i]          = axi_if[i].RDATA;
                rlast[i]          = axi_if[i].RLAST;
                axi_if[i].RREADY  = rready[i];

            end

            axi_pmu pmu (
                .aclk         (aclk),
                .aresetn      (aresetn),
                .mon_axi_i    (axi_if[i]),

                .enable       ('1)
            );
        end
    endgenerate

    circulant #(
        .AXI_DATA_WIDTH   (AXI_DATA_WIDTH  ),
        .AXI_ADDR_WIDTH   (AXI_ADDR_WIDTH  ),
        .AXI_ID_R_WIDTH   (AXI_MAX_ID_WIDTH),
        .AXI_ID_W_WIDTH   (AXI_MAX_ID_WIDTH),

        .ROUTERS_COUNT    (ROUTERS_COUNT    ),
        .GENERATICS_COUNT (GENERATICS_COUNT ),
        .GENERATICS       (GENERATICS       ),
        .ALGORITHM        ("Greedy"         ),

        .VIRTUAL_CHANNEL_NUMBER(2),
        .VIRTUAL_NETWORKS('{1, 1}),
        .BUFFER_ALLOCATOR("KeepInNetwork"),
        .SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING(1)
    ) dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_i(axi_if),
        .m_axi_o(axi_if_ram)
    );

    generate
        for (genvar i = 0; i < ROUTERS_COUNT; i++) begin : map_rams
            axi_ram #(
                .AXI_DATA_WIDTH(AXI_DATA_WIDTH  ),
                .AXI_ID_W_WIDTH(AXI_MAX_ID_WIDTH),
                .AXI_ID_R_WIDTH(AXI_MAX_ID_WIDTH),
                .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH  )
            ) ram (
                .clk_i     (aclk),
                .rst_n_i   (aresetn),
                .s_axi_i   (axi_if_ram[i])
            );
            
            initial begin
                for (int j = 0; j < (2**AXI_ADDR_WIDTH)/AXI_DATA_BYTES; j++) begin
                    ram.coupled_ram.ram[j] = $urandom();
                end
            end
        end

    endgenerate
    
endmodule