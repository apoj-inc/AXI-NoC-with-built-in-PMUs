module router_dual_parallel #(
    parameter DATA_WIDTH = 32,
    `ifdef TID_PRESENT
    parameter ID_WIDTH = 4,
    `else
    parameter ID_WIDTH = 0,
    `endif
    `ifdef TDEST_PRESENT
    parameter DEST_WIDTH = 4,
    `else
    parameter DEST_WIDTH = 0,
    `endif
    `ifdef TUSER_PRESENT
    parameter USER_WIDTH = 4,
    `else
    parameter USER_WIDTH = 0,
    `endif
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
    input clk, rst_n,
    input  axis_data_t in  [CHANNEL_NUMBER],
    input  logic  in_valid  [CHANNEL_NUMBER],
    output logic  in_ready  [CHANNEL_NUMBER],
    output axis_data_t out [CHANNEL_NUMBER],
    output logic  out_valid [CHANNEL_NUMBER],
    input  logic  out_ready [CHANNEL_NUMBER]
);

    `include "axis_type.svh"

    axis_data_t queue_out [CHANNEL_NUMBER],
    arbiter_out_req, arbiter_out_resp,
    arb_req_axis [CHANNEL_NUMBER/2],
    arb_resp_axis [CHANNEL_NUMBER/2],
    alg_req_axis [CHANNEL_NUMBER/2],
    alg_resp_axis [CHANNEL_NUMBER/2];

    logic queue_out_ready [CHANNEL_NUMBER];
    logic queue_out_valid [CHANNEL_NUMBER];

    logic arbiter_out_ready;
    logic arbiter_out_valid;

    logic arb_req_axis_ready [CHANNEL_NUMBER/2],
    logic arb_req_axis_valid [CHANNEL_NUMBER/2],

    logic arb_resp_axis_ready [CHANNEL_NUMBER/2],
    logic arb_resp_axis_valid [CHANNEL_NUMBER/2],

    logic alg_req_axis_ready [CHANNEL_NUMBER/2],
    logic alg_req_axis_valid [CHANNEL_NUMBER/2],

    logic alg_resp_axis_ready [CHANNEL_NUMBER/2];
    logic alg_resp_axis_valid [CHANNEL_NUMBER/2];
    
    logic [$clog2(CHANNEL_NUMBER/2)-1:0] current_grant_req, current_grant_resp;
    logic [MAX_ROUTERS_X_WIDTH-1:0] target_x_req, target_x_resp;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y_req, target_y_resp;

    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER/2; i++) begin : interfaces_concat
            assign arb_req_axis_valid[i] = queue_out_valid[i*2];
            assign queue_out_ready[i*2]  = arb_req_axis_ready[i];
            assign arb_req_axis[i]       = queue_out[i*2];

            
            assign arb_resp_axis_valid[i]   = queue_out_valid[i*2 + 1];
            assign queue_out_ready[i*2 + 1] = arb_resp_axis_ready[i];
            assign arb_resp_axis[i]         = queue_out[i*2 + 1];

            assign out_valid[i*2]        = alg_req_axis_valid[i];
            assign alg_req_axis_ready[i] = out_ready[i*2];
            assign out[i*2]              = alg_req_axis[i];

            assign out_valid[i*2 + 1]     = alg_resp_axis_valid[i];
            assign alg_resp_axis_ready[i] = out_ready[i*2 + 1];
            assign out[i*2 + 1]           = alg_resp_axis[i];
        end
        
    endgenerate
    arbiter #(
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .CHANNEL_NUMBER(CHANNEL_NUMBER/2),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .MAXIMUM_PACKAGES_NUMBER(MAXIMUM_PACKAGES_NUMBER)
    ) arb_req (
        .clk(clk), .rst_n(rst_n),
        .in(arb_req_axis),
        .in_ready(arb_req_axis_ready),
        .in_valid(arb_req_axis_valid),
        .out(arbiter_out_req),
        .out_ready(arbiter_out_req_ready),
        .out_valid(arbiter_out_req_valid),
        .current_grant(current_grant_req),
        .target_x(target_x_req),
        .target_y(target_y_req)
    ), arb_resp (
        .clk(clk), .rst_n(rst_n),
        .in(arb_resp_axis),
        .in_ready(arb_resp_axis_ready),
        .in_valid(arb_resp_axis_valid),
        .out(arbiter_out_resp),
        .out_ready(arbiter_out_resp_ready),
        .out_valid(arbiter_out_resp_valid),
        .current_grant(current_grant_resp),
        .target_x(target_x_resp),
        .target_y(target_y_resp)
    );

    algorithm #(
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .CHANNEL_NUMBER(CHANNEL_NUMBER/2),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .ROUTER_X(ROUTER_X),
        .ROUTER_Y(ROUTER_Y)
    ) alg_req (
        .clk(clk), .rst_n(rst_n),
        .in(arbiter_out_req),
        .in_ready(arbiter_out_req_ready),
        .in_valid(arbiter_out_req_valid),
        .out(alg_req_axis),
        .out_ready(alg_req_axis_ready),
        .out_valid(alg_req_axis_valid),
        .target_x(target_x_req),
        .target_y(target_y_req)
    ), alg_resp (
        .clk(clk), .rst_n(rst_n),
        .in(arbiter_out_resp),
        .in_ready(arbiter_out_resp_ready),
        .in_valid(arbiter_out_resp_valid),
        .out(alg_resp_axis),
        .out_ready(alg_resp_axis_ready),
        .out_valid(alg_resp_axis_valid),
        .target_x(target_x_resp),
        .target_y(target_y_resp)
    );

    generate
        for(i = 0; i < CHANNEL_NUMBER; i++) begin : axis_if_gen

            queue_datatype data_i, data_o;

            assign data_i = in[i];
            assign queue_out[i] = data_o;

            stream_fifo #(
                .DATA_WIDTH($bits(data_i)),
                .FIFO_LEN(BUFFER_LENGTH)
            ) q (
                .ACLK(clk),
                .ARESETn(rst_n),
                
                .data_i(data_i),
                .valid_i(in_valid[i]),
                .ready_o(in_ready[i]),
                
                .data_o(data_o),
                .valid_o(queue_out_valid[i]),
                .ready_i(queue_out_ready[i])
            );

        end
    endgenerate

    
endmodule
