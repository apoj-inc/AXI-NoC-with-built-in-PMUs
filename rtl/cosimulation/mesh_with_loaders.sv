`include "defines.svh"

module mesh_with_loaders
import axi_type::*;
#(
    parameter AXI_MASTER_LOADER_FIFO_DEPTH = 64,

    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),

    parameter N = MAX_ROUTERS_X*MAX_ROUTERS_Y,
    parameter MAX_ID_WIDTH = (ID_W_WIDTH > ID_R_WIDTH) ? ID_W_WIDTH : ID_R_WIDTH
) (
    input  logic                      aclk,
    input  logic                      aresetn,

    input  logic                      pmu_enable_i,
    input  logic [4:0]                pmu_addr_i   [N],
    output logic [31:0]               pmu_data_o   [N],

    input  logic                      resp_wait_i  [N],
    input  logic [MAX_ID_WIDTH-1:0]   id_i         [N],
    input  logic                      write_i      [N],
    input  logic [ADDR_WIDTH-1:0]     axaddr_i     [N],
    input  logic [7:0]                axlen_i      [N],
    input  logic [AXI_DATA_WIDTH-1:0] wdata_i      [N],
    input  logic [AXI_DATA_BYTES-1:0] wstrb_i      [N],
    input  logic                      fifo_push_i  [N],
    input  logic                      start_i,
    output logic                      idle_o       [N],
    output logic [AXI_DATA_WIDTH-1:0] rdata_o      [N]
);

    axi_mosi_t axi_mosi[N];
    axi_miso_t axi_miso[N];

    axi_mosi_t axi_mosi_ram[N];
    axi_miso_t axi_miso_ram[N];

    generate
        genvar i;
        for (i = 0; i < N; i++) begin : map_wires

            axi_pmu pmu (
                .aclk         (aclk),
                .aresetn      (aresetn),
                .enable       (pmu_enable_i),
                .mon_axi_miso (axi_miso[i]),
                .mon_axi_mosi (axi_mosi[i]),
                .addr_i       (pmu_addr_i[i]),
                .data_o       (pmu_data_o[i])
            );

            axi_master_loader #(
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
                .m_axi_i     (axi_miso[i]),
                .m_axi_o     (axi_mosi[i])
            );
        end
    endgenerate

    XY_mesh_dual_parallel #(
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_X_WIDTH(MAX_ROUTERS_X_WIDTH),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .MAX_ROUTERS_Y_WIDTH(MAX_ROUTERS_Y_WIDTH)
    ) dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_i(axi_mosi),
        .s_axi_o(axi_miso),

        .m_axi_i(axi_miso_ram),
        .m_axi_o(axi_mosi_ram)
    );

    axi_ram #(
        .BYTE_WIDTH(8)
    ) ram[N] (
        .clk_i({N{aclk}}),
        .rst_n_i({N{aresetn}}),
        .in_mosi_i(axi_mosi_ram),
        .in_miso_o(axi_miso_ram)
    );
    
endmodule