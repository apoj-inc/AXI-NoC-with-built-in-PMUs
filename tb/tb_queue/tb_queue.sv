module tb_queue(
    input clk,
    input rst_n,
    input m_tvalid,
    input s_tready,
    input [32-1:0] m_tdata,
    output s_tvalid,
    output m_tready,
    output [32-1:0] s_tdata,
    
    output s_tvalid_alt,
    output m_tready_alt,
    output [32-1:0] s_tdata_alt
);

    axis_miso_t axis_miso_in, axis_miso_out;
    axis_mosi_t axis_mosi_in, axis_mosi_out;

    assign axis_mosi_in.TVALID = m_tvalid;
    assign axis_mosi_in.data.TDATA = m_tdata;
    assign m_tready = axis_miso_in.TREADY;
 
    assign s_tvalid = axis_mosi_out.TVALID;
    assign s_tdata = axis_mosi_out.data.TDATA;
    assign axis_miso_out.TREADY = s_tready;
    
    queue queue_name(
        clk, rst_n,

        axis_mosi_in,
        axis_miso_in,

        axis_mosi_out,
        axis_miso_out
    );
    
    stream_fifo #(
        .DATA_WIDTH(32)
        ) stream_fifo (
        clk, rst_n,
        m_tdata, m_tvalid, m_tready_alt,
        s_tdata_alt, s_tvalid_alt, s_tready
        );

endmodule