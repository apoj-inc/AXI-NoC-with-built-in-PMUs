`include "defines.svh"
`include "axis_defines.svh"
`include "XY_compas.svh"

module torus #(
    parameter        AXI_DATA_WIDTH  = 32,
    parameter        AXI_ADDR_WIDTH  = 16,
    parameter        AXI_ID_W_WIDTH  = 5,
    parameter        AXI_ID_R_WIDTH  = 5,

    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH   = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4,

    parameter        MAX_ROUTERS_X   = 5,
    parameter        MAX_ROUTERS_Y   = 5,

    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        VIRTUAL_CHANNEL_NUMBER_WIDTH = $clog2(VIRTUAL_CHANNEL_NUMBER),

    parameter        SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING = 0,
    parameter        VIRTUAL_NETWORK_NUMBER = 2,
    parameter int    VIRTUAL_NETWORKS[VIRTUAL_NETWORK_NUMBER] = '{1, 1},
    
    parameter        BUFFER_DEPTH    = 16,
    parameter string ALGORITHM       = "XY",
    parameter string BUFFER_ALLOCATOR = "Straight",

    parameter        MAX_ROUTERS_X_WIDTH = $clog2(MAX_ROUTERS_X),
    parameter        MAX_ROUTERS_Y_WIDTH = $clog2(MAX_ROUTERS_Y)
) (
    input ACLK, ARESETn,

    axi_if.s s_axi_i[MAX_ROUTERS_X*MAX_ROUTERS_Y],
    axi_if.m m_axi_o[MAX_ROUTERS_X*MAX_ROUTERS_Y]
);

    genvar i, j;
    genvar current_virtual_channel;
    
    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   router_if[MAX_ROUTERS_Y][MAX_ROUTERS_X][5*VIRTUAL_CHANNEL_NUMBER](),
        from_home[MAX_ROUTERS_Y][MAX_ROUTERS_X][VIRTUAL_CHANNEL_NUMBER](),
        router_in[MAX_ROUTERS_Y][MAX_ROUTERS_X][5*VIRTUAL_CHANNEL_NUMBER]();

    generate
        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : Y
            for (j = 0; j < MAX_ROUTERS_X; j++) begin : X
                
                axi2axis #(
                    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
                    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
                    .AXI_ID_W_WIDTH(AXI_ID_W_WIDTH),
                    .AXI_ID_R_WIDTH(AXI_ID_R_WIDTH),

                    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
                    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),

                    .COORDINATES("XY"),

                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y)
                ) bridge (
                    .ACLK(ACLK),
                    .ARESETn(ARESETn),

                    .s_axi_if_i(s_axi_i[i * MAX_ROUTERS_X + j]),
                    .m_axi_if_o(m_axi_o[i * MAX_ROUTERS_X + j]),

                    .s_axis_if_resp_i(router_if[i][j][HOME_RESP]),
                    .m_axis_if_resp_o(from_home[i][j][HOME_RESP]),

                    .s_axis_if_req_i(router_if[i][j][HOME_REQ]),
                    .m_axis_if_req_o(from_home[i][j][HOME_REQ])
                );



                for (current_virtual_channel = 0; current_virtual_channel < VIRTUAL_CHANNEL_NUMBER; current_virtual_channel++) begin : assigning_channels
                    `AXIS_INTERFACE2INTERFACE(from_home[i][j][HOME*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel], router_in[i][j][HOME*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                    `AXIS_INTERFACE2INTERFACE(router_if[(MAX_ROUTERS_Y+i-1)%MAX_ROUTERS_Y][j][SOUTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel] , router_in[i][j][NORTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                    `AXIS_INTERFACE2INTERFACE(router_if[i][(MAX_ROUTERS_X+j+1)%MAX_ROUTERS_X][WEST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel] , router_in[i][j][EAST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                    `AXIS_INTERFACE2INTERFACE(router_if[(MAX_ROUTERS_Y+i+1)%MAX_ROUTERS_Y][j][NORTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel] , router_in[i][j][SOUTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                    `AXIS_INTERFACE2INTERFACE(router_if[i][(MAX_ROUTERS_X+j-1)%MAX_ROUTERS_X][EAST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel] , router_in[i][j][WEST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                end
                
                router #(
                    .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                    .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                    .PHISICAL_CHANNEL_NUMBER  (5),
                    .VIRTUAL_CHANNEL_NUMBER  (VIRTUAL_CHANNEL_NUMBER),
                    .BUFFER_DEPTH    (BUFFER_DEPTH),
                    .TOPOLOGY        ("Torus"),
                    .ALGORITHM       (ALGORITHM),
                    .COORDINATES     ("XY"),
                    .BUFFER_ALLOCATOR(BUFFER_ALLOCATOR),

                    .SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING(SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING),
                    .VIRTUAL_NETWORK_NUMBER(VIRTUAL_NETWORK_NUMBER),
                    .VIRTUAL_NETWORKS(VIRTUAL_NETWORKS),

                    .MAX_ROUTERS_X   (MAX_ROUTERS_X),
                    .MAX_ROUTERS_Y   (MAX_ROUTERS_Y),
                    .ROUTER_X        (j),
                    .ROUTER_Y        (i)
                ) router (
                    .clk_i(ACLK),
                    .rst_n_i(ARESETn),

                    .s_axis_i(router_in[i][j]),
                    .m_axis_o(router_if[i][j])
                );

            end
        end
    endgenerate



endmodule