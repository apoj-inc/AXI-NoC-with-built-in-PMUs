module algorithm_selector_clockwise #(
    parameter ROUTERS_N = 6,
    parameter ROUTERS_N_WIDTH = $clog2(ROUTERS_N),
    parameter ROUTER_N = 0,
    parameter CHANNEL_NUMBER = 5,
    parameter GENERATICS_COUNT = 2,
    parameter int GENERATICS[GENERATICS_COUNT] = '{1, 2}
) (
    input  logic [ROUTERS_N_WIDTH-1:0]         target,
    output logic [CHANNEL_NUMBER-1:0]      selector_o
);
    logic [ROUTERS_N_WIDTH:0] extended_target;
    logic [ROUTERS_N_WIDTH-1:0] target_dif;

    assign extended_target = ROUTERS_N > target ? target + ROUTERS_N: target;
    assign target_dif = extended_target - ROUTERS_N;

    always_comb begin
        selector_o = '0;

        if(target_dif == 0) begin
            selector_o[0] = 1'b1;
        end

        for (int i = 0; i < $size(GENERATICS); i++) begin
            if(GENERATICS[i] <= target_dif) begin
                selector_o[i] = 1'b1;
            end
        end
    end

endmodule: algorithm_selector_clockwise
