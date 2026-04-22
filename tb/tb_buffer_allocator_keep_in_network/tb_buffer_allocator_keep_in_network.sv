`include "defines.svh"
`include "axis_defines.svh"

module tb_buffer_allocator_keep_in_network #(
    parameter        PHYSICAL_CHANNEL_NUMBER = 8,
    parameter        VIRTUAL_CHANNEL_NUMBER = 4,
    parameter        CHANNEL_NUMBER = PHYSICAL_CHANNEL_NUMBER*VIRTUAL_CHANNEL_NUMBER,
    parameter        CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),

    parameter        VIRTUAL_NETWORK_NUMBER = 2,
    parameter int    VIRTUAL_NETWORKS[VIRTUAL_NETWORK_NUMBER] = '{3, 1},

    parameter        AXIS_DATA_WIDTH = 32,
    parameter        AXIS_ID_WIDTH = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4
) (
    input logic ACLK, ARESETn,

    input m0_tvalid,
    input s0_tready,
    input [32-1:0] m0_tdata,
    input m0_tlast,
    output s0_tvalid,
    output m0_tready,
    output [32-1:0] s0_tdata,
    output s0_tlast,
    
    output s0_tvalid_alt,
    output m0_tready_alt,
    output [32-1:0] s0_tdata_alt,

    input m1_tvalid,
    input s1_tready,
    input [32-1:0] m1_tdata,
    input m1_tlast,
    output s1_tvalid,
    output m1_tready,
    output [32-1:0] s1_tdata,
    output s1_tlast,
    
    output s1_tvalid_alt,
    output m1_tready_alt,
    output [32-1:0] s1_tdata_alt,

    input m2_tvalid,
    input s2_tready,
    input [32-1:0] m2_tdata,
    input m2_tlast,
    output s2_tvalid,
    output m2_tready,
    output [32-1:0] s2_tdata,
    output s2_tlast,
    
    output s2_tvalid_alt,
    output m2_tready_alt,
    output [32-1:0] s2_tdata_alt,

    input m3_tvalid,
    input s3_tready,
    input [32-1:0] m3_tdata,
    input m3_tlast,
    output s3_tvalid,
    output m3_tready,
    output [32-1:0] s3_tdata,
    output s3_tlast,
    
    output s3_tvalid_alt,
    output m3_tready_alt,
    output [32-1:0] s3_tdata_alt
);

    axis_if #(
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_ID_WIDTH   (AXIS_ID_WIDTH  ),
        .AXIS_DEST_WIDTH (AXIS_DEST_WIDTH),
        .AXIS_USER_WIDTH (AXIS_USER_WIDTH)
    )   axis_i [CHANNEL_NUMBER](),
        axis_o [CHANNEL_NUMBER]();


    assign axis_i[0].TVALID = m0_tvalid;
    assign axis_i[0].TDATA = m0_tdata;
    assign axis_i[0].TLAST = m0_tlast;
    assign m0_tready = axis_i[0].TREADY;
 
    assign s0_tvalid = axis_o[0].TVALID;
    assign s0_tdata = axis_o[0].TDATA;
    assign s0_tlast = axis_o[0].TLAST;
    assign axis_o[0].TREADY = s0_tready;


    assign axis_i[1].TVALID = m1_tvalid;
    assign axis_i[1].TDATA = m1_tdata;
    assign axis_i[1].TLAST = m1_tlast;
    assign m1_tready = axis_i[1].TREADY;
 
    assign s1_tvalid = axis_o[1].TVALID;
    assign s1_tdata = axis_o[1].TDATA;
    assign s1_tlast = axis_o[1].TLAST;
    assign axis_o[1].TREADY = s1_tready;


    assign axis_i[2].TVALID = m2_tvalid;
    assign axis_i[2].TDATA = m2_tdata;
    assign axis_i[2].TLAST = m2_tlast;
    assign m2_tready = axis_i[2].TREADY;
 
    assign s2_tvalid = axis_o[2].TVALID;
    assign s2_tdata = axis_o[2].TDATA;
    assign s2_tlast = axis_o[2].TLAST;
    assign axis_o[2].TREADY = s2_tready;


    assign axis_i[3].TVALID = m3_tvalid;
    assign axis_i[3].TDATA = m3_tdata;
    assign axis_i[3].TLAST = m3_tlast;
    assign m3_tready = axis_i[3].TREADY;
 
    assign s3_tvalid = axis_o[3].TVALID;
    assign s3_tdata = axis_o[3].TDATA;
    assign s3_tlast = axis_o[3].TLAST;
    assign axis_o[3].TREADY = s3_tready;


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
        .s_axis_i(axis_i),
        .m_axis_o(axis_o)
    );
    
endmodule