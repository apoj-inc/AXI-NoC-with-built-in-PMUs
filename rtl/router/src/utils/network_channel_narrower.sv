`include "axis_defines.svh"

module network_channel_narrower #(
    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4,

    parameter        WIDTH_IN  = 10,
    parameter        WIDTH_OUT = 5
    ) (
        axis_if.s s_axis_i[WIDTH_IN],
        axis_if.m m_axis_o[WIDTH_OUT]
    );


    genvar i;
    generate
        for (i = 0; i < WIDTH_IN && i < WIDTH_OUT; i++) begin : narowwer_gen
            `AXIS_INTERFACE2INTERFACE(s_axis_i[i], m_axis_o[i])
        end
    endgenerate

endmodule : network_channel_narrower
