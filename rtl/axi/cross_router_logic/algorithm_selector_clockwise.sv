module algorithm_selector_clockwise #(
    parameter MAX_N = 5,
    parameter MAX_N_WIDTH = $clog2(MAX_N),
    parameter N = 0,
    parameter CHANNEL_NUMBER = 5,
    parameter GENERATICS = {1, 2}
) (
    input  logic [MAX_N_WIDTH-1:0]         target,
    output logic [CHANNEL_NUMBER-1:0]      selector_o
);
    logic [MAX_N_WIDTH:0] extended_target;
    logic [MAX_N_WIDTH-1:0] target_dif;

    assign extended_target = N > target ? target + MAX_N + 1'b1: target;
    assign target_dif = extended_target - N;

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
