`include "virtual_networks_utils.svh"

module channel_decoder #(
    parameter        PHISICAL_CHANNEL_NUMBER = 8,
    parameter        PHISICAL_CHANNEL_NUMBER_WIDTH = $clog2(PHISICAL_CHANNEL_NUMBER),
    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        VIRTUAL_NUMBER_WIDTH = $clog2(VIRTUAL_CHANNEL_NUMBER),
    parameter        CHANNEL_NUMBER = PHISICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER)
) (
    input  logic[CHANNEL_NUMBER_WIDTH-1:0] channel_number,
    output logic[PHISICAL_CHANNEL_NUMBER_WIDTH-1:0] phisical_channel_number,
    output logic[VIRTUAL_NUMBER_WIDTH-1:0] virtual_channel_number
);

    logic[PHISICAL_CHANNEL_NUMBER_WIDTH-1:0] phisical_channel_number_lookup [CHANNEL_NUMBER_WIDTH-1:0];
    logic[VIRTUAL_NUMBER_WIDTH-1:0]          virtual_channel_number_lookup  [CHANNEL_NUMBER_WIDTH-1:0];

    genvar current_channel;
    generate
        for(current_channel = 0; current_channel < CHANNEL_NUMBER; current_channel++) begin : case_channel
            assign phisical_channel_number_lookup[current_channel] = calculate_phisical_channel(current_channel, VIRTUAL_CHANNEL_NUMBER);
            assign virtual_channel_number_lookup[current_channel]  =  calculate_virtual_channel(current_channel, VIRTUAL_CHANNEL_NUMBER);
        end
    endgenerate

    always_comb begin
        phisical_channel_number = phisical_channel_number_lookup[channel_number];
        virtual_channel_number  =  virtual_channel_number_lookup[channel_number];
    end

endmodule : channel_decoder
