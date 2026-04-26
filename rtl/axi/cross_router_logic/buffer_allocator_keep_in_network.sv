`include "defines.svh"
`include "axis_defines.svh"
`include "virtual_networks_utils.svh"

module buffer_allocator_keep_in_network #(
    parameter        PHYSICAL_CHANNEL_NUMBER = 5,
    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),

    parameter        VIRTUAL_NETWORK_NUMBER = 2,
    parameter int    VIRTUAL_NETWORKS[VIRTUAL_NETWORK_NUMBER] = '{1, 1},

    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4
) (
    input  ACLK, ARESETn,
    axis_if.s s_axis_i [CHANNEL_NUMBER],
    axis_if.m m_axis_o [CHANNEL_NUMBER]
);
    `GENERATE_AXIS_TYPEDEFS
    `GENERATE_CALCULATE_VIRTUAL_NETWORK_OFFSET

    genvar current_physical_channel, current_virtual_network, interface_virtual_channel;
    generate
        for(current_physical_channel = 0; current_physical_channel < PHYSICAL_CHANNEL_NUMBER; current_physical_channel++) begin: pc
            localparam PHYSICAL_OFFSET = current_physical_channel * VIRTUAL_CHANNEL_NUMBER;
            for(current_virtual_network = 0; current_virtual_network < VIRTUAL_NETWORK_NUMBER; current_virtual_network++) begin: vn
                localparam CHANNELS = VIRTUAL_NETWORKS[current_virtual_network];
                localparam OFFSET   = PHYSICAL_OFFSET + calculate_virtual_network_offset(current_virtual_network);
                if(CHANNELS == 1) begin
                    `AXIS_INTERFACE2INTERFACE(s_axis_i[OFFSET], m_axis_o[OFFSET])
                end else begin
                    // Variables
                    logic [$clog2(CHANNELS):0]   allocated_to [CHANNELS];
                    logic [$clog2(CHANNELS):0]   allocated_to_next [CHANNELS];
                    logic [CHANNELS:0] busy;
                    logic [CHANNELS:0] busy_next;
                    logic [$clog2(CHANNELS-1):0] current_channel;
                    logic done;
                    logic [$clog2(CHANNELS-1):0] target_channel;
                    // Interfaces
                    axis_mosi_t in_mosi_i[CHANNELS], out_mosi_o[CHANNELS];
                    axis_miso_t in_miso_o[CHANNELS], out_miso_i[CHANNELS];
                    for (interface_virtual_channel = 0; interface_virtual_channel < CHANNELS; interface_virtual_channel++) begin: vc
                        `AXIS_INTERFACE_MASTER2TYPEDEF(m_axis_o[interface_virtual_channel + OFFSET], out_mosi_o[interface_virtual_channel], out_miso_i[interface_virtual_channel])
                        `AXIS_INTERFACE_SLAVE2TYPEDEF(s_axis_i[interface_virtual_channel + OFFSET], in_mosi_i[interface_virtual_channel], in_miso_o[interface_virtual_channel])
                    end
                    // Main
                    always_comb begin
                        busy_next = busy;
                        allocated_to_next = allocated_to;

                        for (target_channel = 0; target_channel < CHANNELS; target_channel++) begin
                            if(out_mosi_o[target_channel].data.TLAST && out_miso_i[target_channel].TREADY) begin
                                busy_next[target_channel] = 1'b0;
                            end
                        end

                        target_channel = '0;
                        for (current_channel = '0; current_channel < CHANNELS; current_channel++) begin
                            done = 1'b0;
                            if(in_mosi_i[current_channel].TVALID && allocated_to[current_channel] == '1) begin
                                for (target_channel=target_channel; (target_channel < CHANNELS) && !done; target_channel++) begin
                                    if(!busy_next[target_channel] && out_miso_i[target_channel].TREADY) begin
                                        busy_next[target_channel] = 1'b1;
                                        done = 1'b1;
                                        allocated_to_next[current_channel] = target_channel;
                                    end
                                end
                            end
                        end
                        
                        
                        for (current_channel = 0; current_channel < CHANNELS; current_channel++) begin
                            if(!busy_next[allocated_to_next[current_channel]]) begin
                                allocated_to_next[current_channel] = '1;
                            end
                        end

                        for (current_channel = 0; current_channel < CHANNELS; current_channel++) begin
                            out_mosi_o[current_channel] = '0;
                            in_miso_o[current_channel] = '0;
                        end

                        for(current_channel = 0; current_channel < CHANNELS; current_channel++) begin
                            if(busy_next[allocated_to_next[current_channel]]) begin
                                out_mosi_o[allocated_to_next[current_channel]] = in_mosi_i[current_channel];
                                in_miso_o[current_channel] = out_miso_i[allocated_to_next[current_channel]];
                            end
                        end

                    end

                    always_ff @(posedge ACLK or negedge ARESETn) begin
                        if(!ARESETn) begin
                            busy <= '0;
                        end else begin
                            busy <= busy_next;
                        end
                    end

                    int alloc;
                    always_ff @(posedge ACLK or negedge ARESETn) begin
                        if(!ARESETn) begin
                            for(alloc = 0; alloc < CHANNELS; alloc++) begin
                                allocated_to[alloc] <= '1;
                            end
                        end else begin
                            allocated_to <= allocated_to_next;
                        end
                        alloc <= 0;
                    end
                end
            end
        end
    endgenerate
   
endmodule
