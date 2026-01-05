module algorithm_dual #(
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4,
    parameter DEST_WIDTH = 4,
    parameter USER_WIDTH = 4,
    parameter CHANNEL_NUMBER = 10,
    parameter CHANNEL_NUMBER_WIDTH
    = $clog2(CHANNEL_NUMBER),
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0
) (
    input clk, rst_n,
    
    input  axis_data_t in,
    input  logic  in_valid,
    output logic  in_ready,
    output axis_data_t out [CHANNEL_NUMBER],
    output logic  out_valid [CHANNEL_NUMBER],
    input  logic  out_ready [CHANNEL_NUMBER]

    input logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant,

    input logic [MAX_ROUTERS_X_WIDTH-1:0] target_x,
    input logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y
);

    `include "axi_type.svh"

    axis_data_t in_filtered;
    logic in_filtered_ready;
    logic in_filtered_valid;

    logic [CHANNEL_NUMBER_WIDTH-1:0] ctrl;
    logic [CHANNEL_NUMBER-1:0] selector;

    logic [CHANNEL_NUMBER-1:0] busy;
    logic [CHANNEL_NUMBER-1:0] busy_next;

    assign selector[0] = ((target_x == ROUTER_X) && (target_y == ROUTER_Y));
    assign selector[1] = ((target_x == ROUTER_X) && (target_y == ROUTER_Y));

    assign selector[2] = (target_y < ROUTER_Y);
    assign selector[3] = (target_y < ROUTER_Y);

    assign selector[4] = (target_x > ROUTER_X);
    assign selector[5] = (target_x > ROUTER_X);

    assign selector[6] = (target_y > ROUTER_Y);
    assign selector[7] = (target_y > ROUTER_Y);

    assign selector[8] = (target_x < ROUTER_X);
    assign selector[9] = (target_x < ROUTER_X);

    always_comb begin
        ctrl = '0;
        for (int i = 0; i < CHANNEL_NUMBER; i++) begin
            int channel;
            channel = CHANNEL_NUMBER - 1 - i;
            if(selector[channel] && (channel[0] == current_grant[0])) begin
                ctrl = channel;
            end
        end
    end

    assign out[ctrl] = in_filtered;
    assign out_valid[ctrl] = in_filtered_valid;
    assign in_filtered_ready = out_ready[ctrl];

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            busy <= '0;
        end else begin
            busy <= busy_next;
        end
    end

    always_comb begin
        busy_next = busy;
        if (in_valid && (in.TID == ROUTING_HEADER)) begin

            in_filtered_valid = !busy[ctrl] ? '1 : '0;
            in_filtered  = !busy[ctrl] ? in : '0;

            in_ready = !busy[ctrl] ? in_filtered_ready : 1'b0;
            busy_next[ctrl] = in_filtered_ready ? 1'b1 : busy[ctrl];
        end
        else if (in_valid) begin
            in_filtered_valid = in_valid;
            in_filtered  = in;
            in_ready = in_filtered_ready;

            if (in.TLAST && in_filtered_ready) begin
                busy_next[ctrl] = 1'b0;
            end
        end
        else begin
            in_filtered_valid = 1'b0;
            in_filtered  = '0;
            in_ready = in_filtered_ready;
        end
    end

endmodule