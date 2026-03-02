`include "defines.svh"
`include "axis_defines.svh"

module router_dual_parallel #(
    parameter AXIS_DATA_WIDTH = 40,
    parameter AXIS_ID_WIDTH = 4,
    parameter AXIS_DEST_WIDTH = 4,
    parameter AXIS_USER_WIDTH = 4,

    parameter CHANNEL_NUMBER = 10,
    parameter CHANNEL_NUMBER_WIDTH
    = $clog2(CHANNEL_NUMBER),
    parameter BUFFER_DEPTH = 16,
    parameter MAXIMUM_PACKAGES_NUMBER = 5,
    parameter MAXIMUM_PACKAGES_NUMBER_WIDTH
    = $clog2(MAXIMUM_PACKAGES_NUMBER - 1),

    parameter USE_XY_COORDINATES = 0,
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
    parameter USE_TORUS_XY = 0,
    
    // Circulant
    parameter ROUTER_N = 0,
    parameter ROUTERS_COUNT = 6,
    parameter USE_CLOCKWISE = 0,
    parameter GENERATICS_COUNT = 2,
    parameter int GENERATICS[GENERATICS_COUNT] = '{2, 1}
)(
    input clk_i, rst_n_i,
    axis_if.s s_axis_i [CHANNEL_NUMBER],
    axis_if.m m_axis_o [CHANNEL_NUMBER]
);

    localparam TARGET_LEN = USE_XY_COORDINATES ?    MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH   :
                            USE_N_COORDINATES  ?    $clog2(ROUTERS_COUNT)                       :
                                                    0                                           ;

    initial assert (TARGET_LEN != 0) else $error("Wrong coordintes configuration");
    
    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   queue_o_if         [CHANNEL_NUMBER  ] (),
        arb_i_req_axis_if  [CHANNEL_NUMBER/2] (),
        arb_i_resp_axis_if [CHANNEL_NUMBER/2] (),
        arb_o_req_if                          (),
        arb_o_resp_if                         (),
        alg_o_req_axis_if  [CHANNEL_NUMBER/2] (),
        alg_o_resp_axis_if [CHANNEL_NUMBER/2] ();
    
    logic [TARGET_LEN-1:0] target_resp, target_req;

    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER/2; i++) begin : interfaces_concat
            `AXIS_INTERFACE2INTERFACE(queue_o_if[i*2], arb_i_req_axis_if[i])
            `AXIS_INTERFACE2INTERFACE(queue_o_if[i*2+1], arb_i_resp_axis_if[i])

            `AXIS_INTERFACE2INTERFACE(alg_o_req_axis_if[i], m_axis_o[i*2])
            `AXIS_INTERFACE2INTERFACE(alg_o_resp_axis_if[i], m_axis_o[i*2+1])
        end
    endgenerate

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
        .CHANNEL_NUMBER(CHANNEL_NUMBER/2),

        .TARGET_LEN(TARGET_LEN)
    ) arb_req (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .s_axis_i(arb_i_req_axis_if),
        .m_axis_o(arb_o_req_if),

        // Mesh and Torus
        .target_o(target_req)
    ), arb_resp (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .s_axis_i(arb_i_resp_axis_if),
        .m_axis_o(arb_o_resp_if),

        .target_o(target_resp)
    );

    algorithm #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH),
        .CHANNEL_NUMBER(CHANNEL_NUMBER/2),

        .TARGET_LEN(TARGET_LEN),

        // Algorithm and topology specific parameters
        // Mesh and Torus
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .ROUTER_X(ROUTER_X),
        .ROUTER_Y(ROUTER_Y),
        .USE_MESH_XY(USE_MESH_XY),
        .USE_TORUS_XY(USE_TORUS_XY),
        .USE_XY_COORDINATES(USE_XY_COORDINATES),
        
        // Circulant
        .ROUTER_N(ROUTER_N),
        .ROUTERS_COUNT(ROUTERS_COUNT),
        .USE_CLOCKWISE(USE_CLOCKWISE),
        .GENERATICS_COUNT(GENERATICS_COUNT),
        .GENERATICS(GENERATICS)
    ) alg_req (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .s_axis_i(arb_o_req_if),
        .m_axis_o(alg_o_req_axis_if),

        .target_i(target_req)
    ), alg_resp (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .s_axis_i(arb_o_resp_if),
        .m_axis_o(alg_o_resp_axis_if),

        .target_i(target_resp)
    );

    
endmodule
