module axi_mux #(
    parameter INPUT_NUM = 3,
    parameter integer ID_ROUTING [(INPUT_NUM-1) * 2] = '{0, 0, 1, 1},

    parameter AXI_DATA_WIDTH = 32,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter ADDR_WIDTH = 16,
    

    parameter Ax_FIFO_LEN = 4
) (
    input logic ACLK,
    input logic ARESETn,

    axi_if.s s_axi_in[INPUT_NUM],
    axi_if.m m_axi_out
);

    enum { AW_HANDSHAKE, W_HANDSHAKE } w_state, w_next_state;

    // AW channel 
    logic [INPUT_NUM-1:0] AWVALID;
    logic [INPUT_NUM-1:0] AWREADY;
    logic [ID_W_WIDTH-1:0] AWID [INPUT_NUM];
    logic [ADDR_WIDTH-1:0] AWADDR [INPUT_NUM];
    logic [7:0] AWLEN [INPUT_NUM];
    logic [2:0] AWSIZE [INPUT_NUM];
    logic [1:0] AWBURST [INPUT_NUM];

    // W channel
    logic [INPUT_NUM-1:0] WVALID;
    logic [INPUT_NUM-1:0] WREADY;
    logic [AXI_DATA_WIDTH-1:0] WDATA [INPUT_NUM];
    logic [(AXI_DATA_WIDTH/8)-1:0] WSTRB [INPUT_NUM];
    logic WLAST [INPUT_NUM];

    // B channel
    logic [INPUT_NUM-1:0] BVALID;
    logic [INPUT_NUM-1:0] BREADY;
    logic [ID_W_WIDTH-1:0] BID [INPUT_NUM];

    // AR channel
    logic [INPUT_NUM-1:0] ARVALID;
    logic [INPUT_NUM-1:0] ARREADY;
    logic [ID_R_WIDTH-1:0] ARID [INPUT_NUM];
    logic [ADDR_WIDTH-1:0] ARADDR [INPUT_NUM];
    logic [7:0] ARLEN [INPUT_NUM];
    logic [2:0] ARSIZE [INPUT_NUM];
    logic [1:0] ARBURST [INPUT_NUM];

    // R channel
    logic [INPUT_NUM-1:0] RVALID;
    logic [INPUT_NUM-1:0] RREADY;
    logic [ID_R_WIDTH-1:0] RID [INPUT_NUM];
    logic [AXI_DATA_WIDTH-1:0] RDATA [INPUT_NUM];
    logic RLAST [INPUT_NUM];


    // AW arbiter channel
    logic AWVALID_arbiter;
    logic AWREADY_arbiter;
    logic [ID_W_WIDTH-1:0] AWID_arbiter;
    logic [ADDR_WIDTH-1:0] AWADDR_arbiter;
    logic [7:0] AWLEN_arbiter;
    logic [2:0] AWSIZE_arbiter;
    logic [1:0] AWBURST_arbiter;

    // AW FIFO channel
    logic AWVALID_fifo;
    logic AWREADY_fifo;
    logic [ID_W_WIDTH-1:0] AWID_fifo;
    logic [ADDR_WIDTH-1:0] AWADDR_fifo;
    logic [7:0] AWLEN_fifo;
    logic [2:0] AWSIZE_fifo;
    logic [1:0] AWBURST_fifo;

    generate
        genvar i;

        for (i = 0; i < INPUT_NUM; i++) begin : map_if
            always_comb begin
                s_axi_in[i].AWREADY = AWREADY[i];
                AWVALID[i] = s_axi_in[i].AWVALID;
                AWID[i] = s_axi_in[i].AWID;
                AWADDR[i] = s_axi_in[i].AWADDR;
                AWLEN[i] = s_axi_in[i].AWLEN;
                AWSIZE[i] = s_axi_in[i].AWSIZE;
                AWBURST[i] = s_axi_in[i].AWBURST;

                s_axi_in[i].WREADY = WREADY[i];
                WVALID[i] = s_axi_in[i].WVALID;
                WDATA[i] = s_axi_in[i].WDATA;
                WSTRB[i] = s_axi_in[i].WSTRB;
                WLAST[i] = s_axi_in[i].WLAST;

                BREADY[i] = s_axi_in[i].BREADY;
                s_axi_in[i].BVALID = BVALID[i];
                s_axi_in[i].BID = BID[i];

                s_axi_in[i].ARREADY = ARREADY[i];
                ARVALID[i] = s_axi_in[i].ARVALID;
                ARID[i] = s_axi_in[i].ARID;
                ARADDR[i] = s_axi_in[i].ARADDR;
                ARLEN[i] = s_axi_in[i].ARLEN;
                ARSIZE[i] = s_axi_in[i].ARSIZE;
                ARBURST[i] = s_axi_in[i].ARBURST;

                RREADY[i] = s_axi_in[i].RREADY;
                s_axi_in[i].RVALID = RVALID[i];
                s_axi_in[i].RID = RID[i];
                s_axi_in[i].RDATA = RDATA[i];
                s_axi_in[i].RLAST = RLAST[i];
            end
        end
    endgenerate


    logic [ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2 - 1:0] data_w [INPUT_NUM];

    generate
        for (i = 0; i < INPUT_NUM; i++) begin : map_data_w
            assign data_w[i] = {AWID[i], AWADDR[i], AWLEN[i], AWSIZE[i], AWBURST[i]};
        end
    endgenerate

    stream_arbiter #(
        .AXI_DATA_WIDTH(ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2),
        .INPUT_NUM(INPUT_NUM)
    ) stream_arbiter_aw (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i(data_w),
        .valid_i(AWVALID),
        .ready_o(AWREADY),

        .data_o({AWID_arbiter, AWADDR_arbiter, AWLEN_arbiter, AWSIZE_arbiter, AWBURST_arbiter}),
        .valid_o(AWVALID_arbiter),
        .ready_i(AWREADY_arbiter)
    );

    stream_fifo #(
        .DATA_WIDTH(ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2),
        .FIFO_LEN(Ax_FIFO_LEN)
    ) stream_fifo_aw (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i({AWID_arbiter, AWADDR_arbiter, AWLEN_arbiter, AWSIZE_arbiter, AWBURST_arbiter}),
        .valid_i(AWVALID_arbiter),
        .ready_o(AWREADY_arbiter),

        .data_o({AWID_fifo, AWADDR_fifo, AWLEN_fifo, AWSIZE_fifo, AWBURST_fifo}),
        .valid_o(AWVALID_fifo),
        .ready_i(AWREADY_fifo)
    );


    logic [ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2 - 1:0] data_r [INPUT_NUM];

    generate
        for (i = 0; i < INPUT_NUM; i++) begin : map_data_r
            assign data_r[i] = {ARID[i], ARADDR[i], ARLEN[i], ARSIZE[i], ARBURST[i]};
        end
    endgenerate

    stream_arbiter #(
        .AXI_DATA_WIDTH(ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2),
        .INPUT_NUM(INPUT_NUM)
    ) stream_arbiter_ar (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i(data_r),
        .valid_i(ARVALID),
        .ready_o(ARREADY),

        .data_o({m_axi_out.ARID, m_axi_out.ARADDR, m_axi_out.ARLEN, m_axi_out.ARSIZE, m_axi_out.ARBURST}),
        .valid_o(m_axi_out.ARVALID),
        .ready_i(m_axi_out.ARREADY)
    );


    // AW-W fsm

    logic [$clog2(INPUT_NUM)-1:0] selected;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            w_state <= AW_HANDSHAKE;
        end
        else begin
            w_state <= w_next_state;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            selected <= 0;
        end
        else begin
            case (w_state)
                AW_HANDSHAKE: begin
                    selected <= INPUT_NUM-1;
                    for (int j = 0; j < INPUT_NUM - 1; j++) begin
                        if (AWID_fifo >= ID_ROUTING[j * 2] && AWID_fifo <= ID_ROUTING[j * 2 + 1]) begin
                            selected <= j;
                        end
                    end
                end 
            endcase
        end
    end

    always_comb begin
        w_next_state = AW_HANDSHAKE;
        case (w_state)
            AW_HANDSHAKE: begin
                if (m_axi_out.AWVALID && m_axi_out.AWREADY) begin
                    w_next_state = W_HANDSHAKE;
                end
            end
            W_HANDSHAKE: begin
                if (m_axi_out.WREADY && m_axi_out.WVALID && m_axi_out.WLAST) begin
                    w_next_state = AW_HANDSHAKE;
                end
                else begin
                    w_next_state = W_HANDSHAKE;
                end
            end
        endcase
    end

    always_comb begin
        AWREADY_fifo = 0;

        for (int j = 0; j < INPUT_NUM - 1; j++) begin
            WREADY[j] = 0;
        end

        case (w_state)
            AW_HANDSHAKE: begin
                int sel;
                sel = INPUT_NUM - 1;

                for (int j = 0; j < INPUT_NUM - 1; j++) begin
                    if (AWID_fifo >= ID_ROUTING[j * 2] && AWID_fifo <= ID_ROUTING[j * 2 + 1]) begin
                        sel = j;
                    end
                end

                AWREADY_fifo = m_axi_out.AWREADY;
                m_axi_out.AWVALID = AWVALID_fifo;
                m_axi_out.AWID = AWID_fifo;
                m_axi_out.AWADDR = AWADDR_fifo;
                m_axi_out.AWLEN = AWLEN_fifo;
                m_axi_out.AWSIZE = AWSIZE_fifo;
                m_axi_out.AWBURST = AWBURST_fifo;

                WREADY[sel] = m_axi_out.WREADY;
                m_axi_out.WVALID = WVALID[sel];
                m_axi_out.WDATA = WDATA[sel];
                m_axi_out.WSTRB = WSTRB[sel];
                m_axi_out.WLAST = WLAST[sel];
            end
            W_HANDSHAKE: begin
                WREADY[selected] = m_axi_out.WREADY;
                m_axi_out.WVALID = WVALID[selected];
                m_axi_out.WDATA = WDATA[selected];
                m_axi_out.WSTRB = WSTRB[selected];
                m_axi_out.WLAST = WLAST[selected];
            end
        endcase
    end


    // B procedural

    always_comb begin
        int sel;
        sel = INPUT_NUM - 1;

        for (int j = 0; j < INPUT_NUM-1; j++) begin
            if (m_axi_out.BID >= ID_ROUTING[j * 2] && m_axi_out.BID <= ID_ROUTING[j * 2 + 1]) begin
                sel = j;
            end
        end

        m_axi_out.BREADY = BREADY[sel];
        BVALID[sel] = m_axi_out.BVALID;
        BID[sel] = m_axi_out.BID;
    end

    // R procedural

    always_comb begin
        int sel;
        sel = INPUT_NUM - 1;

        for (int j = 0; j < INPUT_NUM-1; j++) begin
            if (m_axi_out.RID >= ID_ROUTING[j * 2] && m_axi_out.RID <= ID_ROUTING[j * 2 + 1]) begin
                sel = j;
            end
        end

        m_axi_out.RREADY = RREADY[sel];
        RVALID[sel] = m_axi_out.RVALID;
        RID[sel] = m_axi_out.RID;
        RDATA[sel] = m_axi_out.RDATA;
        RLAST[sel] = m_axi_out.RLAST;
    end

endmodule