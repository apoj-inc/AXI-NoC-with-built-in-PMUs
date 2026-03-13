`include "virtual_channels_utils.svh"

module channel_decoder #(
    parameter        PHYSICAL_CHANNEL_NUMBER = 8,
    parameter        PHYSICAL_CHANNEL_NUMBER_WIDTH = $clog2(PHYSICAL_CHANNEL_NUMBER),
    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        VIRTUAL_CHANNEL_NUMBER_WIDTH = $clog2(VIRTUAL_CHANNEL_NUMBER),
    parameter        CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER)
) (
    input  logic[CHANNEL_NUMBER_WIDTH-1:0] channel_number,
    output logic[PHYSICAL_CHANNEL_NUMBER_WIDTH-1:0] physical_channel_number,
    output logic[VIRTUAL_CHANNEL_NUMBER_WIDTH-1:0] virtual_channel_number
);

    `GENERATE_CALCULATE_PHYSICAL_CHANNEL
    `GENERATE_CALCULATE_VIRTUAL_CHANNEL

    logic[PHYSICAL_CHANNEL_NUMBER_WIDTH-1:0] physical_channel_number_lookup [CHANNEL_NUMBER];
    logic[VIRTUAL_CHANNEL_NUMBER_WIDTH-1:0]  virtual_channel_number_lookup  [CHANNEL_NUMBER];

    genvar current_channel;
    generate
        for(current_channel = 0; current_channel < CHANNEL_NUMBER; current_channel++) begin : case_channel
            assign physical_channel_number_lookup[current_channel] = calculate_physical_channel(current_channel);
            assign virtual_channel_number_lookup[current_channel]  =  calculate_virtual_channel(current_channel);
        end
    endgenerate

    always_comb begin
        physical_channel_number = physical_channel_number_lookup[channel_number];
        virtual_channel_number  =  virtual_channel_number_lookup[channel_number];
    end

endmodule : channel_decoder
