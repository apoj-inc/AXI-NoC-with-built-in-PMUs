`include "defines.svh"
`include "axis_defines.svh"

module buffer_allocator_straight #(
    parameter        PHYSICAL_CHANNEL_NUMBER = 8,
    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),

    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4
) (
    axis_if.s s_axis_i [CHANNEL_NUMBER],
    axis_if.m m_axis_o [CHANNEL_NUMBER]
);

    genvar allocated_channel;
    generate
        for(allocated_channel = 0; allocated_channel < CHANNEL_NUMBER; allocated_channel++) begin : straight_assignment
            `AXIS_INTERFACE2INTERFACE(s_axis_i[allocated_channel], m_axis_o[allocated_channel])
        end
    endgenerate
    
endmodule