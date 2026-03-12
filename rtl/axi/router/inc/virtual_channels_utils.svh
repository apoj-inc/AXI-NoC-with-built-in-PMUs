`ifndef __VIRUAL_CHANNELS__UTILS__
`define __VIRUAL_CHANNELS__UTILS__

package virtualChannelsUtils;

    localparam VIRTUAL_CHANNEL_NUMBER = 2;

    function int calculate_physical_channel(int general_channel);
        return general_channel / (VIRTUAL_CHANNEL_NUMBER);
    endfunction

    function int calculate_virtual_channel(int general_channel);
        return general_channel % (VIRTUAL_CHANNEL_NUMBER);
    endfunction

    function int calculate_general_channel(int physical_channel, int virtual_channel);
        return physical_channel*VIRTUAL_CHANNEL_NUMBER+virtual_channel;
    endfunction

endpackage

`endif
