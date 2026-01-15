module axi_demux #(
    parameter OUTPUT_NUM = 3,
    parameter integer ID_ROUTING [(OUTPUT_NUM-1) * 2] = '{0, 0, 1, 1},

    parameter AXI_DATA_WIDTH = 32,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter ADDR_WIDTH = 16,
    

    parameter Ax_FIFO_LEN = 4,
    parameter W_FIFO_LEN = 4,
    parameter B_FIFO_LEN = 4,
    parameter R_FIFO_LEN = 4
) (
    input logic ACLK,
    input logic ARESETn,

    axi_if.s s_axi_in,
    axi_if.m m_axi_out[OUTPUT_NUM]
);

    parameter AW_HANDSHAKE = 0, W_HANDSHAKE = 1;
    parameter AR_HANDSHAKE = 0, R_HANDSHAKE = 1;

    logic [1:0] w_state, w_next_state;
    logic r_state, r_next_state;

    logic [$clog2(OUTPUT_NUM)-1:0] selected;

    // AW channel 
    logic [OUTPUT_NUM-1:0] AWVALID;
    logic [OUTPUT_NUM-1:0] AWREADY;
    logic [ID_W_WIDTH-1:0] AWID [OUTPUT_NUM];
    logic [ADDR_WIDTH-1:0] AWADDR [OUTPUT_NUM];
    logic [7:0] AWLEN [OUTPUT_NUM];
    logic [2:0] AWSIZE [OUTPUT_NUM];
    logic [1:0] AWBURST [OUTPUT_NUM];

    // W channel
    logic [OUTPUT_NUM-1:0] WVALID;
    logic [OUTPUT_NUM-1:0] WREADY;
    logic [AXI_DATA_WIDTH-1:0] WDATA [OUTPUT_NUM];
    logic [(AXI_DATA_WIDTH/8)-1:0] WSTRB [OUTPUT_NUM];
    logic WLAST [OUTPUT_NUM];

    // B channel
    logic [OUTPUT_NUM-1:0] BVALID;
    logic [OUTPUT_NUM-1:0] BREADY;
    logic [ID_W_WIDTH-1:0] BID [OUTPUT_NUM];

    // AR channel 
    logic [OUTPUT_NUM-1:0] ARVALID;
    logic [OUTPUT_NUM-1:0] ARREADY;
    logic [ID_R_WIDTH-1:0] ARID [OUTPUT_NUM];
    logic [ADDR_WIDTH-1:0] ARADDR [OUTPUT_NUM];
    logic [7:0] ARLEN [OUTPUT_NUM];
    logic [2:0] ARSIZE [OUTPUT_NUM];
    logic [1:0] ARBURST [OUTPUT_NUM];

    // R channel
    logic [OUTPUT_NUM-1:0] RVALID;
    logic [OUTPUT_NUM-1:0] RREADY;
    logic [ID_R_WIDTH-1:0] RID [OUTPUT_NUM];
    logic [AXI_DATA_WIDTH-1:0] RDATA [OUTPUT_NUM];
    logic RLAST [OUTPUT_NUM];

    // --- demux_in --- //
    // AW channel 
    logic AWVALID_fifo;
    logic AWREADY_fifo;
    logic [ID_W_WIDTH-1:0] AWID_fifo;
    logic [ADDR_WIDTH-1:0] AWADDR_fifo;
    logic [7:0] AWLEN_fifo;
    logic [2:0] AWSIZE_fifo;
    logic [1:0] AWBURST_fifo;

    // W channel
    logic WVALID_fifo;
    logic WREADY_fifo;
    logic [AXI_DATA_WIDTH-1:0] WDATA_fifo;
    logic [(AXI_DATA_WIDTH/8)-1:0] WSTRB_fifo;
    logic WLAST_fifo;


    stream_fifo #(
        .DATA_WIDTH(ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2),
        .FIFO_LEN(Ax_FIFO_LEN)
    ) stream_fifo_aw (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i({s_axi_in.AWID, s_axi_in.AWADDR, s_axi_in.AWLEN, s_axi_in.AWSIZE, s_axi_in.AWBURST}),
        .valid_i(s_axi_in.AWVALID),
        .ready_o(s_axi_in.AWREADY),

        .data_o({AWID_fifo, AWADDR_fifo, AWLEN_fifo, AWSIZE_fifo, AWBURST_fifo}),
        .valid_o(AWVALID_fifo),
        .ready_i(AWREADY_fifo)
    );

    stream_fifo #(
        .DATA_WIDTH(AXI_DATA_WIDTH + (AXI_DATA_WIDTH/8) + 1),
        .FIFO_LEN(W_FIFO_LEN)
    ) stream_fifo_w (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i({s_axi_in.WDATA, s_axi_in.WSTRB, s_axi_in.WLAST}),
        .valid_i(s_axi_in.WVALID),
        .ready_o(s_axi_in.WREADY),

        .data_o({WDATA_fifo, WSTRB_fifo, WLAST_fifo}),
        .valid_o(WVALID_fifo),
        .ready_i(WREADY_fifo)
    );

    // AR channel
    logic ARVALID_fifo;
    logic ARREADY_fifo;
    logic [ID_R_WIDTH-1:0] ARID_fifo;
    logic [ADDR_WIDTH-1:0] ARADDR_fifo;
    logic [7:0] ARLEN_fifo;
    logic [2:0] ARSIZE_fifo;
    logic [1:0] ARBURST_fifo;

    stream_fifo #(
        .AXI_DATA_WIDTH(ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2),
        .FIFO_LEN(Ax_FIFO_LEN)
    ) stream_fifo_ar (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i({s_axi_in.ARID, s_axi_in.ARADDR, s_axi_in.ARLEN, s_axi_in.ARSIZE, s_axi_in.ARBURST}),
        .valid_i(s_axi_in.ARVALID),
        .ready_o(s_axi_in.ARREADY),

        .data_o({ARID_fifo, ARADDR_fifo, ARLEN_fifo, ARSIZE_fifo, ARBURST_fifo}),
        .valid_o(ARVALID_fifo),
        .ready_i(ARREADY_fifo)
    );

    generate
        genvar i;
        for (i = 0; i < OUTPUT_NUM; i++) begin : map_if
            always_comb begin
                AWREADY[i] = m_axi_out[i].AWREADY;
                m_axi_out[i].AWVALID = AWVALID[i];
                m_axi_out[i].AWID = AWID[i];
                m_axi_out[i].AWADDR = AWADDR[i];
                m_axi_out[i].AWLEN = AWLEN[i];
                m_axi_out[i].AWSIZE = AWSIZE[i];
                m_axi_out[i].AWBURST = AWBURST[i];

                WREADY[i] = m_axi_out[i].WREADY;
                m_axi_out[i].WVALID = WVALID[i];
                m_axi_out[i].WDATA = WDATA[i];
                m_axi_out[i].WSTRB = WSTRB[i];
                m_axi_out[i].WLAST = WLAST[i];

                BVALID[i] = m_axi_out[i].BVALID;
                BID[i] = m_axi_out[i].BID;
                m_axi_out[i].BREADY = BREADY[i];

                ARREADY[i] = m_axi_out[i].ARREADY;
                m_axi_out[i].ARVALID = ARVALID[i];
                m_axi_out[i].ARID = ARID[i];
                m_axi_out[i].ARADDR = ARADDR[i];
                m_axi_out[i].ARLEN = ARLEN[i];
                m_axi_out[i].ARSIZE = ARSIZE[i];
                m_axi_out[i].ARBURST = ARBURST[i];

                m_axi_out[i].RREADY = RREADY[i];
                RVALID[i] = m_axi_out[i].RVALID;
                RID[i] = m_axi_out[i].RID;
                RDATA[i] = m_axi_out[i].RDATA;
                RLAST[i] = m_axi_out[i].RLAST;
            end
        end
    endgenerate


    // write_fsm

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            w_state <= AW_HANDSHAKE;
        end
        else begin
            w_state <= w_next_state;
        end
    end

    always_comb begin
        w_next_state = AW_HANDSHAKE;
        case (w_state)
            AW_HANDSHAKE: begin
                w_next_state = AW_HANDSHAKE;

                if (AWVALID_fifo && AWREADY[OUTPUT_NUM-1] && (AWID_fifo > ID_ROUTING[(OUTPUT_NUM-1) * 2 - 1])) begin
                    w_next_state = W_HANDSHAKE;
                end

                for (int i = 0; i < OUTPUT_NUM-1; i++) begin
                    if (AWVALID_fifo && AWREADY[i] && (AWID_fifo >= ID_ROUTING[i * 2] && AWID_fifo <= ID_ROUTING[i * 2 + 1])) begin
                        w_next_state = W_HANDSHAKE;
                    end
                end
            end
            W_HANDSHAKE: begin
                if (WREADY[selected] && WVALID_fifo && WLAST_fifo) begin
                    w_next_state = AW_HANDSHAKE;
                end
                else begin
                    w_next_state = W_HANDSHAKE;
                end
            end
        endcase
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            selected <= 0;
        end
        else begin
            case (w_state)
                AW_HANDSHAKE: begin
                    selected <= OUTPUT_NUM-1;
                    for (int i = 0; i < OUTPUT_NUM; i++) begin
                        if (AWID_fifo >= ID_ROUTING[i * 2] && AWID_fifo <= ID_ROUTING[i * 2 + 1]) begin
                            selected <= i;
                        end
                    end
                end
            endcase
        end
    end

    always_comb begin

        AWREADY_fifo = 0;
        for (int i = 0; i < OUTPUT_NUM; i = i + 1) begin
            AWVALID[i] = 0;
            AWID[i] = 0;
            AWADDR[i] = 0;
            AWLEN[i] = 0;
            AWSIZE[i] = 0;
            AWBURST[i] = 0;
        end

        WREADY_fifo = 0;
        for (int i = 0; i < OUTPUT_NUM; i = i + 1) begin
            WVALID[i] = 0;
            WDATA[i] = 0;
            WSTRB[i] = 0;
            WLAST[i] = 0;
        end

        case (w_state)
            AW_HANDSHAKE: begin
                if (AWVALID_fifo) begin
                    int sel;
                    sel = OUTPUT_NUM-1;
                    for (int i = 0; i < OUTPUT_NUM; i++) begin
                        if (AWID_fifo >= ID_ROUTING[i * 2] && AWID_fifo <= ID_ROUTING[i * 2 + 1]) begin
                            sel = i;
                        end
                    end
                    
                    AWREADY_fifo = AWREADY[sel];
                    AWVALID[sel] = AWVALID_fifo;
                    AWID[sel] = AWID_fifo;
                    AWADDR[sel] = AWADDR_fifo;
                    AWLEN[sel] = AWLEN_fifo;
                    AWSIZE[sel] = AWSIZE_fifo;
                    AWBURST[sel] = AWBURST_fifo;

                    WREADY_fifo = WREADY[sel];
                    WVALID[sel] = WVALID_fifo;
                    WDATA[sel] = WDATA_fifo;
                    WSTRB[sel] = WSTRB_fifo;
                    WLAST[sel] = WLAST_fifo;
                end
            end
            W_HANDSHAKE: begin
                WREADY_fifo = WREADY[selected];
                WVALID[selected] = WVALID_fifo;
                WDATA[selected] = WDATA_fifo;
                WSTRB[selected] = WSTRB_fifo;
                WLAST[selected] = WLAST_fifo;
            end
        endcase
    end

    // B channel arbiter

    stream_arbiter #(
        .AXI_DATA_WIDTH(ID_W_WIDTH),
        .INPUT_NUM(OUTPUT_NUM)
    ) stream_arbiter_b (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i(BID),
        .valid_i(BVALID),
        .ready_o(BREADY),

        .data_o(s_axi_in.BID),
        .valid_o(s_axi_in.BVALID),
        .ready_i(s_axi_in.BREADY)
    );


    // read_logic

    always_comb begin

        ARREADY_fifo = 0;
        for (int i = 0; i < OUTPUT_NUM; i = i + 1) begin
            ARVALID[i] = 0;
            ARID[i] = 0;
            ARADDR[i] = 0;
            ARLEN[i] = 0;
            ARSIZE[i] = 0;
            ARBURST[i] = 0;
        end

        if (ARVALID_fifo) begin
            int sel;
            sel = OUTPUT_NUM-1;
            for (int i = 0; i < OUTPUT_NUM; i++) begin
                if (ARID_fifo >= ID_ROUTING[i * 2] && ARID_fifo <= ID_ROUTING[i * 2 + 1]) begin
                    sel = i;
                end
            end

            ARREADY_fifo = ARREADY[sel];
            ARVALID[sel] = ARVALID_fifo;
            ARID[sel] = ARID_fifo;
            ARADDR[sel] = ARADDR_fifo;
            ARLEN[sel] = ARLEN_fifo;
            ARSIZE[sel] = ARSIZE_fifo;
            ARBURST[sel] = ARBURST_fifo;
        end
    end

    // R channel arbiter

    logic [ID_R_WIDTH + AXI_DATA_WIDTH + 1 - 1:0] data_i [OUTPUT_NUM];

    generate
        for (i = 0; i < OUTPUT_NUM; i++) begin : map_data
            assign data_i[i] = {RID[i], RDATA[i], RLAST[i]};
        end
    endgenerate

    stream_arbiter #(
        .AXI_DATA_WIDTH(ID_R_WIDTH + AXI_DATA_WIDTH + 1),
        .INPUT_NUM(OUTPUT_NUM)
    ) stream_arbiter_r (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i(data_i),
        .valid_i(RVALID),
        .ready_o(RREADY),

        .data_o({s_axi_in.RID, s_axi_in.RDATA, s_axi_in.RLAST}),
        .valid_o(s_axi_in.RVALID),
        .ready_i(s_axi_in.RREADY)
    );

endmodule
