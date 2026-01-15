`include "defines.svh"

module algorithm_dual #(
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
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0
) (
    input clk_i, rst_n_i,
    
    input  axis_mosi_t in_mosi_i,
    output axis_miso_t in_miso_o,
    output axis_mosi_t out_mosi_o [CHANNEL_NUMBER],
    input  axis_miso_t out_miso_i [CHANNEL_NUMBER],

    input logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant_i,

    input logic [MAX_ROUTERS_X_WIDTH-1:0] target_x_i,
    input logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y_i
);

    `include "axis_type.svh"

    logic [CHANNEL_NUMBER_WIDTH-1:0] ctrl;
    logic [CHANNEL_NUMBER-1:0] selector;

    logic [CHANNEL_NUMBER-1:0] busy;
    logic [CHANNEL_NUMBER-1:0] busy_next;

    assign selector[0] = ((target_x_i == ROUTER_X) && (target_y_i == ROUTER_Y));
    assign selector[1] = ((target_x_i == ROUTER_X) && (target_y_i == ROUTER_Y));

    assign selector[2] = (target_y_i < ROUTER_Y);
    assign selector[3] = (target_y_i < ROUTER_Y);

    assign selector[4] = (target_x_i > ROUTER_X);
    assign selector[5] = (target_x_i > ROUTER_X);

    assign selector[6] = (target_y_i > ROUTER_Y);
    assign selector[7] = (target_y_i > ROUTER_Y);

    assign selector[8] = (target_x_i < ROUTER_X);
    assign selector[9] = (target_x_i < ROUTER_X);

    always_comb begin
        ctrl = '0;
        for (int i = 0; i < CHANNEL_NUMBER; i++) begin
            int channel;
            channel = CHANNEL_NUMBER - 1 - i;
            if(selector[channel] && (channel[0] == current_grant_i[0])) begin
                ctrl = channel;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < CHANNEL_NUMBER; i++) begin
            out_mosi_o[i] = '0;
        end
        in_miso_o = out_miso_i[ctrl];
        out_mosi_o[ctrl] = in_mosi_i;
    end

    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            busy <= '0;
        end else begin
            busy <= busy_next;
        end
    end

    always_comb begin
        busy_next = busy;
        if (in_mosi_i.TVALID) begin
            if (in_mosi_i.data.TID == ROUTING_HEADER) begin
                busy_next[ctrl] = out_miso_i[ctrl].TREADY ? 1'b1 : busy[ctrl];
            end else if (in_mosi_i.data.TLAST && out_miso_i[ctrl].TREADY) begin
                busy_next[ctrl] = 1'b0;
            end
        end
    end

endmodule