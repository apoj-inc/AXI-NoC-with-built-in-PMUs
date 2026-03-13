`include "defines.svh"
`include "axis_defines.svh"
`include "virtual_networks_utils.svh"

module router #(
    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4,

    parameter        PHYSICAL_CHANNEL_NUMBER = 5,
    parameter        PHYSICAL_CHANNEL_NUMBER_WIDTH = $clog2(PHYSICAL_CHANNEL_NUMBER),
    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),

    parameter        SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING = 0,
    parameter        VIRTUAL_NETWORK_NUMBER = 2,
    parameter int    VIRTUAL_NETWORKS[VIRTUAL_NETWORK_NUMBER] = '{1, 1},

    parameter        BUFFER_DEPTH = 16,
    parameter string BUFFER_ALLOCATOR = "Straight",
    parameter string TOPOLOGY = "Mesh",
    parameter string ALGORITHM = "XY",
    parameter string COORDINATES = "XY",
    
    // Algorithm and topology specific parameters
    // Mesh and Torus
    parameter        MAX_ROUTERS_X = 4,
    parameter        MAX_ROUTERS_X_WIDTH = $clog2(MAX_ROUTERS_X),
    parameter        MAX_ROUTERS_Y = 4,
    parameter        MAX_ROUTERS_Y_WIDTH = $clog2(MAX_ROUTERS_Y),
    parameter        ROUTER_X = 0,
    parameter        ROUTER_Y = 0,
    
    // Circulant
    parameter        ROUTER_N = 0,
    parameter        ROUTERS_COUNT = 6,
    parameter        GENERATICS_COUNT = 2,
    parameter int    GENERATICS[GENERATICS_COUNT] = '{2, 1}
)(
    input  clk_i, rst_n_i,
    axis_if.s s_axis_i [CHANNEL_NUMBER],
    axis_if.m m_axis_o [CHANNEL_NUMBER]
);
    
    `GENERATE_CALCULATE_VIRTUAL_NETWORK_OFFSET

    int testing_iterator, a0;

    localparam TARGET_LEN = COORDINATES == "XY" ?    MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH   :
                            COORDINATES == "N"  ?    $clog2(ROUTERS_COUNT)                       :
                                                     0                                           ;

    initial assert (TARGET_LEN != 0) else $error("Wrong coordintes configuration");

    initial assert (CHANNEL_NUMBER == PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER) 
        else $error("Channels misalligned! Virtual channels: %d, physical channels: %d, general channels: %d",
        VIRTUAL_NETWORK_NUMBER, PHYSICAL_CHANNEL_NUMBER, CHANNEL_NUMBER);

    initial begin
        a0 = 0;
        for(testing_iterator = 0; testing_iterator  < VIRTUAL_NETWORK_NUMBER; testing_iterator++) begin
            a0 = a0 + VIRTUAL_NETWORKS[testing_iterator];
        end
        assert (a0 == VIRTUAL_CHANNEL_NUMBER) else $error("Incorrect virtual channels allocation!");
    end

    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   queue_o_if       [CHANNEL_NUMBER  ] ();

    router_buffer #(
        .PHYSICAL_CHANNEL_NUMBER(PHYSICAL_CHANNEL_NUMBER),
        .VIRTUAL_CHANNEL_NUMBER(VIRTUAL_CHANNEL_NUMBER),
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .VIRTUAL_NETWORK_NUMBER(VIRTUAL_NETWORK_NUMBER),
        .VIRTUAL_NETWORKS(VIRTUAL_NETWORKS),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH),
        .BUFFER_ALLOCATOR(BUFFER_ALLOCATOR)
    ) buffer (
        .ACLK(clk_i),
        .ARESETn(rst_n_i),

        .s_axis_i(s_axis_i),
        .m_axis_o(queue_o_if)
    );

    genvar current_virtual_network;
    generate
        if(SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING) begin : simultanious_virtual_network_routing

            axis_if #(
                .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
            )   arb_i_if [VIRTUAL_NETWORK_NUMBER][CHANNEL_NUMBER] (),
                alg_o_if [VIRTUAL_NETWORK_NUMBER][CHANNEL_NUMBER] ();

            network_channel_picker # (
                .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH (AXIS_USER_WIDTH),
                
                .PHYSICAL_CHANNEL_NUMBER(PHYSICAL_CHANNEL_NUMBER),
                .VIRTUAL_CHANNEL_NUMBER(VIRTUAL_CHANNEL_NUMBER),
                .CHANNEL_NUMBER(CHANNEL_NUMBER),
                .VIRTUAL_NETWORK_NUMBER(VIRTUAL_NETWORK_NUMBER),
                .VIRTUAL_NETWORKS(VIRTUAL_NETWORKS)
            ) ncp (
                .s_axis_dem(queue_o_if),
                .m_axis_dem(arb_i_if),
                .s_axis_mux(alg_o_if),
                .m_axis_mux(m_axis_o)
            );

            for (current_virtual_network = 0; current_virtual_network < VIRTUAL_NETWORK_NUMBER; current_virtual_network++) begin : simultainious_network_routing_gen
                localparam VIRTUAL_NETWORK_CHANNELS = VIRTUAL_NETWORKS[current_virtual_network];
                localparam CHANNELS_IN_NETWORK = VIRTUAL_NETWORK_CHANNELS*PHYSICAL_CHANNEL_NUMBER;

                logic [PHYSICAL_CHANNEL_NUMBER_WIDTH-1:0] current_grant;
                logic [TARGET_LEN-1:0] target;

                axis_if #(
                    .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                    .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
                )   arb_o_if (),
                    arb_i_if_n [CHANNELS_IN_NETWORK] (),
                    alg_o_if_n [CHANNELS_IN_NETWORK] ();

                network_channel_narrower #(
                    .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                    .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                    .WIDTH_IN(CHANNEL_NUMBER),
                    .WIDTH_OUT(CHANNELS_IN_NETWORK)
                ) ncn1 (
                    .s_axis_i(arb_i_if[current_virtual_network]),
                    .m_axis_o(arb_i_if_n)
                );

                arbiter #(
                    .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                    .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH (AXIS_USER_WIDTH),
                    .CHANNEL_NUMBER  (CHANNELS_IN_NETWORK),

                    .TARGET_LEN(TARGET_LEN)
                ) arb (
                    .clk_i(clk_i), .rst_n_i(rst_n_i),

                    .s_axis_i(arb_i_if_n),
                    .m_axis_o(arb_o_if),

                    .current_grant_o(current_grant),
                    .target_o(target)
                );

                algorithm #(
                    .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                    .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                    .PHYSICAL_CHANNEL_NUMBER(PHYSICAL_CHANNEL_NUMBER),
                    .VIRTUAL_CHANNEL_NUMBER(VIRTUAL_NETWORK_CHANNELS),
                    .TOPOLOGY(TOPOLOGY),
                    .ALGORITHM(ALGORITHM),
                    .COORDINATES(COORDINATES),

                    .TARGET_LEN(TARGET_LEN),

                    // Algorithm and topology specific parameters
                    // Mesh and Torus
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
                    .ROUTER_X(ROUTER_X),
                    .ROUTER_Y(ROUTER_Y),
                    
                    // Circulant
                    .ROUTER_N(ROUTER_N),
                    .ROUTERS_COUNT(ROUTERS_COUNT),
                    .GENERATICS_COUNT(GENERATICS_COUNT),
                    .GENERATICS(GENERATICS)
                ) alg (
                    .clk_i(clk_i), .rst_n_i(rst_n_i),

                    .s_axis_i(arb_o_if),
                    .m_axis_o(alg_o_if_n),

                    .current_grant_i(current_grant),
                    .target_i(target)
                );

                network_channel_narrower #(
                    .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                    .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                    .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                    .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                    .WIDTH_IN(CHANNELS_IN_NETWORK),
                    .WIDTH_OUT(CHANNEL_NUMBER)
                ) ncn2 (
                    .s_axis_i(alg_o_if_n),
                    .m_axis_o(alg_o_if[current_virtual_network])
                );

            end
        end else begin : non_simultanious_virtual_network_routing
            logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant;
            logic [TARGET_LEN-1:0] target;
    
            axis_if #(
                .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
            )   arb_o_if                        ();

            arbiter #(
                .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH (AXIS_USER_WIDTH),
                .CHANNEL_NUMBER  (CHANNEL_NUMBER),

                .TARGET_LEN(TARGET_LEN)
            ) arb (
                .clk_i(clk_i), .rst_n_i(rst_n_i),

                .s_axis_i(queue_o_if),
                .m_axis_o(arb_o_if),

                .current_grant_o(current_grant),
                .target_o(target)
            );

            algorithm #(
                .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

                .PHYSICAL_CHANNEL_NUMBER(PHYSICAL_CHANNEL_NUMBER),
                .VIRTUAL_CHANNEL_NUMBER(VIRTUAL_CHANNEL_NUMBER),
                .CHANNEL_NUMBER(CHANNEL_NUMBER),
                .TOPOLOGY(TOPOLOGY),
                .ALGORITHM(ALGORITHM),
                .COORDINATES(COORDINATES),

                .TARGET_LEN(TARGET_LEN),

                // Algorithm and topology specific parameters
                // Mesh and Torus
                .MAX_ROUTERS_X(MAX_ROUTERS_X),
                .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
                .ROUTER_X(ROUTER_X),
                .ROUTER_Y(ROUTER_Y),
                
                // Circulant
                .ROUTER_N(ROUTER_N),
                .ROUTERS_COUNT(ROUTERS_COUNT),
                .GENERATICS_COUNT(GENERATICS_COUNT),
                .GENERATICS(GENERATICS)
            ) alg (
                .clk_i(clk_i), .rst_n_i(rst_n_i),

                .s_axis_i(arb_o_if),
                .m_axis_o(m_axis_o),

                .current_grant_i(current_grant),
                .target_i(target)
            );
        end
    endgenerate
    
endmodule
