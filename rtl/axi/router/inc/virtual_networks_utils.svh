`ifndef __VIRUAL_NETWORKS__UTILS__
`define __VIRUAL_NETWORKS__UTILS__

package virtualNetworksUtils;

    localparam VIRTUAL_NETWORK_NUMBER = 2;
    localparam int VIRTUAL_NETWORKS[VIRTUAL_NETWORK_NUMBER] = '{1, 1};

    function int calculate_virtual_network_offset(int current_virtual_network);
        automatic int res = 0;
        for (int i = 0; i < current_virtual_network; i++) begin
            res += VIRTUAL_NETWORKS[i];
        end
        return res;
    endfunction

endpackage

`endif
