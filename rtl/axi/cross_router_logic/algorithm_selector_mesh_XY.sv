`include "XY_compas.svh"

module algorithm_selector_mesh_XY #(
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

    always_comb begin
        if (target_x_i > ROUTER_X) begin
            selector_o = EAST;
        end
        else if (target_x_i < ROUTER_X) begin
            selector_o = WEST;
        end
        else if (target_y_i > ROUTER_Y) begin
            selector_o = SOUTH;
        end
        else if (target_y_i < ROUTER_Y) begin
            selector_o = NORTH;
        end
        else begin
            selector_o = HOME;
        end
    end
    
endmodule