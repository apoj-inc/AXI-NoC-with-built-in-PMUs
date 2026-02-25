`include "defines.svh"

module mesh_with_loaders # (
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ID_W_WIDTH = 5,
    parameter AXI_ID_R_WIDTH = 5,
    parameter AXI_ADDR_WIDTH = 16,
    
    parameter AXIS_DATA_WIDTH = 40,
    parameter AXIS_ID_WIDTH = 4,
    parameter AXIS_DEST_WIDTH = 4,
    parameter AXIS_USER_WIDTH = 4,
    
    parameter AXI_MASTER_LOADER_FIFO_DEPTH = 64,

    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_Y = 4,

    parameter N = MAX_ROUTERS_X*MAX_ROUTERS_Y,

    parameter MAX_ROUTERS_X_WIDTH = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y_WIDTH = $clog2(MAX_ROUTERS_Y),

    parameter BUFFER_DEPTH = 16,

    parameter AXI_MAX_ID_WIDTH = (AXI_ID_W_WIDTH > AXI_ID_R_WIDTH) ? AXI_ID_W_WIDTH : AXI_ID_R_WIDTH,

    parameter AXI_DATA_BYTES = AXI_DATA_WIDTH / 8 + (AXI_DATA_WIDTH % 8 != 0)
) (
    input  logic                        aclk,
    input  logic                        aresetn,

    input  logic                        pmu_enable_i,
    input  logic [4:0]                  pmu_addr_i   [N],
    output logic [31:0]                 pmu_data_o   [N],

    input  logic                        resp_wait_i  [N],
    input  logic [AXI_MAX_ID_WIDTH-1:0] id_i         [N],
    input  logic                        write_i      [N],
    input  logic [AXI_ADDR_WIDTH-1:0]   axaddr_i     [N],
    input  logic [7:0]                  axlen_i      [N],
    input  logic [AXI_DATA_WIDTH-1:0]   wdata_i      [N],
    input  logic [AXI_DATA_BYTES-1:0]   wstrb_i      [N],
    input  logic                        fifo_push_i  [N],
    input  logic                        start_i,
    output logic                        idle_o       [N],
    output logic [AXI_DATA_WIDTH-1:0]   rdata_o      [N]
);

    axi_if #(
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_ID_W_WIDTH (AXI_ID_W_WIDTH),
        .AXI_ID_R_WIDTH (AXI_ID_R_WIDTH)
    ) axi_if_loader_noc [N](), axi_if_noc_ram [N]();

    generate
        genvar i;
        for (i = 0; i < N; i++) begin : map_wires

            axi_pmu #(
                .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
                .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
                .AXI_ID_R_WIDTH (AXI_ID_R_WIDTH),
                .AXI_ID_W_WIDTH (AXI_ID_W_WIDTH)
            ) pmu (
                .aclk         (aclk),
                .aresetn      (aresetn),
                .enable       (pmu_enable_i),
                .mon_axi_i    (axi_if_loader_noc[i]),
                .addr_i       (pmu_addr_i[i]),
                .data_o       (pmu_data_o[i])
            );

            axi_master_loader #(
                .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
                .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
                .AXI_ID_W_WIDTH(AXI_ID_W_WIDTH),
                .AXI_ID_R_WIDTH(AXI_ID_R_WIDTH),
                .FIFO_DEPTH(AXI_MASTER_LOADER_FIFO_DEPTH),
                .LOADER_ID(i)
            ) loader (
                .clk_i       (aclk),
                .arstn_i     (aresetn),
                .resp_wait_i (resp_wait_i[i]),
                .id_i        (id_i[i]),
                .write_i     (write_i[i]),
                .axaddr_i    (axaddr_i[i]),
                .axlen_i     (axlen_i[i]),
                .wdata_i     (wdata_i[i]),
                .wstrb_i     (wstrb_i[i]),
                .fifo_push_i (fifo_push_i[i]),
                .start_i     (start_i),
                .idle_o      (idle_o[i]),
                .rdata_o     (rdata_o[i]),
                .m_axi_if_o  (axi_if_loader_noc[i])
            );

            axi_ram #(
                .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
                .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
                .AXI_ID_W_WIDTH (AXI_ID_W_WIDTH),
                .AXI_ID_R_WIDTH (AXI_ID_R_WIDTH),
                .BYTE_WIDTH(8)
            ) ram (
                .clk_i(aclk),
                .rst_n_i(aresetn),
                .s_axi_i(axi_if_noc_ram[i])
            );
        end
    endgenerate

    XY_mesh_dual_parallel #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_ID_W_WIDTH(AXI_ID_W_WIDTH),
        .AXI_ID_R_WIDTH(AXI_ID_R_WIDTH),
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
        .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH(AXIS_USER_WIDTH),

        .BUFFER_DEPTH(BUFFER_DEPTH)

        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y)
    ) dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_i(axi_if_loader_noc),
        .m_axi_o(axi_if_noc_ram)
    );
    
endmodule