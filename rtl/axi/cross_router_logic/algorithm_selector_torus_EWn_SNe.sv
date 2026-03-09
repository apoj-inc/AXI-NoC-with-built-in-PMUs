`include "XY_compas.svh"

module algorithm_selector_torus_EWn_SNe #(
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH = $clog2(MAX_ROUTERS_Y),
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0,
    parameter CHANNEL_NUMBER = 5,
    parameter CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER)
) (
    input  logic [MAX_ROUTERS_X_WIDTH-1:0]  target_x_i,
    input  logic [MAX_ROUTERS_Y_WIDTH-1:0]  target_y_i,
    output logic [CHANNEL_NUMBER_WIDTH-1:0] selector_o
);

    localparam CRITICAL_X = MAX_ROUTERS_X / 2;
    localparam CRITICAL_Y = MAX_ROUTERS_Y / 2;

    logic [MAX_ROUTERS_X_WIDTH:0] distance_x;
    logic [MAX_ROUTERS_Y_WIDTH:0] distance_y;
    logic take_arc_x;
    logic take_arc_y;

    assign distance_x = target_x_i < ROUTER_X ? ROUTER_X - target_x_i : target_x_i - ROUTER_X;
    assign distance_y = target_y_i < ROUTER_Y ? ROUTER_Y - target_y_i : target_y_i - ROUTER_Y;
    assign take_arc_x = distance_x > CRITICAL_X;
    assign take_arc_y = distance_y > CRITICAL_Y;

    logic [CHANNEL_NUMBER_WIDTH-1:0] selector_XY;

    algorithm_selector_mesh_XY #(
        .MAX_ROUTERS_X  (MAX_ROUTERS_X ),
        .MAX_ROUTERS_Y  (MAX_ROUTERS_Y ),
        .ROUTER_X       (ROUTER_X      ),
        .ROUTER_Y       (ROUTER_Y      ),
        .CHANNEL_NUMBER (CHANNEL_NUMBER)
    ) XY_selector (
        .target_x_i(target_x_i),
        .target_y_i(target_y_i),
        .selector_o(selector_XY)
    );

    always_comb begin
        if (ROUTER_X > target_x_i && ROUTER_Y > target_y_i && take_arc_x) begin
            selector_o = EAST;
        end
        else if (ROUTER_X < target_x_i && ROUTER_Y > target_y_i && take_arc_y) begin
            selector_o = SOUTH;
        end
        else begin
            selector_o = selector_XY;
        end
    end

endmodule
