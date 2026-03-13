`include "defines.svh"
`include "axis_defines.svh"

// TODO Not tested, just a blueprint. Tesbench before use!
module buffer_allocator_keep_in_network #(
    parameter        PHYSICAL_CHANNEL_NUMBER = 8,
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

    logic [CHANNEL_NUMBER-1:0] busy;
    logic [CHANNEL_NUMBER-1:0] busy_next;
    logic [CHANNEL_NUMBER_WIDTH-1:0] allocated_to[CHANNEL_NUMBER];
    logic [CHANNEL_NUMBER_WIDTH-1:0] allocated_to_next[CHANNEL_NUMBER];

    int current_virtual_network;
    int current_physical_channel, current_first_channel, current_channel, target_channel;
    int done;
    always_comb begin
        busy_next = busy;
        current_channel = 0;
        current_first_channel = 0;
        allocated_to_next = allocated_to;
        for(current_physical_channel = 0; current_physical_channel < PHYSICAL_CHANNEL_NUMBER; current_physical_channel++) begin
            for(current_virtual_network = 0; current_virtual_network < VIRTUAL_NETWORK_NUMBER; current_virtual_network++) begin
                target_channel = current_first_channel;
                for(current_channel = current_first_channel; current_channel < current_first_channel + VIRTUAL_NETWORKS[current_virtual_network]; current_channel++) begin
                    done = 1'b0;
                    if(in_mosi_i[current_channel].TVALID) begin
                        for (; (target_channel < current_first_channel + VIRTUAL_NETWORKS[current_virtual_network]) && !done; target_channel++) begin
                            if(!busy[target_channel] && out_miso_i[target_channel].TREADY) begin
                                busy_next[target_channel] = 1'b1;
                                done = 1'b1;
                                allocated_to_next[target_channel] = current_channel;
                            end
                            
                        end
                    end
                end
                current_first_channel = current_channel;
            end
        end

        for (target_channel = 0; target_channel < CHANNEL_NUMBER; target_channel++) begin
            if(s_axis_i.TLAST && m_axis_o.TREADY) begin
                busy_next[target_channel] = 1'b0;
            end
        end

    end

    int allocated_channel;
    int allocation_shift;
    always_comb begin
        allocation_shift = 0;
        for(allocated_channel = 0; allocated_channel < CHANNEL_NUMBER; allocated_channel++) begin
            if(busy[allocated_channel]) begin
                `AXIS_INTERFACE2INTERFACE(m_axis_o[allocated_channel], s_axis_i[allocated_to_next[allocated_channel]])
                allocation_shift++;
            end else begin
                `AXIS_INTERFACE2INTERFACE(m_axis_o[allocated_channel], s_axis_i[allocated_channel + allocation_shift])
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
            for(alloc = 0; alloc < CHANNEL_NUMBER; alloc++) begin
                allocated_to[alloc] <= '0;
            end
        end else begin
            allocated_to <= allocated_to_next;
        end
    end
    
endmodule