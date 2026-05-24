`include "XY_compas.svh"

module algorithm_selector_torus_XY_one_way #(
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0,
    parameter CHANNEL_NUMBER = 5
) (
    input  logic [MAX_ROUTERS_X_WIDTH-1:0] target_x_i,
    input  logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y_i,
    output logic [CHANNEL_NUMBER-1:0]      selector_o
);

    assign selector_o[HOME] = ((target_x_i == ROUTER_X) && (target_y_i == ROUTER_Y));
    assign selector_o[NORTH] = (target_y_i != ROUTER_Y);
    assign selector_o[EAST] = (target_x_i != ROUTER_X);
    assign selector_o[SOUTH] = '0;
    assign selector_o[WEST] = '0;

endmodule: algorithm_selector_torus_XY_one_way
