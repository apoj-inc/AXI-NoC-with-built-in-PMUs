`include "defines.svh"
`include "axis_defines.svh"
`include "axi2axis_typedef.svh"

module algorithm_dual #(
    parameter AXIS_DATA_WIDTH = 40,
    parameter AXIS_ID_WIDTH = 4,
    parameter AXIS_DEST_WIDTH = 4,
    parameter AXIS_USER_WIDTH = 4,
    parameter CHANNEL_NUMBER = 10,
    parameter CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),
    parameter TARGET_LEN     = 0,

    // Algorithm and topology specific parameters
    // Mesh and Torus
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0,
    parameter USE_MESH_XY = 0,
    
    // Circulant
    parameter N = 0,
    parameter MAX_N = 0,
    parameter USE_CLOCKWISE = 0
) (
    input clk_i, rst_n_i,
    
    axis_if.s s_axis_i,
    axis_if.m m_axis_o [CHANNEL_NUMBER],

    input logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant_i,

    input logic [TARGET_LEN-1:0] target_i
);

    `GENERATE_AXIS_TYPEDEFS
    axis_mosi_t in_mosi_i, out_mosi_o[CHANNEL_NUMBER];
    axis_miso_t in_miso_o, out_miso_i[CHANNEL_NUMBER];

    `AXIS_INTERFACE_SLAVE2TYPEDEF(s_axis_i, in_mosi_i, in_miso_o)
    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER; i++) begin : typedef_to_interface
            `AXIS_INTERFACE_MASTER2TYPEDEF(m_axis_o[i], out_mosi_o[i], out_miso_i[i])
        end
    endgenerate

    logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y_i;
    assign target_y_i =
        target_i[MAX_ROUTERS_Y_WIDTH-1:0];
    logic [MAX_ROUTERS_X_WIDTH-1:0] target_x_i;
    assign target_x_i =
        target_i[MAX_ROUTERS_Y_WIDTH+MAX_ROUTERS_X_WIDTH-1 -: MAX_ROUTERS_X_WIDTH];

    logic [CHANNEL_NUMBER_WIDTH-1:0] ctrl;
    logic [CHANNEL_NUMBER-1:0] selector;

    logic [CHANNEL_NUMBER/2-1:0] selector_count;

    logic [CHANNEL_NUMBER-1:0] busy;
    logic [CHANNEL_NUMBER-1:0] busy_next;

    always_comb begin
        for (int i = 0; i < CHANNEL_NUMBER/2; i = i + 1) begin : selector_copier
            selector[i*2]   = selector_count[i];
            selector[i*2+1] = selector_count[i];
        end
    end

    generate

        if(USE_MESH_XY) begin
            algorithm_selector_mesh_XY #(
            .MAX_ROUTERS_X(MAX_ROUTERS_X), 
            .MAX_ROUTERS_Y(MAX_ROUTERS_Y), 
            .ROUTER_X(ROUTER_X),
            .ROUTER_Y(ROUTER_Y),
            .CHANNEL_NUMBER(CHANNEL_NUMBER)
            ) algorithm_selector (
                .target_x_i(target_x_i),
                .target_y_i(target_y_i),
                .selector_o(selector)
            );
        end else if(USE_CLOCKWISE) begin
            algorithm_selector_clockwise #(
            .MAX_ROUTERS_X(MAX_ROUTERS_X), 
            .MAX_ROUTERS_Y(MAX_ROUTERS_Y), 
            .ROUTER_X(ROUTER_X),
            .ROUTER_Y(ROUTER_Y),
            .CHANNEL_NUMBER(CHANNEL_NUMBER)
            ) algorithm_selector (
                .target_x_i(target_x_i),
                .target_y_i(target_y_i),
                .selector_o(selector)
            );
        end else $error("No algorithm specified!");

    endgenerate

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
        in_miso_o = ((in_mosi_i.data.TID != ROUTING_HEADER) || !busy[ctrl]) ? out_miso_i[ctrl] : '0;
        out_mosi_o[ctrl] = ((in_mosi_i.data.TID != ROUTING_HEADER) || !busy[ctrl]) ? in_mosi_i : '0;
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
        if (in_mosi_i.TVALID && (in_mosi_i.data.TID == ROUTING_HEADER)) begin
            busy_next[ctrl] = out_miso_i[ctrl].TREADY ? 1'b1 : busy[ctrl];
        end
        else if (in_mosi_i.TVALID) begin
            if (in_mosi_i.data.TLAST && out_miso_i[ctrl].TREADY) begin
                busy_next[ctrl] = 1'b0;
            end
        end
    end

endmodule