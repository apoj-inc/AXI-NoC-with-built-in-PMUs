`include "defines.svh"

import axi2axis_XY_pkg::*;
import axi_type_pkg::*;

module mesh_with_loaders #(
    parameter AXI_MASTER_LOADER_FIFO_DEPTH = 64
) (
    input  logic                      aclk,
    input  logic                      aresetn,

    input  logic                      pmu_enable_i,
    input  logic [4:0]                pmu_addr_i   [CORE_COUNT],
    output logic [31:0]               pmu_data_o   [CORE_COUNT],

    input  logic                      resp_wait_i  [CORE_COUNT],
    input  logic [MAX_ID_WIDTH-1:0]   id_i         [CORE_COUNT],
    input  logic                      write_i      [CORE_COUNT],
    input  logic [ADDR_WIDTH-1:0]     axaddr_i     [CORE_COUNT],
    input  logic [7:0]                axlen_i      [CORE_COUNT],
    input  logic [AXI_DATA_WIDTH-1:0] wdata_i      [CORE_COUNT],
    input  logic [AXI_DATA_BYTES-1:0] wstrb_i      [CORE_COUNT],
    input  logic                      fifo_push_i  [CORE_COUNT],
    input  logic                      start_i,
    output logic                      idle_o       [CORE_COUNT],
    output logic [AXI_DATA_WIDTH-1:0] rdata_o      [CORE_COUNT]
);

    axi_mosi_t axi_mosi[CORE_COUNT];
    axi_miso_t axi_miso[CORE_COUNT];

    axi_mosi_t axi_mosi_ram[CORE_COUNT];
    axi_miso_t axi_miso_ram[CORE_COUNT];

    generate
        genvar i;
        for (i = 0; i < CORE_COUNT; i++) begin : map_wires

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
    ) ram[CORE_COUNT] (
        .clk_i({CORE_COUNT{aclk}}),
        .rst_n_i({CORE_COUNT{aresetn}}),
        .in_mosi_i(axi_mosi_ram),
        .in_miso_o(axi_miso_ram)
    );
    
endmodule