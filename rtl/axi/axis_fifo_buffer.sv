`include "defines.svh"

module axis_fifo_buffer #(
    parameter CHANNEL_NUMBER = 8,
    parameter BUFFER_LENGTH = 8,
    parameter AXIS_DATA_WIDTH = 40,
    parameter AXIS_ID_WIDTH = 4,
    parameter AXIS_DEST_WIDTH = 4,
    parameter AXIS_USER_WIDTH = 4
) (
    input  ACLK, ARESETn,
    axis_if.s s_axis_i [CHANNEL_NUMBER],
    axis_if.m m_axis_o [CHANNEL_NUMBER]
);

    `GENERATE_AXIS_TYPEDEFS
    axis_mosi_t in_mosi_i[CHANNEL_NUMBER], out_mosi_o[CHANNEL_NUMBER];
    axis_miso_t in_miso_o[CHANNEL_NUMBER], out_miso_i[CHANNEL_NUMBER];

    generate
        genvar j;
        for (j = 0; j < CHANNEL_NUMBER; j++) begin : typedef_to_interface
            `AXIS_INTERFACE_SLAVE2TYPEDEF(s_axis_i[j], in_mosi_i[j], in_miso_o[j])
            `AXIS_INTERFACE_MASTER2TYPEDEF(m_axis_o[j], out_mosi_o[j], out_miso_i[j])
        end
    endgenerate

    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER; i++) begin : gen_fifos
            stream_fifo #(
                .DATA_WIDTH($bits(axis_data_t)),
                .FIFO_LEN(BUFFER_LENGTH)
            ) q (
                .ACLK(ACLK),
                .ARESETn(ARESETn),

                .data_i(in_mosi_i[i].data),
                .valid_i(in_mosi_i[i].TVALID),
                .ready_o(in_miso_o[i].TREADY),

                .data_o(out_mosi_o[i].data),
                .valid_o(out_mosi_o[i].TVALID),
                .ready_i(out_miso_i[i].TREADY)

            );
        end
    endgenerate
    
endmodule