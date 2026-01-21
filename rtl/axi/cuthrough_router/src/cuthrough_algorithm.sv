module algorithm #(
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
    `endif
    ,
    parameter CHANNEL_NUMBER = 5,
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
    axis_if.m out,

    output logic [CHANNEL_NUMBER-1:0] selector
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

    logic [7:0] packages_left;

    logic busy;
    logic busy_next;

    logic [MAX_ROUTERS_X_WIDTH-1:0]  target_x;
    logic [MAX_ROUTERS_Y_WIDTH-1:0]  target_y;

    algorithm_selector #(
       .MAX_ROUTERS_X(MAX_ROUTERS_X), 
       .MAX_ROUTERS_Y(MAX_ROUTERS_Y), 
       .ROUTER_X(ROUTER_X),
       .ROUTER_Y(ROUTER_Y)
    ) (
        .target_x(target_x),
        .target_y(target_y),
        .selector(selector)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            busy <= '0;
        end else begin
            busy <= busy_next;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            target_x <= '0;
            target_y <= '0;
        end else begin
            if(in.TID == ROUTING_HEADER) begin
                target_y <= in.TDATA[
                    MAX_ROUTERS_X_WIDTH-1:0
                ];
                target_x <= in.TDATA[
                    MAX_ROUTERS_X_WIDTH+MAX_ROUTERS_Y_WIDTH-1:
                    MAX_ROUTERS_X_WIDTH
                ];
            end
        end
    end

    always_comb begin
        busy_next = busy;
        if (in.TVALID && (in.TID == ROUTING_HEADER)) begin

            in_filtered.TVALID = !busy ? '1 : '0;
            in_filtered.TDATA  = !busy ? in.TDATA : '0;
            `ifdef TSTRB_PRESENT
            in_filtered.TSTRB  = !busy ? in.TSTRB : '0;
            `endif
            `ifdef TKEEP_PRESENT
            in_filtered.TKEEP  = !busy ? in.TKEEP : '0;
            `endif
            `ifdef TLAST_PRESENT
            in_filtered.TLAST  = !busy ? in.TLAST : '0;
            `endif
            `ifdef TID_PRESENT
            in_filtered.TID    = !busy ? in.TID : '0;
            `endif
            `ifdef TDEST_PRESENT
            in_filtered.TDEST  = !busy ? in.TDEST : '0;
            `endif
            `ifdef TUSER_PRESENT
            in_filtered.TUSER  = !busy ? in.TUSER : '0;
            `endif

            in.TREADY = !busy ? in_filtered.TREADY : 1'b0;
            busy_next = in_filtered.TREADY ? 1'b1 : busy;
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
                busy_next = 1'b0;
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

endmodule