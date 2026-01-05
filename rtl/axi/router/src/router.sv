`include "defines.svh"

module router #(
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
    parameter CHANNEL_NUMBER = 5,
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
    input  clk, rst_n,
    input  axi_packet_t in  [CHANNEL_NUMBER],
    input  logic  in_valid  [CHANNEL_NUMBER],
    output logic  in_ready  [CHANNEL_NUMBER],
    output axi_packet_t out [CHANNEL_NUMBER],
    output logic  out_valid [CHANNEL_NUMBER],
    input  logic  out_ready [CHANNEL_NUMBER]
);

    `include "axis_type.svh"

    axis_data_t queue_out [CHANNEL_NUMBER],
    arbiter_out;

    logic queue_out_ready [CHANNEL_NUMBER];
    logic queue_out_valid [CHANNEL_NUMBER];

    logic arbiter_out_ready;
    logic arbiter_out_valid;

    logic [MAX_ROUTERS_X_WIDTH-1:0] target_x;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y;

    arbiter #(
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .MAXIMUM_PACKAGES_NUMBER(MAXIMUM_PACKAGES_NUMBER)
    ) arb (
        .clk(clk), .rst_n(rst_n),
        .in(queue_out),
        .in_ready(queue_out_ready),
        .in_valid(queue_out_valid),
        .out(arbiter_out),
        .out_ready(arbiter_out_ready),
        .out_valid(arbiter_out_valid),
        .target_x(target_x),
        .target_y(target_y)
    );

    algorithm #(
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .ROUTER_X(ROUTER_X),
        .ROUTER_Y(ROUTER_Y)
    ) alg (
        .clk(clk), .rst_n(rst_n),
        .in(arbiter_out),
        .in_ready(arbiter_out_ready),
        .in_valid(arbiter_out_valid),
        .out(out),
        .out_ready(out_ready),
        .out_valid(out_valid),
        .target_x(target_x),
        .target_y(target_y)
    );

    generate
        genvar i;
        for(i = 0; i < CHANNEL_NUMBER; i++) begin : axis_if_gen

            axis_data_t data_i, data_o;

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
