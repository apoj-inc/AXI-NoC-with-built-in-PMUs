`include "defines.svh"

module router_dual #(
    parameter AXIS_DATA_WIDTH = 40,
    parameter AXIS_ID_WIDTH = 4,
    parameter AXIS_DEST_WIDTH = 4,
    parameter AXIS_USER_WIDTH = 4,

    parameter CHANNEL_NUMBER = 10,
    parameter CHANNEL_NUMBER_WIDTH
    = $clog2(CHANNEL_NUMBER),
    parameter BUFFER_LENGTH = 16,
    parameter MAXIMUM_PACKAGES_NUMBER = 5,
    parameter MAXIMUM_PACKAGES_NUMBER_WIDTH
    = $clog2(MAXIMUM_PACKAGES_NUMBER - 1),

    parameter USE_X_Y_COORDINATES = 0,
    parameter USE_N_COORDINATES   = 0,
    
    // Algorithm and topology specific parameters
    // Mesh and Torus
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter MAX_PACKAGES = 4,
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0,
    parameter USE_MESH_XY = 0,
    
    // Circulant
    parameter N = 0,
    parameter MAX_N = 0,
    parameter USE_CLOCKWISE = 0
)(
    input  clk_i, rst_n_i,
    axis_if.s s_axis_i [CHANNEL_NUMBER],
    axis_if.m m_axis_o [CHANNEL_NUMBER]
);

    localparam TARGET_LEN = USE_X_Y_COORDINATES ?   MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH   :
                            USE_N_COORDINATES   ?   $clog2(N)                                   :
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
        .BUFFER_LENGTH(BUFFER_LENGTH),
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
        .CHANNEL_NUMBER  (CHANNEL_NUMBER),

        .TARGET_LEN(TARGET_LEN),

        // Algorithm and topology specific parameters
        // Mesh and Torus
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .ROUTER_X(ROUTER_X),
        .ROUTER_Y(ROUTER_Y),
        
        // Circulant
        .N(N),
        .MAX_N(MAX_N),
        .USE_CLOCKWISE(USE_CLOCKWISE)
    ) alg (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .s_axis_i(arb_o_if),
        .m_axis_o(m_axis_o),

        .current_grant_i(current_grant),

        .target_i(target)
    );
    
endmodule
