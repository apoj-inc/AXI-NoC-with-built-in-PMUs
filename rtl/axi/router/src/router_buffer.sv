`include "defines.svh"
`include "axis_defines.svh"

module router_buffer #(
    parameter        PHYSICAL_CHANNEL_NUMBER = 8,
    parameter        VIRTUAL_CHANNEL_NUMBER = 2,
    parameter        CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),

    parameter        VIRTUAL_NETWORK_NUMBER = 2,
    parameter int    VIRTUAL_NETWORKS[VIRTUAL_NETWORK_NUMBER] = '{1, 1},

    parameter        BUFFER_DEPTH = 8,

    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4,
    
    parameter string BUFFER_ALLOCATOR = "Straight"
) (
    input  ACLK, ARESETn,
    axis_if.s s_axis_i [CHANNEL_NUMBER],
    axis_if.m m_axis_o [CHANNEL_NUMBER]
);

    `GENERATE_AXIS_TYPEDEFS
    axis_mosi_t in_mosi_i[CHANNEL_NUMBER], out_mosi_o[CHANNEL_NUMBER];
    axis_miso_t in_miso_o[CHANNEL_NUMBER], out_miso_i[CHANNEL_NUMBER];

    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   alloc_if [CHANNEL_NUMBER] ();

    generate
        if(BUFFER_ALLOCATOR == "Straight") begin : router_buffer_alloc_buffer_allocator_straight
            buffer_allocator_straight #(
                .PHYSICAL_CHANNEL_NUMBER(PHYSICAL_CHANNEL_NUMBER),
                .VIRTUAL_CHANNEL_NUMBER(VIRTUAL_CHANNEL_NUMBER),
                .CHANNEL_NUMBER(CHANNEL_NUMBER),
                .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
            ) buffer_allocator (
                .s_axis_i(s_axis_i),
                .m_axis_o(alloc_if)
            );
        end /* else if(BUFFER_ALLOCATOR == "KeepInNetwork") begin : router_buffer_alloc_keep_in_network
            buffer_allocator_keep_network #(
                .PHYSICAL_CHANNEL_NUMBER(PHYSICAL_CHANNEL_NUMBER),
                .VIRTUAL_CHANNEL_NUMBER(VIRTUAL_CHANNEL_NUMBER),
                .CHANNEL_NUMBER(CHANNEL_NUMBER),
                .VIRTUAL_NETWORK_NUMBER(VIRTUAL_NETWORK_NUMBER),
                .VIRTUAL_NETWORKS(VIRTUAL_NETWORKS),
                .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
                .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
                .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
                .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
            ) buffer_allocator (
                .ACLK(ACLK), .ARESETn(ARESETn),
                .s_axis_i(s_axis_i),
                .m_axis_o(alloc_if.m)
            );
        end*/ else begin : router_buffer_alloc_error
            initial $error("No buffer allocator proveided! %s", BUFFER_ALLOCATOR);
        end
    endgenerate

    generate
        genvar j;
        for (j = 0; j < CHANNEL_NUMBER; j++) begin : typedef_to_interface
            `AXIS_INTERFACE_SLAVE2TYPEDEF(alloc_if[j], in_mosi_i[j], in_miso_o[j])
            `AXIS_INTERFACE_MASTER2TYPEDEF(m_axis_o[j], out_mosi_o[j], out_miso_i[j])
        end
    endgenerate

    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER; i++) begin : gen_fifos
            stream_fifo #(
                .DATA_WIDTH($bits(axis_data_t)),
                .FIFO_DEPTH(BUFFER_DEPTH)
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