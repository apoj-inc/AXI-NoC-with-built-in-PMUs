`include "defines.svh"

module mesh_dual_w (
    input ACLK, ARESETn,

    axi_if.s s_axi_i[`MAX_ROUTERS_X*`MAX_ROUTERS_Y],
    axi_if.m m_axi_o[`MAX_ROUTERS_X*`MAX_ROUTERS_Y]
);

XY_mesh_dual #(
    .AXI_DATA_WIDTH(`AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(`AXI_ADDR_WIDTH),
    .AXI_ID_W_WIDTH(`AXI_ID_W_WIDTH),
    .AXI_ID_R_WIDTH(`AXI_ID_R_WIDTH),

    .AXIS_DATA_WIDTH(`AXIS_DATA_WIDTH),
    .AXIS_ID_WIDTH(`AXIS_ID_WIDTH),
    .AXIS_DEST_WIDTH(`AXIS_DEST_WIDTH),
    .AXIS_USER_WIDTH(`AXIS_USER_WIDTH),

    .MAX_ROUTERS_X(`MAX_ROUTERS_X),
    .MAX_ROUTERS_Y(`MAX_ROUTERS_Y),
    
    .BUFFER_DEPTH(`BUFFER_DEPTH),

    .MAX_ROUTERS_X_WIDTH(`MAX_ROUTERS_X_WIDTH),
    .MAX_ROUTERS_Y_WIDTH(`MAX_ROUTERS_Y_WIDTH)
) dut (
    .ACLK(ACLK), .ARESETn(ARESETn),

    .s_axi_i(s_axi_i),
    .m_axi_o(m_axi_o)
);

endmodule : mesh_dual_w
