`include "defines.svh"
`include "axis_defines.svh"

module router #(
    parameter AXIS_DATA_WIDTH = 40,
    parameter AXIS_ID_WIDTH = 4,
    parameter AXIS_DEST_WIDTH = 4,
    parameter AXIS_USER_WIDTH = 4,

    parameter CHANNEL_NUMBER = 5,
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

    `GENERATE_AXIS_TYPEDEFS
    axis_mosi_t in_mosi_i[CHANNEL_NUMBER], out_mosi_o[CHANNEL_NUMBER];
    axis_miso_t in_miso_o[CHANNEL_NUMBER], out_miso_o[CHANNEL_NUMBER];

    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER; i++) begin : typedef_to_interface
            `AXIS_INTERFACE_SLAVE2TYPEDEF(s_axis_i[i], in_mosi_i[i], in_miso_o[i])
            `AXIS_INTERFACE_MASTER2TYPEDEF(m_axis_o[i], out_mosi_o[i], out_miso_o[i])
        end
    endgenerate

    localparam TARGET_LEN = USE_X_Y_COORDINATES ?   MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH   :
                            USE_N_COORDINATES   ?   $clog2(N)                                   :
                                                    0                                           ;

    initial assert (TARGET_LEN != 0) else $error("Wrong coordintes configuration");

    axis_mosi_t queue_o_mosi [CHANNEL_NUMBER];
    axis_miso_t queue_o_miso [CHANNEL_NUMBER];

    axis_mosi_t arbiter_o_mosi;
    axis_miso_t arbiter_o_miso;

    logic [TARGET_LEN-1:0] target;

    axis_fifo_buffer #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .BUFFER_LENGTH(BUFFER_LENGTH),
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
        `ifdef TID_PRESENT
         ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
         ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
         ,
        .USER_WIDTH(USER_WIDTH)
        `endif
    ) q (
        .ACLK(clk_i),
        .ARESETn(rst_n_i),

        .in_mosi_i(in_mosi_i),
        .in_miso_o(in_miso_o),
        .out_mosi_o(queue_o_mosi),
        .out_miso_i(queue_o_miso)
    );

    arbiter #(
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
        `ifdef TID_PRESENT
         ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
         ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
         ,
        .USER_WIDTH(USER_WIDTH)
        `endif,
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .MAXIMUM_PACKAGES_NUMBER(MAXIMUM_PACKAGES_NUMBER),

        .TARGET_LEN(TARGET_LEN)
    ) arb (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .in_mosi_i(queue_o_mosi),
        .in_miso_o(queue_o_miso),

        .out_mosi_o(arbiter_o_mosi),
        .out_miso_i(arbiter_o_miso),

        .target_o(target)
    );

    algorithm #(
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
        `ifdef TID_PRESENT
         ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
         ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
         ,
        .USER_WIDTH(USER_WIDTH)
        `endif,
        .CHANNEL_NUMBER(CHANNEL_NUMBER),

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

        .in_mosi_i(arbiter_o_mosi),
        .in_miso_o(arbiter_o_miso),

        .out_mosi_o(out_mosi_o),
        .out_miso_i(out_miso_i),

        .target_i(target)
    );

    
endmodule
