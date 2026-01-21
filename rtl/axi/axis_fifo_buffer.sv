`include "defines.svh"

module axis_fifo_buffer #(
    parameter CHANNEL_NUMBER = 8,
    parameter BUFFER_LENGTH = 8,
    parameter AXIS_DATA_WIDTH = 40
    `ifdef TID_PRESENT
    ,
    parameter ID_WIDTH = 4
    `endif
    `ifdef TDEST_PRESENT
    ,
    parameter DEST_WIDTH = 4
    `endif
    `ifdef TUSER_PRESENT
    ,
    parameter USER_WIDTH = 4
    `endif
) (
    input  ACLK, ARESETn,
    input  axis_mosi_t in_mosi_i  [CHANNEL_NUMBER],
    output axis_miso_t in_miso_o  [CHANNEL_NUMBER],
    output axis_mosi_t out_mosi_o [CHANNEL_NUMBER],
    input  axis_miso_t out_miso_i [CHANNEL_NUMBER]
);

    `include "axis_type.svh"

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