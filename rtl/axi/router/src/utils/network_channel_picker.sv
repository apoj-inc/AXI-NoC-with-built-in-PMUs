`include "axis_defines.svh"
`include "virtual_networks_utils.svh"

module network_channel_picker #(
    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4,

    parameter        PHYSICAL_CHANNEL_NUMBER = 5,
    parameter        PHYSICAL_CHANNEL_NUMBER_WIDTH = $clog2(PHYSICAL_CHANNEL_NUMBER),
    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),

    parameter        SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING = 0,
    parameter        VIRTUAL_NETWORK_NUMBER = 2,
    parameter int    VIRTUAL_NETWORKS[VIRTUAL_NETWORK_NUMBER] = '{1, 1}
    ) (
        axis_if.m m_axis_dem [CHANNEL_NUMBER],
        axis_if.s s_axis_dem [CHANNEL_NUMBER],
        axis_if.m m_axis_mux [CHANNEL_NUMBER],
        axis_if.s s_axis_mux [CHANNEL_NUMBER]
    );

    `GENERATE_CALCULATE_VIRTUAL_NETWORK_OFFSET

    genvar current_virtual_network, current_physical_channel, current_virtual_channel;
    generate
        for (current_virtual_network = 0; current_virtual_network < VIRTUAL_NETWORK_NUMBER; current_virtual_network++) begin : simultainious_network_routing_gen
                localparam VIRTUAL_NETWORK_OFFSET = calculate_virtual_network_offset(current_virtual_network);
                localparam VIRTUAL_NETWORKS_OFFSET = VIRTUAL_NETWORK_OFFSET*PHYSICAL_CHANNEL_NUMBER;
                localparam VIRTUAL_NETWORK_CHANNELS = VIRTUAL_NETWORKS[current_virtual_network];
                localparam CHANNELS_IN_NETWORK = VIRTUAL_NETWORK_CHANNELS*PHYSICAL_CHANNEL_NUMBER;
                
                for(current_physical_channel = 0; current_physical_channel < PHYSICAL_CHANNEL_NUMBER; current_physical_channel++) begin : physical_channels_mapping
                    for(current_virtual_channel = 0; current_virtual_channel < VIRTUAL_NETWORK_CHANNELS; current_virtual_channel++) begin : virtual_channels_mapping
                        localparam ORIGINAL_CHANNEL = current_physical_channel * VIRTUAL_CHANNEL_NUMBER+VIRTUAL_NETWORK_OFFSET + current_virtual_channel;
                        localparam MAPPED_CHANNEL   = VIRTUAL_NETWORKS_OFFSET + current_physical_channel * VIRTUAL_NETWORK_CHANNELS + current_virtual_channel;
                        
                        `AXIS_INTERFACE2INTERFACE(m_axis_dem[ORIGINAL_CHANNEL], s_axis_dem[MAPPED_CHANNEL]  )
                        `AXIS_INTERFACE2INTERFACE(m_axis_mux[MAPPED_CHANNEL],   s_axis_mux[ORIGINAL_CHANNEL])
                    end
                end
        end
    endgenerate

endmodule : network_channel_picker
