module algorithm_selector_clockwise #(
    parameter ROUTERS_COUNT = 6,
    parameter ROUTERS_COUNT_WIDTH = $clog2(ROUTERS_COUNT),
    parameter ROUTER_N = 0,
    parameter CHANNEL_NUMBER = 5,
    parameter GENERATICS_COUNT = 2,
    parameter int GENERATICS[GENERATICS_COUNT] = '{2, 1},
    parameter CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER)
) (
    input  logic [ROUTERS_COUNT_WIDTH-1:0]       target_i,
    output logic [CHANNEL_NUMBER_WIDTH-1:0]      selector_o
);
    logic [ROUTERS_COUNT_WIDTH:0] extended_target;
    logic [ROUTERS_COUNT_WIDTH-1:0] target_dif;

    assign extended_target = ROUTER_N > target_i ? target_i + ROUTERS_COUNT: target_i;
    assign target_dif = extended_target - ROUTER_N;

    always_comb begin
        selector_o = '0;

        if(target_dif == 0) begin
            selector_o = 0;
        end

        for (int i = GENERATICS_COUNT-1; i >= 0; i--) begin
            if(GENERATICS[i] <= target_dif) begin
                selector_o = i + 1;
            end
        end
    end

endmodule: algorithm_selector_clockwise
