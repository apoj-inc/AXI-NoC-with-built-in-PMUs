`include "defines.svh"
`include "axis_defines.svh"
`include "XY_compas.svh"

module XY_mesh_dual_parallel #(
    parameter AXI_DATA_WIDTH  = 32,
    parameter AXI_ADDR_WIDTH  = 16,
    parameter AXI_ID_W_WIDTH  = 5,
    parameter AXI_ID_R_WIDTH  = 5,

    parameter AXIS_DATA_WIDTH = 40,
    parameter AXIS_ID_WIDTH   = 4,
    parameter AXIS_DEST_WIDTH = 4,
    parameter AXIS_USER_WIDTH = 4,

    parameter MAX_ROUTERS_X   = 4,
    parameter MAX_ROUTERS_Y   = 4,

    parameter BUFFER_DEPTH = 16,

    parameter MAX_ROUTERS_X_WIDTH = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y_WIDTH = $clog2(MAX_ROUTERS_Y)
) (
    input ACLK, ARESETn,

    axi_if.s s_axi_i[MAX_ROUTERS_X*MAX_ROUTERS_Y],
    axi_if.m m_axi_o[MAX_ROUTERS_X*MAX_ROUTERS_Y]
);
    
    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   router_if[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][10](),
        from_home[MAX_ROUTERS_Y][MAX_ROUTERS_X][2](),
        router_in[MAX_ROUTERS_Y][MAX_ROUTERS_X][10]();

    generate
        genvar i;
        genvar j;

        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : zeroing_Y
            assign router_if[i][0][WEST_REQ].TVALID = '0;
            assign router_if[i][0][WEST_RESP].TVALID = '0;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_REQ].TVALID = '0;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_RESP].TVALID = '0;

            assign router_if[i][0][WEST_REQ].TREADY = '1;
            assign router_if[i][0][WEST_RESP].TREADY = '1;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_REQ].TREADY = '1;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_RESP].TREADY = '1;
        end

        for (i = 0; i < MAX_ROUTERS_X; i++) begin : zeroing_X
            assign router_if[0][i][NORTH_REQ].TVALID = '0;
            assign router_if[0][i][NORTH_RESP].TVALID = '0;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH_REQ].TVALID = '0;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH_RESP].TVALID = '0;

            assign router_if[0][i][NORTH_REQ].TREADY = '1;
            assign router_if[0][i][NORTH_RESP].TREADY = '1;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH_REQ].TREADY = '1;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH_RESP].TREADY = '1;
        end
    endgenerate

    generate
        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : Y
            for (j = 0; j < MAX_ROUTERS_X; j++) begin : X
                
                axi2axis_XY #(
                    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
                    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
                    .AXI_ID_W_WIDTH(AXI_ID_W_WIDTH),
                    .AXI_ID_R_WIDTH(AXI_ID_R_WIDTH),

                    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
                    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),

                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y)
                ) bridge (
                    .ACLK(ACLK),
                    .ARESETn(ARESETn),

                    .s_axi_if_i(s_axi_i[i * MAX_ROUTERS_X + j]),
                    .m_axi_if_o(m_axi_o[i * MAX_ROUTERS_X + j]),

                    .s_axis_if_resp_i(router_if[i+1][j+1][HOME_RESP]),
                    .m_axis_if_resp_o(from_home[i][j][HOME_RESP]),

                    .s_axis_if_req_i(router_if[i+1][j+1][HOME_REQ]),
                    .m_axis_if_req_o(from_home[i][j][HOME_REQ])
                );

                `AXIS_INTERFACE2INTERFACE(from_home[i][j][HOME_REQ], router_in[i][j][HOME_REQ])
                `AXIS_INTERFACE2INTERFACE(from_home[i][j][HOME_RESP], router_in[i][j][HOME_RESP])

                `AXIS_INTERFACE2INTERFACE(router_if[i][j+1][SOUTH_REQ] , router_in[i][j][NORTH_REQ])
                `AXIS_INTERFACE2INTERFACE(router_if[i][j+1][SOUTH_RESP], router_in[i][j][NORTH_RESP])

                `AXIS_INTERFACE2INTERFACE(router_if[i+1][j+2][WEST_REQ] , router_in[i][j][EAST_REQ])
                `AXIS_INTERFACE2INTERFACE(router_if[i+1][j+2][WEST_RESP], router_in[i][j][EAST_RESP])

                `AXIS_INTERFACE2INTERFACE(router_if[i+2][j+1][NORTH_REQ] , router_in[i][j][SOUTH_REQ])
                `AXIS_INTERFACE2INTERFACE(router_if[i+2][j+1][NORTH_RESP], router_in[i][j][SOUTH_RESP])

                `AXIS_INTERFACE2INTERFACE(router_if[i+1][j][EAST_REQ] , router_in[i][j][WEST_REQ])
                `AXIS_INTERFACE2INTERFACE(router_if[i+1][j][EAST_RESP], router_in[i][j][WEST_RESP])
                
                router_dual_parallel #(
                    .CHANNEL_NUMBER(10),
                    .USE_XY_COORDINATES(1),
                    .USE_MESH_XY(1),
                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y),

                    .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                    .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                    .BUFFER_DEPTH(BUFFER_DEPTH)
                ) router (
                    .clk_i(ACLK),
                    .rst_n_i(ARESETn),

                    .s_axis_i(router_in[i][j]),
                    .m_axis_o(router_if[i+1][j+1])
                );

            end
        end
    endgenerate

endmodule
