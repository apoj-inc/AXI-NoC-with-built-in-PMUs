`include "defines.svh"

import axi_type_pkg::*;

module XY_mesh_dual_cpu #(
    parameter MAX_ROUTERS_X = 3,
    parameter MAX_ROUTERS_Y = 3,

    parameter Ax_FIFO_LEN = 4,
    parameter W_FIFO_LEN = 4
) (
    input logic clk,
    input logic rst_n
);

    localparam CPUS_NUMBER = MAX_ROUTERS_X*MAX_ROUTERS_Y;

    axi_mosi_t s_axi_i[CPUS_NUMBER];
    axi_miso_t s_axi_o[CPUS_NUMBER];

    axi_miso_t m_axi_i[CPUS_NUMBER];
    axi_mosi_t m_axi_o[CPUS_NUMBER];

    sr_cpu_axi cpu[CPUS_NUMBER] (
        .clk   ({CPUS_NUMBER{clk}}),  
        .rst_n ({CPUS_NUMBER{rst_n}}),

        .in_miso_i(m_axi_i),
        .in_mosi_o(m_axi_o)
    );

    axi_ram ram[CPUS_NUMBER] (
        .clk   ({CPUS_NUMBER{clk}}),
        .rst_n ({CPUS_NUMBER{rst_n}}),

        .in_mosi_i(s_axi_i),
        .in_miso_o(s_axi_o)
    );

    XY_mesh_dual #(
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