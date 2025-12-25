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

    axis_if axis_in(), axis_out();

    assign axis_in.TVALID = m_tvalid;
    assign axis_in.TDATA = m_tdata;
    assign m_tready = axis_in.TREADY;
 
    assign s_tvalid = axis_out.TVALID;
    assign s_tdata = axis_out.TDATA;
    assign axis_out.TREADY = s_tready;
    
    queue queue_name(clk, rst_n, axis_in, axis_out);
    stream_fifo #(.DATA_TYPE(logic [31:0])) stream_fifo(clk, rst_n, m_tdata, m_tvalid, m_tready_alt, s_tdata_alt, s_tvalid_alt, s_tready);

endmodule