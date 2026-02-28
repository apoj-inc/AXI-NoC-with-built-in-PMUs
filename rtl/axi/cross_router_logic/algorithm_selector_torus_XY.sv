module algorithm_selector_torus_XY #(
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

    logic [MAX_ROUTERS_X_WIDTH:0] distance_x;
    logic [MAX_ROUTERS_Y_WIDTH:0] distance_y;

    logic [MAX_ROUTERS_X_WIDTH:0] reverse_distance_x;
    logic [MAX_ROUTERS_Y_WIDTH:0] reverse_distance_y;

    assign distance_x = (MAX_ROUTERS_X + ROUTER_X - target_x_i) % MAX_ROUTERS_X;
    assign distance_y = (MAX_ROUTERS_Y + ROUTER_Y - target_y_i) % MAX_ROUTERS_Y;

    assign reverse_distance_x = (MAX_ROUTERS_X + target_x_i - ROUTER_X) % MAX_ROUTERS_X;
    assign reverse_distance_y = (MAX_ROUTERS_Y + target_y_i - ROUTER_Y) % MAX_ROUTERS_Y;

    assign selector_o[0] = ((target_x_i == ROUTER_X) && (target_y_i == ROUTER_Y));
    assign selector_o[1] = (reverse_distance_y < distance_y) && (target_y_i != ROUTER_Y); // Down
    assign selector_o[2] = (distance_x > reverse_distance_x) && (target_x_i != ROUTER_X); // Left
    assign selector_o[3] = (reverse_distance_y >= distance_y) && (target_y_i != ROUTER_Y); // Up
    assign selector_o[4] = (distance_x <= reverse_distance_x) && (target_x_i != ROUTER_X); // Right
endmodule: algorithm_selector_torus_XY
