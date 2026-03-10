`include "defines.svh"

module router_dual #(
    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4,

    parameter        CHANNEL_NUMBER = 10,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),
    parameter        BUFFER_DEPTH = 16,
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

    localparam TARGET_LEN = COORDINATES == "XY" ?    MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH   :
                            COORDINATES == "N"  ?    $clog2(ROUTERS_COUNT)                       :
                                                     0                                           ;

    initial assert (TARGET_LEN != 0) else $error("Wrong coordintes configuration");
    
    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   queue_o_if         [CHANNEL_NUMBER  ] (),
        arb_o_if                              ();
    
    logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant;
    logic [TARGET_LEN-1:0] target;

    axis_fifo_buffer #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    ) q (
        .ACLK(clk_i),
        .ARESETn(rst_n_i),

        .s_axis_i(s_axis_i),
        .m_axis_o(queue_o_if)
    );

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

    algorithm_dual #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH),

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
    
endmodule
