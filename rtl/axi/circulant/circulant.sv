`include "defines.svh"
`include "axis_defines.svh"

module circulant #(
    parameter        AXI_DATA_WIDTH  = 32,
    parameter        AXI_ADDR_WIDTH  = 16,
    parameter        AXI_ID_W_WIDTH  = 5,
    parameter        AXI_ID_R_WIDTH  = 5,

    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH   = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4,
    
    parameter        BUFFER_DEPTH    = 16,
    parameter string ALGORITHM       = "Clockwise",
    parameter string BUFFER_ALLOCATOR = "Straight",

    parameter        ROUTERS_COUNT = 6,
    parameter        GENERATICS_COUNT = 2,
    parameter int    GENERATICS[GENERATICS_COUNT] = '{2, 1},

    
    parameter        PHYSICAL_CHANNEL_NUMBER = GENERATICS_COUNT*2 + 1,
    parameter        PHYSICAL_CHANNEL_NUMBER_WIDTH = $clog2(PHYSICAL_CHANNEL_NUMBER),

    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        VIRTUAL_CHANNEL_NUMBER_WIDTH = $clog2(VIRTUAL_CHANNEL_NUMBER),

    parameter        SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING = 0,
    parameter        VIRTUAL_NETWORK_NUMBER = 2,
    parameter int    VIRTUAL_NETWORKS[VIRTUAL_NETWORK_NUMBER] = '{1, 1}
) (
    input ACLK, ARESETn,

    axi_if.s s_axi_i[ROUTERS_COUNT],
    axi_if.m m_axi_o[ROUTERS_COUNT]
);

    int test_previous_generatic;
    int test_i;

    initial begin //GENERATICS sanity test
    assert (GENERATICS_COUNT > 0) else $error("No generatics passed!");
    test_previous_generatic = GENERATICS[0];
    assert (test_previous_generatic < ROUTERS_COUNT) else $error("Generatics greater than routers!");
    for(test_i = 1; test_i < GENERATICS_COUNT; test_i++) begin
        assert (GENERATICS[test_i] < test_previous_generatic) else $error("Generatics order broken!");
        test_previous_generatic = GENERATICS[test_i];
    end

    assert (test_previous_generatic > 0) else $error("Incorrect genetarics format: nonpositive!");
    end

    localparam CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER;

    typedef enum logic {
        HOME_REQ,
        HOME_RESP
    } home_index;

    genvar i, generatic, current_virtual_channel;
    
    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   router_if[ROUTERS_COUNT][CHANNEL_NUMBER](),
        from_home[ROUTERS_COUNT][VIRTUAL_CHANNEL_NUMBER](),
        router_in[ROUTERS_COUNT][CHANNEL_NUMBER]();

    generate
        for (i = 0; i < ROUTERS_COUNT; i++) begin : router_iteration

            axi2axis #(
                .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
                .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
                .AXI_ID_W_WIDTH(AXI_ID_W_WIDTH),
                .AXI_ID_R_WIDTH(AXI_ID_R_WIDTH),

                .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
                .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH(AXIS_USER_WIDTH),

                .COORDINATES("N"),

                .ROUTER_N(i),
                .ROUTERS_COUNT(ROUTERS_COUNT)
            ) bridge (
                .ACLK(ACLK),
                .ARESETn(ARESETn),

                .s_axi_if_i(s_axi_i[i]),
                .m_axi_if_o(m_axi_o[i]),

                .s_axis_if_resp_i(router_if[i][HOME_RESP]),
                .m_axis_if_resp_o(from_home[i][HOME_RESP]),

                .s_axis_if_req_i(router_if[i][HOME_REQ]),
                .m_axis_if_req_o(from_home[i][HOME_REQ])
            );

            for (current_virtual_channel = 0; current_virtual_channel < VIRTUAL_CHANNEL_NUMBER; current_virtual_channel++) begin : assigning_home_channels
                `AXIS_INTERFACE2INTERFACE(from_home[i][current_virtual_channel], router_in[i][current_virtual_channel])
            end

            for (generatic = 0; generatic < GENERATICS_COUNT; generatic++) begin : interconnection_assignment
                for (current_virtual_channel = 0; current_virtual_channel < VIRTUAL_CHANNEL_NUMBER; current_virtual_channel++) begin : assigning_generatics_channels
                    //Clockwise
                    `AXIS_INTERFACE2INTERFACE(router_if[i][(generatic+1)*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel]  , router_in[(i+GENERATICS[generatic])%ROUTERS_COUNT][(generatic+1)*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                    //Counter clockwise
                    `AXIS_INTERFACE2INTERFACE(router_if[i][(generatic+GENERATICS_COUNT+1)*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel]  , router_in[(i+GENERATICS[generatic])%ROUTERS_COUNT][(generatic+GENERATICS_COUNT+1)*VIRTUAL_CHANNEL_NUMBER+current_virtual_channel])
                end
            end
            
            router #(
                .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                .PHYSICAL_CHANNEL_NUMBER  (PHYSICAL_CHANNEL_NUMBER),
                .VIRTUAL_CHANNEL_NUMBER  (VIRTUAL_CHANNEL_NUMBER),
                .BUFFER_DEPTH    (BUFFER_DEPTH),
                .TOPOLOGY        ("Circulant"),
                .ALGORITHM       (ALGORITHM),
                .COORDINATES     ("N"),
                .BUFFER_ALLOCATOR(BUFFER_ALLOCATOR),

                .SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING(SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING),
                .VIRTUAL_NETWORK_NUMBER(VIRTUAL_NETWORK_NUMBER),
                .VIRTUAL_NETWORKS(VIRTUAL_NETWORKS),

                .ROUTER_N(i),
                .ROUTERS_COUNT(ROUTERS_COUNT),
                .GENERATICS_COUNT(GENERATICS_COUNT),
                .GENERATICS(GENERATICS)
            ) router (
                .clk_i(ACLK),
                .rst_n_i(ARESETn),

                .s_axis_i(router_in[i]),
                .m_axis_o(router_if[i])
            );

        end
    endgenerate



endmodule