`include "defines.svh"

module router #(
    parameter AXIS_DATA_WIDTH = 40
    `ifdef TID_PRESENT
    ,
    parameter ID_WIDTH = 4
    `endif
    `ifdef TDEST_PRESENT
    ,
    parameter DEST_WIDTH = 4
    `endif
    `ifdef TUSER_PRESENT
    ,
    parameter USER_WIDTH = 4
    `endif,
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
    
    // Circulant
    parameter N = 0
)(
    input  clk_i, rst_n_i,
    input  axis_mosi_t in_mosi_i  [CHANNEL_NUMBER],
    output axis_miso_t in_miso_o  [CHANNEL_NUMBER],
    output axis_mosi_t out_mosi_o [CHANNEL_NUMBER],
    input  axis_miso_t out_miso_i [CHANNEL_NUMBER]
);

    localparam TARGET_LEN = USE_X_Y_COORDINATES ?   MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH   :
                            USE_N_COORDINATES   ?   $clog2(N)                                   :
                                                    0                                           ;

    initial assert (TARGET_LEN != 0) else $error("Wrong coordintes configuration");

    `include "axis_type.svh"

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
        .N(N)
    ) alg (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .in_mosi_i(arbiter_o_mosi),
        .in_miso_o(arbiter_o_miso),

        .out_mosi_o(out_mosi_o),
        .out_miso_i(out_miso_i),

        .target_i(target)
    );

    
endmodule
