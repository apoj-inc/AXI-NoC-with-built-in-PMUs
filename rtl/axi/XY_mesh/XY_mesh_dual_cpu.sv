`include "defines.svh"

module XY_mesh_dual_cpu #(
    parameter ADDR_WIDTH = 12,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter MAX_ID_WIDTH = 4,
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
    `endif,

    parameter MAX_ROUTERS_X = 3,
    parameter MAX_ROUTERS_Y = 3,

    parameter Ax_FIFO_LEN = 4,
    parameter W_FIFO_LEN = 4
) (
    input logic clk,
    input logic rst_n
);

    `include "axi_type.svh"

    localparam CPUS_NUMBER = MAX_ROUTERS_X*MAX_ROUTERS_Y;

    axi_mosi_t s_axi_i[CPUS_NUMBER];
    axi_miso_t s_axi_o[CPUS_NUMBER];

    axi_miso_t m_axi_i[CPUS_NUMBER];
    axi_mosi_t m_axi_o[CPUS_NUMBER];

    sr_cpu_axi #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .MAX_ID_WIDTH(MAX_ID_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
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
    ) cpu[CPUS_NUMBER] (
        .clk   ({CPUS_NUMBER{clk}}),  
        .rst_n ({CPUS_NUMBER{rst_n}}),

        .in_miso_i(m_axi_i),
        .in_mosi_o(m_axi_o)
    );

    axi_ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
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
    ) ram[CPUS_NUMBER] (
        .clk   ({CPUS_NUMBER{clk}}),
        .rst_n ({CPUS_NUMBER{rst_n}}),

        .in_mosi_i(s_axi_i),
        .in_miso_o(s_axi_o)
    );

    XY_mesh_dual #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .ID_W_WIDTH(ID_W_WIDTH),
    .ID_R_WIDTH(ID_R_WIDTH)
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
    `endif,

    .MAX_ROUTERS_X(MAX_ROUTERS_X),
    .MAX_ROUTERS_Y(MAX_ROUTERS_Y),

    .Ax_FIFO_LEN(Ax_FIFO_LEN),
    .W_FIFO_LEN(W_FIFO_LEN)

    ) mesh (
        .ACLK      (clk),
        .ARESETn   (rst_n),

        .s_axi_i  (s_axi_i),
        .s_axi_o  (s_axi_o),

        .m_axi_i (m_axi_i),
        .m_axi_o (m_axi_o)
    );

endmodule