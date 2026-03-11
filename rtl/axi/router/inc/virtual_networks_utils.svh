`ifndef __VIRUAL_NETWORK__UTILS__
`define __VIRUAL_NETWORK__UTILS__

function int calculate_virtual_network_offset(int current_virtual_network, int VIRTUAL_NETWORKS[]);
    automatic int res = 0;
    for (int i = 0; i < current_virtual_network; i++) begin
        res += VIRTUAL_NETWORKS[i];
    end
    return res;
endfunction

function int calculate_physical_channel(int general_channel, int VIRTUAL_CHANNEL_NUMBER);
    return general_channel / (VIRTUAL_CHANNEL_NUMBER);
endfunction

function int calculate_virtual_channel(int general_channel, int VIRTUAL_CHANNEL_NUMBER);
    return general_channel % (VIRTUAL_CHANNEL_NUMBER);
endfunction

function int calculate_general_channel(int physical_channel, int virtual_channel, int VIRTUAL_CHANNEL_NUMBER);
    return physical_channel*VIRTUAL_CHANNEL_NUMBER+virtual_channel;
endfunction

`endif
