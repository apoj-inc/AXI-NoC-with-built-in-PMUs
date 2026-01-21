`include "defines.svh"

module mesh_with_loaders # (
    parameter ID_W_WIDTH = 5,
    parameter ID_R_WIDTH = 5,
    parameter MAX_ID_WIDTH = 4,
    parameter ADDR_WIDTH = 16,

    parameter N = (ID_W_WIDTH-1)*(ID_R_WIDTH-1),

    parameter AXI_DATA_WIDTH = 32
    `ifdef TID_PRESENT
    ,
    parameter ID_WIDTH = 4
    `endif
    `ifdef TDEST_PRESENT
    ,
    parameter DEST_WIDTH = 4
    `endif
    `ifdef TUSER_PRESENT
    ,
    parameter USER_WIDTH = 4
    `endif
) (
    input  logic        aclk,
    input  logic        aresetn,

    input  logic [4:0]  pmu_addr_i   [N],
    output logic [63:0] pmu_data_o   [N],

    input  logic [7:0]  req_depth_i,
    input  logic [4:0]  id_i         [N],
    input  logic        write_i      [N],
    input  logic [7:0]  axlen_i      [N],
    input  logic        fifo_push_i  [N],
    input  logic        start_i,
    output logic        idle_o       [N]
);

    `include "axi_type.svh"

    axi_mosi_t axi_mosi[N];
    axi_miso_t axi_miso[N];

    axi_mosi_t axi_mosi_ram[N];
    axi_miso_t axi_miso_ram[N];

    generate
        genvar i;
        for (i = 0; i < N; i++) begin : map_wires

            axi_pmu #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .ID_W_WIDTH(ID_W_WIDTH),
                .ID_R_WIDTH(ID_R_WIDTH),
                .MAX_ID_WIDTH(MAX_ID_WIDTH)
                `ifdef TID_PRESENT
                ,
                .ID_WIDTH(ID_WIDTH)
                `endif
                `ifdef TDEST_PRESENT
                ,
                .DEST_WIDTH(DEST_WIDTH)
                `endif
                `ifdef TUSER_PRESENT
                ,
                .USER_WIDTH(USER_WIDTH)
                `endif
            ) pmu (
                .aclk    (aclk),
                .aresetn (aresetn),
                .mon_axi_miso (axi_miso[i]),
                .mon_axi_mosi (axi_mosi[i]),
                .addr_i  (pmu_addr_i[i]),
                .data_o  (pmu_data_o[i])
            );

            axi_master_loader #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .ID_W_WIDTH(ID_W_WIDTH),
                .ID_R_WIDTH(ID_R_WIDTH),
                .MAX_ID_WIDTH(MAX_ID_WIDTH)
                `ifdef TID_PRESENT
                ,
                .ID_WIDTH(ID_WIDTH)
                `endif
                `ifdef TDEST_PRESENT
                ,
                .DEST_WIDTH(DEST_WIDTH)
                `endif
                `ifdef TUSER_PRESENT
                ,
                .USER_WIDTH(USER_WIDTH)
                `endif
            ) loader (
                .clk_i       (aclk),
                .arstn_i     (aresetn),
                .req_depth_i (req_depth_i),
                .id_i        (id_i[i]),
                .write_i     (write_i[i]),
                .axlen_i     (axlen_i[i]),
                .fifo_push_i (fifo_push_i[i]),
                .start_i     (start_i),
                .idle_o      (idle_o[i]),
                .m_axi_i     (axi_miso[i]),
                .m_axi_o     (axi_mosi[i])
            );
        end
    endgenerate

    XY_mesh_dual_parallel #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_i(axi_mosi),
        .s_axi_o(axi_miso),

        .m_axi_i(axi_miso_ram),
        .m_axi_o(axi_mosi_ram)
    );

    axi_ram #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .BYTE_WIDTH(AXI_DATA_WIDTH/8 + (AXI_DATA_WIDTH%8 != 0)),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH)
    ) ram[N] (
        .clk_i({N{aclk}}),
        .rst_n_i({N{aresetn}}),
        .in_mosi_i(axi_mosi_ram),
        .in_miso_o(axi_miso_ram)
    );
    
endmodule