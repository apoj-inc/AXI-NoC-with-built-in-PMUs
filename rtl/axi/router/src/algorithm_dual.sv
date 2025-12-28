`include "axi2axis_typedef.svh"

module algorithm_dual #(
    parameter DATA_WIDTH = 32
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
    `endif
    ,
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
    
    axis_if.s in,
    axis_if.m out [CHANNEL_NUMBER],

    input logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant,

    input logic [MAX_ROUTERS_X_WIDTH-1:0] target_x,
    input logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y
);

    axis_if #(
        .DATA_WIDTH(DATA_WIDTH)
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
    ) in_filtered();

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

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            busy <= '0;
        end else begin
            busy <= busy_next;
        end
    end

    always_comb begin
        busy_next = busy;
        if (in.TVALID && (in.TID == ROUTING_HEADER)) begin

            in_filtered.TVALID = !busy[ctrl] ? '1 : '0;
            in_filtered.TDATA  = !busy[ctrl] ? in.TDATA : '0;
            `ifdef TSTRB_PRESENT
            in_filtered.TSTRB  = !busy[ctrl] ? in.TSTRB : '0;
            `endif
            `ifdef TKEEP_PRESENT
            in_filtered.TKEEP  = !busy[ctrl] ? in.TKEEP : '0;
            `endif
            `ifdef TLAST_PRESENT
            in_filtered.TLAST  = !busy[ctrl] ? in.TLAST : '0;
            `endif
            `ifdef TID_PRESENT
            in_filtered.TID    = !busy[ctrl] ? in.TID : '0;
            `endif
            `ifdef TDEST_PRESENT
            in_filtered.TDEST  = !busy[ctrl] ? in.TDEST : '0;
            `endif
            `ifdef TUSER_PRESENT
            in_filtered.TUSER  = !busy[ctrl] ? in.TUSER : '0;
            `endif

            in.TREADY = !busy[ctrl] ? in_filtered.TREADY : 1'b0;
            busy_next[ctrl] = in_filtered.TREADY ? 1'b1 : busy[ctrl];
        end
        else if (in.TVALID) begin
            in_filtered.TVALID = in.TVALID;
            in_filtered.TDATA  = in.TDATA;
            `ifdef TSTRB_PRESENT
            in_filtered.TSTRB  = in.TSTRB;
            `endif
            `ifdef TKEEP_PRESENT
            in_filtered.TKEEP  = in.TKEEP;
            `endif
            `ifdef TLAST_PRESENT
            in_filtered.TLAST  = in.TLAST;
            `endif
            `ifdef TID_PRESENT
            in_filtered.TID    = in.TID;
            `endif
            `ifdef TDEST_PRESENT
            in_filtered.TDEST  = in.TDEST;
            `endif
            `ifdef TUSER_PRESENT
            in_filtered.TUSER  = in.TUSER;
            `endif

            in.TREADY = in_filtered.TREADY;

            if (in.TLAST && in_filtered.TREADY) begin
                busy_next[ctrl] = 1'b0;
            end
        end
        else begin
            in_filtered.TVALID = 1'b0;
            in_filtered.TDATA  = '0;
            `ifdef TSTRB_PRESENT
            in_filtered.TSTRB  = '0;
            `endif
            `ifdef TKEEP_PRESENT
            in_filtered.TKEEP  = '0;
            `endif
            `ifdef TLAST_PRESENT
            in_filtered.TLAST  = '0;
            `endif
            `ifdef TID_PRESENT
            in_filtered.TID    = '0;
            `endif
            `ifdef TDEST_PRESENT
            in_filtered.TDEST  = '0;
            `endif
            `ifdef TUSER_PRESENT
            in_filtered.TUSER  = '0;
            `endif

            in.TREADY = in_filtered.TREADY;
        end
    end

    axis_if_demux #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .DATA_WIDTH(DATA_WIDTH)
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
    ) demux (
        in_filtered,
        1'b1,
        ctrl,
        out
    );

endmodule