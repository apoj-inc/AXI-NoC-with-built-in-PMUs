`include "defines.svh"

module circulant_dual_w (
    input aclk, aresetn,

    axi_if.s s_axi_i[`ROUTERS_COUNT],
    axi_if.m m_axi_o[`ROUTERS_COUNT]
);

circulant_dual #(
    .AXI_DATA_WIDTH(`AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(`AXI_ADDR_WIDTH),
    .AXI_ID_W_WIDTH(`AXI_ID_W_WIDTH),
    .AXI_ID_R_WIDTH(`AXI_ID_R_WIDTH),

    .AXIS_DATA_WIDTH(`AXIS_DATA_WIDTH),
    .AXIS_ID_WIDTH(`AXIS_ID_WIDTH),
    .AXIS_DEST_WIDTH(`AXIS_DEST_WIDTH),
    .AXIS_USER_WIDTH(`AXIS_USER_WIDTH),
    
    .BUFFER_DEPTH(`BUFFER_DEPTH),

    .ROUTERS_COUNT(`ROUTERS_COUNT),
    .GENERATICS_COUNT(`GENERATICS_COUNT),
    .GENERATICS(`GENERATICS)
) dut (
    .ACLK(ACLK), .ARESETn(ARESETn),

    .s_axi_i(s_axi_i),
    .m_axi_o(m_axi_o)
);

endmodule : mesh_dual_w