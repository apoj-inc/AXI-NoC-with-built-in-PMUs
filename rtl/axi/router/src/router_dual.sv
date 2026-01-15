`include "defines.svh"

module router_dual #(
    parameter AXIS_DATA_WIDTH = 32
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
    parameter CHANNEL_NUMBER = 10,
    parameter CHANNEL_NUMBER_WIDTH
    = $clog2(CHANNEL_NUMBER),
    parameter BUFFER_LENGTH = 16,
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter MAX_PACKAGES = 4,
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0,
    parameter MAXIMUM_PACKAGES_NUMBER = 5,
    parameter MAXIMUM_PACKAGES_NUMBER_WIDTH
    = $clog2(MAXIMUM_PACKAGES_NUMBER - 1)
)(
    input  clk_i, rst_n_i,
    input  axis_mosi_t in_mosi_i  [CHANNEL_NUMBER],
    output axis_miso_t in_miso_o  [CHANNEL_NUMBER],
    output axis_mosi_t out_mosi_o [CHANNEL_NUMBER],
    input  axis_miso_t out_miso_i [CHANNEL_NUMBER]
);

    `include "axis_type.svh"

    axis_mosi_t queue_o_mosi [CHANNEL_NUMBER];
    axis_miso_t queue_o_miso [CHANNEL_NUMBER];

    axis_mosi_t arbiter_o_mosi;
    axis_miso_t arbiter_o_miso;
    
    logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant;
    logic [MAX_ROUTERS_X_WIDTH-1:0] target_x;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y;

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
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .MAXIMUM_PACKAGES_NUMBER(MAXIMUM_PACKAGES_NUMBER)
    ) arb (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .in_mosi_i(queue_o_mosi),
        .in_miso_o(queue_o_miso),

        .out_mosi_o(arbiter_o_mosi),
        .out_miso_i(arbiter_o_miso),

        .target_x_o(target_x),
        .target_y_o(target_y)
    );

    algorithm_dual #(
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
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .ROUTER_X(ROUTER_X),
        .ROUTER_Y(ROUTER_Y)
    ) alg (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .in_mosi_i(arbiter_o_mosi),
        .in_miso_o(arbiter_o_miso),

        .out_mosi_o(out_mosi_o),
        .out_miso_i(out_miso_i),

        .target_x_i(target_x),
        .target_y_i(target_y)
    );
    
endmodule
