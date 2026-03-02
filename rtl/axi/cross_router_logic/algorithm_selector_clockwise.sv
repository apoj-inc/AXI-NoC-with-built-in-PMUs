module algorithm_selector_clockwise #(
    parameter ROUTERS_COUNT = 6,
    parameter ROUTERS_COUNT_WIDTH = $clog2(ROUTERS_COUNT),
    parameter ROUTER_N = 0,
    parameter CHANNEL_NUMBER = 5,
    parameter GENERATICS_COUNT = 2,
    parameter int GENERATICS[GENERATICS_COUNT] = '{2, 1}
) (
    input  logic [ROUTERS_COUNT_WIDTH-1:0]       target_i,
    output logic [CHANNEL_NUMBER-1:0]      selector_o
);
    logic [ROUTERS_COUNT_WIDTH:0] extended_target;
    logic [ROUTERS_COUNT_WIDTH-1:0] target_dif;

    assign extended_target = ROUTER_N > target_i ? target_i + ROUTERS_COUNT: target_i;
    assign target_dif = extended_target - ROUTER_N;

    always_comb begin
        selector_o = '0;

        if(target_dif == 0) begin
            selector_o[0] = 1'b1;
        end

        for (int i = 0; i < GENERATICS_COUNT; i++) begin
            if(GENERATICS[i] <= target_dif) begin
                selector_o[i+1] = 1'b1;
            end
        end
    end

endmodule: algorithm_selector_clockwise
