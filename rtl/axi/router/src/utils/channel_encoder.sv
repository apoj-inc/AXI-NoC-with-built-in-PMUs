`include "virtual_networks_utils.svh"

module channel_encoder #(
    parameter        PHYSICAL_CHANNEL_NUMBER = 8,
    parameter        PHYSICAL_CHANNEL_NUMBER_WIDTH = $clog2(PHYSICAL_CHANNEL_NUMBER),
    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        VIRTUAL_CHANNEL_NUMBER_WIDTH = $clog2(VIRTUAL_CHANNEL_NUMBER),
    parameter        CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER)
) (
    input  logic[PHYSICAL_CHANNEL_NUMBER_WIDTH-1:0] physical_channel_number,
    input  logic[VIRTUAL_CHANNEL_NUMBER_WIDTH-1:0] virtual_channel_number,
    output logic[CHANNEL_NUMBER_WIDTH-1:0] channel_number
);

    logic[CHANNEL_NUMBER_WIDTH-1:0] channel_number_lookup [PHYSICAL_CHANNEL_NUMBER][VIRTUAL_CHANNEL_NUMBER];

    genvar current_physical_channel, current_virtual_channel;
    generate
        for(current_physical_channel = 0; current_physical_channel < PHYSICAL_CHANNEL_NUMBER; current_physical_channel++) begin : case_physical_channel
            for(current_virtual_channel = 0; current_virtual_channel < VIRTUAL_CHANNEL_NUMBER; current_virtual_channel++) begin : case_virtual_channel
                assign channel_number_lookup[current_physical_channel][current_virtual_channel] = calculate_general_channel(current_physical_channel, current_virtual_channel, VIRTUAL_CHANNEL_NUMBER);
            end
        end
    endgenerate

    always_comb begin
        channel_number = channel_number_lookup[physical_channel_number][virtual_channel_number];
    end

endmodule : channel_encoder
