`include "defines.svh"
`include "axis_defines.svh"
`include "XY_compas.svh"
`include "virtual_networks_utils.svh"

module mesh #(
    parameter        AXI_DATA_WIDTH   = 32,
    parameter        AXI_ADDR_WIDTH   = 16,
    parameter        AXI_ID_W_WIDTH   = 5,
    parameter        AXI_ID_R_WIDTH   = 5,

    parameter        AXIS_DATA_WIDTH  = 40,
    parameter        AXIS_ID_WIDTH    = 4,
    parameter        AXIS_DEST_WIDTH  = 4,
    parameter        AXIS_USER_WIDTH  = 4,

    parameter        MAX_ROUTERS_X    = 4,
    parameter        MAX_ROUTERS_Y    = 4,

    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        VIRTUAL_CHANNEL_NUMBER_WIDTH = $clog2(VIRTUAL_CHANNEL_NUMBER),

    parameter        SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING = 0,
    parameter        VIRTUAL_NETWORK_NUMBER = 2,
    parameter int    VIRTUAL_NETWORKS[VIRTUAL_NETWORK_NUMBER] = '{1, 1},
    
    parameter        BUFFER_DEPTH     = 16,
    parameter string ALGORITHM        = "XY",
    parameter string BUFFER_ALLOCATOR = "Straight",

    parameter        MAX_ROUTERS_X_WIDTH = $clog2(MAX_ROUTERS_X),
    parameter        MAX_ROUTERS_Y_WIDTH = $clog2(MAX_ROUTERS_Y)
) (
    input ACLK, ARESETn,

    axi_if.s s_axi_i[MAX_ROUTERS_X*MAX_ROUTERS_Y],
    axi_if.m m_axi_o[MAX_ROUTERS_X*MAX_ROUTERS_Y]
);
    `GENERATE_CALCULATE_VIRTUAL_NETWORK_OFFSET

    initial assert(MAX_ROUTERS_X >= MAX_ROUTERS_Y) else $error("Mismatched dimensions(X:%d, Y:%d, Y > X)", MAX_ROUTERS_X, MAX_ROUTERS_Y);
    
    localparam PHYSICAL_CHANNEL_NUMBER = 5;
    localparam CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER;

    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   router_if[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][CHANNEL_NUMBER](),
        from_home[MAX_ROUTERS_Y][MAX_ROUTERS_X][VIRTUAL_CHANNEL_NUMBER](),
        router_in[MAX_ROUTERS_Y][MAX_ROUTERS_X][CHANNEL_NUMBER](),
        if_demuxed[MAX_ROUTERS_Y][MAX_ROUTERS_X][VIRTUAL_NETWORK_NUMBER][VIRTUAL_CHANNEL_NUMBER](),
        ncp_s_axis_dem[MAX_ROUTERS_Y][MAX_ROUTERS_X][VIRTUAL_CHANNEL_NUMBER]();

    genvar current_virtual_channel;
    generate
        genvar i, j;

        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : zeroing_Y
            for (current_virtual_channel = 0; current_virtual_channel < VIRTUAL_CHANNEL_NUMBER; current_virtual_channel++) begin : vc
                assign router_if[i][0][WEST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel].TVALID = '0;
                assign router_if[i][MAX_ROUTERS_X+1][EAST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel].TVALID = '0;

                assign router_if[i][0][WEST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel].TREADY = '1;
                assign router_if[i][MAX_ROUTERS_X+1][EAST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel].TREADY = '1;
            end
        end

        for (i = 0; i < MAX_ROUTERS_X; i++) begin : zeroing_X
            for (current_virtual_channel = 0; current_virtual_channel < VIRTUAL_CHANNEL_NUMBER; current_virtual_channel++) begin : vc
                assign router_if[0][i][NORTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel].TVALID = '0;
                assign router_if[MAX_ROUTERS_Y+1][i][SOUTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel].TVALID = '0;

                assign router_if[0][i][NORTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel].TREADY = '1;
                assign router_if[MAX_ROUTERS_Y+1][i][SOUTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel].TREADY = '1;
            end
        end
    endgenerate

    generate
        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : Y
            for (j = 0; j < MAX_ROUTERS_X; j++) begin : X

                axis_if #(
                    .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                    .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
                )   axi2axis_req_resp[2]();
                
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


                    .s_axis_if_req_i(axi2axis_req_resp[0]),
                    .m_axis_if_req_o(from_home[i][j][0]),

                    .s_axis_if_resp_i(axi2axis_req_resp[1]),
                    .m_axis_if_resp_o(from_home[i][j][VIRTUAL_NETWORKS[0]])
                );

                genvar demux_vc;
                for (demux_vc = 0; demux_vc < VIRTUAL_CHANNEL_NUMBER; demux_vc++) begin : demux_input_connect
                    `AXIS_INTERFACE2INTERFACE(router_if[i+1][j+1][demux_vc], ncp_s_axis_dem[i][j][demux_vc])
                end

                network_channel_demux # (
                    .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                    .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH (AXIS_USER_WIDTH),
                    
                    .PHYSICAL_CHANNEL_NUMBER(1),
                    .VIRTUAL_CHANNEL_NUMBER(VIRTUAL_CHANNEL_NUMBER),
                    .CHANNEL_NUMBER(VIRTUAL_CHANNEL_NUMBER),
                    .VIRTUAL_NETWORK_NUMBER(VIRTUAL_NETWORK_NUMBER),
                    .VIRTUAL_NETWORKS(VIRTUAL_NETWORKS)
                ) ncp (
                    .s_axis_dem(ncp_s_axis_dem[i][j]),
                    .m_axis_dem(if_demuxed[i][j])
                );

                genvar gen_arbiter;
                for (gen_arbiter = 0; gen_arbiter < 2; gen_arbiter++) begin: demultiplexing_entrances_to_bridges
                    localparam OFFSET = calculate_virtual_network_offset(gen_arbiter);

                    axis_if #(
                        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
                    )   if_demuxed_narrowed[VIRTUAL_NETWORKS[gen_arbiter]]();

                    network_channel_narrower #(
                        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                        .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                        .WIDTH_IN(VIRTUAL_CHANNEL_NUMBER),
                        .WIDTH_OUT(VIRTUAL_NETWORKS[gen_arbiter])
                    ) ncn (
                        .s_axis_i(if_demuxed[i][j][gen_arbiter]),
                        .m_axis_o(if_demuxed_narrowed)
                    );

                    axis_if #(
                        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
                    )   queue_o_if       [VIRTUAL_NETWORKS[gen_arbiter]] ();

                    router_buffer #(
                        .PHYSICAL_CHANNEL_NUMBER(1),
                        .VIRTUAL_CHANNEL_NUMBER(VIRTUAL_NETWORKS[gen_arbiter]),
                        .CHANNEL_NUMBER(VIRTUAL_NETWORKS[gen_arbiter]),
                        .VIRTUAL_NETWORK_NUMBER(1),
                        .VIRTUAL_NETWORKS('{VIRTUAL_NETWORKS[gen_arbiter]}),
                        .BUFFER_DEPTH(4),
                        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                        .AXIS_USER_WIDTH (AXIS_USER_WIDTH),
                        .BUFFER_ALLOCATOR("KeepInNetwork")
                    ) buffer (
                        .ACLK(ACLK),
                        .ARESETn(ARESETn),

                        .s_axis_i(if_demuxed_narrowed),
                        .m_axis_o(queue_o_if)
                    );
                    
                    arbiter #(
                        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                        .AXIS_USER_WIDTH (AXIS_USER_WIDTH),
                        .CHANNEL_NUMBER  (VIRTUAL_NETWORKS[gen_arbiter]),

                        .TARGET_LEN(1),
                        .NO_TIMEOUT(1)
                    ) arb (
                        .clk_i(ACLK), .rst_n_i(ARESETn),

                        .s_axis_i(queue_o_if),
                        .m_axis_o(axi2axis_req_resp[gen_arbiter])
                    );
                    genvar closed_from_homes;
                    for (closed_from_homes = OFFSET + 1;closed_from_homes < OFFSET + VIRTUAL_NETWORKS[gen_arbiter]; closed_from_homes++) begin: zeroing_from_home
                        assign from_home[i][j][closed_from_homes].TVALID = '0;
                        assign from_home[i][j][closed_from_homes].TDATA  = '0;
                        assign from_home[i][j][closed_from_homes].TSTRB  = '0;
                        assign from_home[i][j][closed_from_homes].TKEEP  = '0;
                        assign from_home[i][j][closed_from_homes].TLAST  = '0;
                        assign from_home[i][j][closed_from_homes].TID    = '0;
                        assign from_home[i][j][closed_from_homes].TDEST  = '0;
                        assign from_home[i][j][closed_from_homes].TUSER  = '0;
                    end
                end

                for (current_virtual_channel = 0; current_virtual_channel < VIRTUAL_CHANNEL_NUMBER; current_virtual_channel++) begin : assigning_channels
                    `AXIS_INTERFACE2INTERFACE(from_home[i][j][HOME*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel], router_in[i][j][HOME*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                    `AXIS_INTERFACE2INTERFACE(router_if[i][j+1][SOUTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel], router_in[i][j][NORTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                    `AXIS_INTERFACE2INTERFACE(router_if[i+1][j+2][WEST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel], router_in[i][j][EAST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                    `AXIS_INTERFACE2INTERFACE(router_if[i+2][j+1][NORTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel], router_in[i][j][SOUTH*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                    `AXIS_INTERFACE2INTERFACE(router_if[i+1][j][EAST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel], router_in[i][j][WEST*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                end

                router #(
                    .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                    .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                    .PHYSICAL_CHANNEL_NUMBER  (5),
                    .VIRTUAL_CHANNEL_NUMBER  (VIRTUAL_CHANNEL_NUMBER),
                    .BUFFER_DEPTH    (BUFFER_DEPTH),
                    .TOPOLOGY        ("Mesh"),
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
                    .m_axis_o(router_if[i+1][j+1])
                );

            end
        end
    endgenerate

endmodule
