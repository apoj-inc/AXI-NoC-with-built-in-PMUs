`include "defines.svh"

module router_dual_parallel #(
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
    input clk_i, rst_n_i,
    input  axis_mosi_t in_mosi_i  [CHANNEL_NUMBER],
    output axis_miso_t in_miso_o  [CHANNEL_NUMBER],
    output axis_mosi_t out_mosi_o [CHANNEL_NUMBER],
    input  axis_miso_t out_miso_i [CHANNEL_NUMBER]
);

    `include "axis_type.svh"

    axis_mosi_t queue_o_mosi [CHANNEL_NUMBER];
    axis_miso_t queue_o_miso [CHANNEL_NUMBER];

    axis_mosi_t arb_req_axis_i_mosi [CHANNEL_NUMBER/2];
    axis_miso_t arb_req_axis_i_miso [CHANNEL_NUMBER/2];

    axis_mosi_t arb_resp_axis_i_mosi [CHANNEL_NUMBER/2];
    axis_miso_t arb_resp_axis_i_miso [CHANNEL_NUMBER/2];

    axis_mosi_t arbiter_o_req_mosi, arbiter_o_resp_mosi;
    axis_miso_t arbiter_o_req_miso, arbiter_o_resp_miso;

    axis_mosi_t alg_req_axis_o_mosi [CHANNEL_NUMBER/2];
    axis_miso_t alg_req_axis_o_miso [CHANNEL_NUMBER/2];

    axis_mosi_t alg_resp_axis_o_mosi [CHANNEL_NUMBER/2];
    axis_miso_t alg_resp_axis_o_miso [CHANNEL_NUMBER/2];
    
    logic [$clog2(CHANNEL_NUMBER/2)-1:0] current_grant_req, current_grant_resp;
    logic [MAX_ROUTERS_X_WIDTH-1:0] target_x_req, target_x_resp;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y_req, target_y_resp;

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

    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER/2; i++) begin : interfaces_concat
            assign arb_req_axis_i_mosi[i] = queue_o_mosi[i*2];
            assign queue_o_miso[i*2] = arb_req_axis_i_miso[i];

            assign arb_resp_axis_i_mosi[i] = queue_o_mosi[i*2+1];
            assign queue_o_miso[i*2+1] = arb_resp_axis_i_miso[i];

            assign out_mosi_o[i*2]   = alg_req_axis_o_mosi[i];
            assign alg_req_axis_o_miso[i]  = out_miso_i[i*2];

            assign out_mosi_o[i*2+1] = alg_resp_axis_o_mosi[i];
            assign alg_resp_axis_o_miso[i] =  out_miso_i[i*2+1];
        end
    endgenerate

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
        .CHANNEL_NUMBER(CHANNEL_NUMBER/2),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .MAXIMUM_PACKAGES_NUMBER(MAXIMUM_PACKAGES_NUMBER)
    ) arb_req (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .in_mosi_i(arb_req_axis_i_mosi),
        .in_miso_o(arb_req_axis_i_miso),

        .out_mosi_o(arbiter_o_req_mosi),
        .out_miso_i(arbiter_o_req_miso),

        .target_x_o(target_x_req),
        .target_y_o(target_y_req)
    ), arb_resp (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .in_mosi_i(arb_resp_axis_i_mosi),
        .in_miso_o(arb_resp_axis_i_miso),

        .out_mosi_o(arbiter_o_resp_mosi),
        .out_miso_i(arbiter_o_resp_miso),

        .target_x_o(target_x_resp),
        .target_y_o(target_y_resp)
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
        .CHANNEL_NUMBER(CHANNEL_NUMBER/2),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .ROUTER_X(ROUTER_X),
        .ROUTER_Y(ROUTER_Y)
    ) alg_req (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .in_mosi_i(arbiter_o_req_mosi),
        .in_miso_o(arbiter_o_req_miso),

        .out_mosi_o(alg_req_axis_o_mosi),
        .out_miso_i(alg_req_axis_o_miso),

        .target_x_i(target_x_req),
        .target_y_i(target_y_req)
    ), alg_resp (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .in_mosi_i(arbiter_o_resp_mosi),
        .in_miso_o(arbiter_o_resp_miso),

        .out_mosi_o(alg_resp_axis_o_mosi),
        .out_miso_i(alg_resp_axis_o_miso),

        .target_x_i(target_x_resp),
        .target_y_i(target_y_resp)
    );

    
endmodule
