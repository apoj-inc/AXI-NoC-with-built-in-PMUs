`include "defines.svh"

module XY_mesh_dual_cpu #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter MAX_ID_WIDTH = 4,
    `ifdef TID_PRESENT
    parameter ID_WIDTH = 4,
    `else
    parameter ID_WIDTH = 0,
    `endif
    `ifdef TDEST_PRESENT
    parameter DEST_WIDTH = 4,
    `else
    parameter DEST_WIDTH = 0,
    `endif
    `ifdef TUSER_PRESENT
    parameter USER_WIDTH = 4,
    `else
    parameter USER_WIDTH = 0,
    `endif

    parameter MAX_ROUTERS_X = 3,
    parameter MAX_ROUTERS_Y = 3,

    parameter Ax_FIFO_LEN = 4,
    parameter W_FIFO_LEN = 4
) (
    input logic clk,
    input logic rst_n
);

    `include "axi_type.svh"

    axi_mosi_t s_axi_i[16];
    axi_miso_t s_axi_o[16];

    axi_miso_t m_axi_i[16];
    axi_mosi_t m_axi_o[16];

    sr_cpu_axi #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .MAX_ID_WIDTH(MAX_ID_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH)
    ) cpu[16] (
        .clk   ({16{clk}}),  
        .rst_n ({16{rst_n}}),

        .in_miso_i(m_axi_i),
        .in_mosi_o(m_axi_o)
    );

    axi_ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .MAX_ID_WIDTH(MAX_ID_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH)
    ) ram[16] (
        .clk   ({16{clk}}),
        .rst_n ({16{rst_n}}),

        .in_mosi_i(s_axi_i),
        .in_miso_o(s_axi_o)
    );

    XY_mesh_dual #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ID_W_WIDTH(ID_W_WIDTH),
    .ID_R_WIDTH(ID_R_WIDTH),
    .MAX_ID_WIDTH(MAX_ID_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_WIDTH(USER_WIDTH),

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