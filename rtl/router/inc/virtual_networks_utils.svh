`ifndef __VIRUAL_NETWORKS__UTILS__
`define __VIRUAL_NETWORKS__UTILS__

`define GENERATE_CALCULATE_VIRTUAL_NETWORK_OFFSET \
function int calculate_virtual_network_offset(int current_virtual_network); \
    automatic int res = 0; \
    for (int i = 0; i < current_virtual_network; i++) begin \
        res += VIRTUAL_NETWORKS[i]; \
    end \
    return res; \
endfunction

`endif
