`include "defines.svh"

module axis_fifo_buffer
import axis_type::*;
#(
    parameter CHANNEL_NUMBER = 8,
    parameter BUFFER_LENGTH = 8
) (
    input  ACLK, ARESETn,
    input  axis_mosi_t in_mosi_i  [CHANNEL_NUMBER],
    output axis_miso_t in_miso_o  [CHANNEL_NUMBER],
    output axis_mosi_t out_mosi_o [CHANNEL_NUMBER],
    input  axis_miso_t out_miso_i [CHANNEL_NUMBER]
);

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