`include "defines.svh"

module axi2axis_XY #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter AXIS_CHANNEL_WIDTH = 40,
    
    `ifdef TID_PRESENT
    parameter ID_WIDTH = 4,
    `else
    parameter ID_WIDTH = 0,
    `endif
    `ifdef TDEST_PRESENT
    parameter DEST_WIDTH = 4,
    `else
    parameter DEST_WIDTH = 0,
    `endif
    `ifdef TUSER_PRESENT
    parameter USER_WIDTH = 4,
    `else
    parameter USER_WIDTH = 0,
    `endif

    parameter ROUTER_X = 0,
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter ROUTER_Y = 0,
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y)
) (
    input ACLK, ARESETn,

    input  axi_mosi_t s_axi_i,
    output axi_miso_t s_axi_o,

    output axi_mosi_t m_axi_o,
    input  axi_miso_t m_axi_i,

    input  axis_mosi_t s_axis_resp_i,
    output axis_miso_t s_axis_resp_o,

    input  axis_miso_t m_axis_resp_i,
    output axis_mosi_t m_axis_resp_o,

    input  axis_mosi_t s_axis_req_i,
    output axis_miso_t s_axis_req_o,

    input  axis_miso_t m_axis_req_i,
    output axis_mosi_t m_axis_req_o
    
);

    `include "axi_type.svh"
    `include "axis_type.svh"

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (8 + (MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH) * 2) - 1:0] RESERVED;
        logic [7:0] PACKET_COUNT;
        logic [MAX_ROUTERS_X_WIDTH-1:0] SOURCE_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] SOURCE_Y;
        logic [MAX_ROUTERS_X_WIDTH-1:0] DESTINATION_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] DESTINATION_Y;
    } routing_header;

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2) - 1:0] RESERVED;
        logic [ID_W_WIDTH-1:0] ID;
        logic [ADDR_WIDTH-1:0] ADDR;
        logic [7:0] LEN;
        logic [2:0] SIZE;
        logic [1:0] BURST;
    } aw_subheader;

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (ID_W_WIDTH) - 1:0] RESERVED;
        logic [ID_W_WIDTH-1:0] ID;
    } b_subheader;

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (DATA_WIDTH) - 1:0] RESERVED;
        logic [DATA_WIDTH-1:0] DATA;
    } w_data;

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2) - 1:0] RESERVED;
        logic [ID_R_WIDTH-1:0] ID;
        logic [ADDR_WIDTH-1:0] ADDR;
        logic [7:0] LEN;
        logic [2:0] SIZE;
        logic [1:0] BURST;
    } ar_subheader;

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (ID_R_WIDTH + DATA_WIDTH) - 1:0] RESERVED;
        logic [ID_R_WIDTH-1:0] ID;
        logic [DATA_WIDTH-1:0] DATA;
    } r_data;

    // response coordinate logic
    logic [8:0] RRESP_LEN, RRESP_LEN_next;
    logic [MAX_ROUTERS_X_WIDTH-1:0] ROUTING_SOURCE_X, ROUTING_SOURCE_X_next;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] ROUTING_SOURCE_Y, ROUTING_SOURCE_Y_next;
    logic [MAX_ROUTERS_X_WIDTH-1:0] RRESP_DESTINATION_X, RRESP_DESTINATION_X_next;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] RRESP_DESTINATION_Y, RRESP_DESTINATION_Y_next;
    logic [MAX_ROUTERS_X_WIDTH-1:0] BRESP_DESTINATION_X, BRESP_DESTINATION_X_next;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] BRESP_DESTINATION_Y, BRESP_DESTINATION_Y_next;
    

    packet_type AW;
    packet_type AR;
    packet_type B;
    packet_type R;

    logic [2:0] DATA_arbiter_i [4];
    logic [2:0] request_data_o, response_data_o;
    logic request_valid_o, response_valid_o;
    logic request_ready_i, response_ready_i;

    always_comb begin
        AW = AW_SUBHEADER;
        AR = AR_SUBHEADER;
        B = B_SUBHEADER;
        R = R_DATA;
    end

    stream_arbiter #(
        .DATA_WIDTH(3),
        .INPUT_NUM(2)
    ) u_stream_arbiter_req (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i('{AR, AW}),
        .valid_i({s_axi_i.AWVALID, s_axi_i.ARVALID}),
        // .ready_o(READY_arbiter_o),

        .data_o(request_data_o),
        .valid_o(request_valid_o),
        .ready_i(request_ready_i)
    );

    stream_arbiter #(
        .DATA_WIDTH(3),
        .INPUT_NUM(2)
    ) u_stream_arbiter_resp (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i('{R, B}),
        .valid_i({m_axi_o.BVALID, m_axi_o.RVALID}),
        // .ready_o(READY_arbiter_o),

        .data_o(response_data_o),
        .valid_o(response_valid_o),
        .ready_i(response_ready_i)
    );


    enum {GENERATE_HEADER, AW_SEND, AR_SEND, W_SEND, R_SEND, B_SEND} out_resp_state, out_resp_state_next, out_req_state, out_req_state_next;

    routing_header routing_header_req_o, routing_header_resp_o;
    aw_subheader aw_subheader_o;
    w_data w_data_o;
    b_subheader b_subheader_o;
    ar_subheader ar_subheader_o;
    r_data r_data_o;

    always_comb begin
        aw_subheader_o.RESERVED = '0;
        aw_subheader_o.ID = s_axi_i.data.aw.AWID;
        aw_subheader_o.ADDR = s_axi_i.data.aw.AWADDR;
        aw_subheader_o.LEN = s_axi_i.data.aw.AWLEN;
        aw_subheader_o.SIZE = s_axi_i.data.aw.AWSIZE;
        aw_subheader_o.BURST = s_axi_i.data.aw.AWBURST;

        w_data_o.RESERVED = '0;
        w_data_o.DATA = s_axi_i.data.w.WDATA;

        b_subheader_o.RESERVED = '0;
        b_subheader_o.ID = m_axi_o.data.b.BID;

        ar_subheader_o.RESERVED = '0;
        ar_subheader_o.ID = s_axi_i.data.ar.ARID;
        ar_subheader_o.ADDR = s_axi_i.data.ar.ARADDR;
        ar_subheader_o.LEN = s_axi_i.data.ar.ARLEN;
        ar_subheader_o.SIZE = s_axi_i.data.ar.ARSIZE;
        ar_subheader_o.BURST = s_axi_i.data.ar.ARBURST;

        r_data_o.RESERVED = '0;
        r_data_o.ID = m_axi_o.data.r.RID;
        r_data_o.DATA = m_axi_o.data.r.RDATA;
    end


    // --- req fsm ---

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            out_req_state <= GENERATE_HEADER;
        end
        else begin
            out_req_state <= out_req_state_next;
        end
    end

    always_comb begin
        out_req_state_next = GENERATE_HEADER;

        case (out_req_state)
            GENERATE_HEADER: begin
                if (request_valid_o && m_axis_req_i.TREADY) begin
                    case (request_data_o)
                        AW_SUBHEADER: out_req_state_next = AW_SEND;
                        AR_SUBHEADER: out_req_state_next = AR_SEND;
                    endcase
                end
                else begin
                    out_req_state_next = GENERATE_HEADER;
                end
            end
            AW_SEND: begin
                if (m_axis_req_o.TVALID && m_axis_req_i.TREADY) begin
                    out_req_state_next = W_SEND;
                end
                else begin
                    out_req_state_next = AW_SEND;
                end
            end
            W_SEND: begin
                if (s_axi_o.WREADY && s_axi_i.WVALID && s_axi_i.data.w.WLAST) begin
                    out_req_state_next = GENERATE_HEADER;
                end
                else begin
                    out_req_state_next = W_SEND;
                end
            end
            AR_SEND: begin
                if (s_axi_o.ARREADY && s_axi_i.ARVALID) begin
                    out_req_state_next = GENERATE_HEADER;
                end
                else begin
                    out_req_state_next = AR_SEND;
                end
            end
            default: begin
                out_req_state_next = GENERATE_HEADER;
            end
        endcase
    end

    always_comb begin
        case (out_req_state)
            GENERATE_HEADER: begin
                if (request_valid_o) begin
                    routing_header_req_o.RESERVED = '0;

                    if (request_data_o == AW_SUBHEADER) begin
                        routing_header_req_o.DESTINATION_X = (s_axi_i.data.aw.AWID - 1) % MAX_ROUTERS_X;
                        routing_header_req_o.DESTINATION_Y = (s_axi_i.data.aw.AWID - 1) / MAX_ROUTERS_X;
                        routing_header_req_o.PACKET_COUNT = s_axi_i.data.aw.AWLEN + 2;
                    end
                    else if (request_data_o == AR_SUBHEADER) begin
                        routing_header_req_o.DESTINATION_X = (s_axi_i.data.ar.ARID - 1) % MAX_ROUTERS_X;
                        routing_header_req_o.DESTINATION_Y = (s_axi_i.data.ar.ARID - 1) / MAX_ROUTERS_X;
                        routing_header_req_o.PACKET_COUNT = 1;
                    end
                    else begin
                        routing_header_req_o = '0;
                    end

                    routing_header_req_o.SOURCE_X = ROUTER_X;
                    routing_header_req_o.SOURCE_Y = ROUTER_Y;


                    s_axi_o.WREADY = '0;
                    request_ready_i = '0;

                    m_axis_req_o.data.TID = ROUTING_HEADER;
                    m_axis_req_o.TVALID = '1;
                    m_axis_req_o.data.TDATA = routing_header_req_o;
                    m_axis_req_o.data.TSTRB = '1;
                    m_axis_req_o.data.TLAST = '0;
                    s_axi_o.AWREADY = '0;
                    s_axi_o.ARREADY = '0;
                end
                else begin
                    routing_header_req_o = '0;

                    s_axi_o.WREADY = '0;
                    request_ready_i = '0;

                    m_axis_req_o.data.TID = '0;
                    m_axis_req_o.TVALID = '0;
                    m_axis_req_o.data.TDATA = '0;
                    m_axis_req_o.data.TSTRB = '1;
                    m_axis_req_o.data.TLAST = '0;
                    s_axi_o.AWREADY = '0;
                    s_axi_o.ARREADY = '0;
                end
            end
            AW_SEND: begin
                routing_header_req_o = '0;

                s_axi_o.WREADY = '0;
                request_ready_i = '0;

                m_axis_req_o.data.TID = AW_SUBHEADER;
                m_axis_req_o.TVALID = '1;
                m_axis_req_o.data.TDATA = aw_subheader_o;
                m_axis_req_o.data.TSTRB = '1;
                m_axis_req_o.data.TLAST = '0;
                s_axi_o.AWREADY = m_axis_req_i.TREADY;
                s_axi_o.ARREADY = '0;

            end
            W_SEND: begin
                routing_header_req_o = '0;
                
                s_axi_o.WREADY = m_axis_req_i.TREADY;
                request_ready_i = m_axis_req_i.TREADY & s_axi_i.WVALID & s_axi_i.data.w.WLAST;

                m_axis_req_o.data.TID = W_DATA;
                m_axis_req_o.TVALID = s_axi_i.WVALID;
                m_axis_req_o.data.TDATA = w_data_o;
                m_axis_req_o.data.TSTRB = s_axi_i.data.w.WSTRB;
                m_axis_req_o.data.TLAST = s_axi_i.WVALID & s_axi_i.data.w.WLAST;
                s_axi_o.AWREADY = '0;
                s_axi_o.ARREADY = '0;
            end
            AR_SEND: begin
                routing_header_req_o = '0;

                s_axi_o.WREADY = '0;
                request_ready_i = s_axi_i.ARVALID & m_axis_req_i.TREADY;

                m_axis_req_o.data.TID = AR_SUBHEADER;
                m_axis_req_o.TVALID = s_axi_i.ARVALID;
                m_axis_req_o.data.TDATA = ar_subheader_o;
                m_axis_req_o.data.TSTRB = '1;
                m_axis_req_o.data.TLAST = 1;
                s_axi_o.AWREADY = '0;
                s_axi_o.ARREADY = m_axis_req_i.TREADY;
            end
            default: begin
                routing_header_req_o = '0;

                s_axi_o.WREADY = '0;
                request_ready_i = '0;

                m_axis_req_o.data.TID = '0;
                m_axis_req_o.TVALID = '0;
                m_axis_req_o.data.TDATA = '0;
                m_axis_req_o.data.TSTRB = '1;
                m_axis_req_o.data.TLAST = '0;
                s_axi_o.AWREADY = '0;
                s_axi_o.ARREADY = '0;
            end
        endcase
    end


    // --- resp fsm ---
    
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            out_resp_state <= GENERATE_HEADER;
        end
        else begin
            out_resp_state <= out_resp_state_next;
        end
    end

    always_comb begin
        out_resp_state_next = GENERATE_HEADER;

        case (out_resp_state)
            GENERATE_HEADER: begin
                if (response_valid_o && m_axis_resp_i.TREADY) begin
                    case (response_data_o)
                        B_SUBHEADER: out_resp_state_next = B_SEND;
                        R_DATA: out_resp_state_next = R_SEND;
                    endcase
                end
                else begin
                    out_resp_state_next = GENERATE_HEADER;
                end
            end
            B_SEND: begin
                if (m_axi_o.BVALID && m_axi_o.data.BREADY) begin
                    out_resp_state_next = GENERATE_HEADER;
                end
                else begin
                    out_resp_state_next = B_SEND;
                end
            end
            R_SEND: begin
                if (m_axi_o.RVALID && m_axi_o.data.RREADY && m_axi_o.data.r.RLAST) begin
                    out_resp_state_next = GENERATE_HEADER;
                end
                else begin
                    out_resp_state_next = R_SEND;
                end
            end
            default: begin
                out_resp_state_next = GENERATE_HEADER;
            end
        endcase
    end

    always_comb begin
        case (out_resp_state)
            GENERATE_HEADER: begin
                if (response_valid_o) begin

                    routing_header_resp_o.RESERVED = '0;

                    if (response_data_o == B_SUBHEADER) begin
                        routing_header_resp_o.DESTINATION_X = BRESP_DESTINATION_X;
                        routing_header_resp_o.DESTINATION_Y = BRESP_DESTINATION_Y;
                        routing_header_resp_o.PACKET_COUNT = 1;
                    end
                    else if (response_data_o == R_DATA) begin
                        routing_header_resp_o.DESTINATION_X = RRESP_DESTINATION_X;
                        routing_header_resp_o.DESTINATION_Y = RRESP_DESTINATION_Y;
                        routing_header_resp_o.PACKET_COUNT = RRESP_LEN;
                    end
                    else begin
                        routing_header_resp_o = '0;
                    end
                    routing_header_resp_o.SOURCE_X = ROUTER_X;
                    routing_header_resp_o.SOURCE_Y = ROUTER_Y;

                    response_ready_i = '0;

                    m_axis_resp_o.data.TID = ROUTING_HEADER;
                    m_axis_resp_o.TVALID = '1;
                    m_axis_resp_o.data.TDATA = routing_header_resp_o;
                    m_axis_resp_o.data.TSTRB = '1;
                    m_axis_resp_o.data.TLAST = '0;
                    m_axi_o.data.RREADY = '0;
                    m_axi_o.data.BREADY = '0;
                end
                else begin
                    routing_header_resp_o = '0;

                    response_ready_i = '0;

                    m_axis_resp_o.data.TID = '0;
                    m_axis_resp_o.TVALID = '0;
                    m_axis_resp_o.data.TDATA = '0;
                    m_axis_resp_o.data.TSTRB = '1;
                    m_axis_resp_o.data.TLAST = '0;
                    m_axi_o.data.RREADY = '0;
                    m_axi_o.data.BREADY = '0;
                end
            end
            B_SEND: begin
                routing_header_resp_o = '0;

                response_ready_i = m_axis_resp_i.TREADY;

                m_axis_resp_o.data.TID = B_SUBHEADER;
                m_axis_resp_o.TVALID = m_axi_o.BVALID;
                m_axis_resp_o.data.TDATA = b_subheader_o;
                m_axis_resp_o.data.TSTRB = '1;
                m_axis_resp_o.data.TLAST = 1;
                m_axi_o.data.RREADY = '0;
                m_axi_o.data.BREADY = m_axis_resp_i.TREADY;
            end
            R_SEND: begin
                routing_header_resp_o = '0;

                response_ready_i = m_axis_resp_i.TREADY & m_axi_o.RVALID & m_axi_o.data.r.RLAST;

                m_axis_resp_o.data.TID = R_DATA;
                m_axis_resp_o.TVALID = m_axi_o.RVALID;
                m_axis_resp_o.data.TDATA = r_data_o;
                m_axis_resp_o.data.TSTRB = '1;
                m_axis_resp_o.data.TLAST = m_axi_o.RVALID & m_axi_o.data.r.RLAST;
                m_axi_o.data.BREADY = '0;
                m_axi_o.data.RREADY = m_axis_resp_i.TREADY;
            end
            default: begin
                routing_header_resp_o = '0;

                response_ready_i = '0;

                m_axis_resp_o.data.TID = '0;
                m_axis_resp_o.TVALID = '0;
                m_axis_resp_o.data.TDATA = '0;
                m_axis_resp_o.data.TSTRB = '1;
                m_axis_resp_o.data.TLAST = '0;
                m_axi_o.data.RREADY = '0;
                m_axi_o.data.BREADY = '0;
            end
        endcase
    end

    // --- axis in logic ---

    routing_header routing_header_req_i, routing_header_resp_i;
    aw_subheader aw_subheader_i;
    w_data w_data_i;
    b_subheader b_subheader_i;
    ar_subheader ar_subheader_i;
    r_data r_data_i;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RRESP_LEN <= 0;
            ROUTING_SOURCE_X <= 0;
            ROUTING_SOURCE_Y <= 0;
            RRESP_DESTINATION_X <= 0;
            RRESP_DESTINATION_Y <= 0;
            BRESP_DESTINATION_X <= 0;
            BRESP_DESTINATION_Y <= 0;
        end
        else begin
            RRESP_LEN <= RRESP_LEN_next;
            ROUTING_SOURCE_X <= ROUTING_SOURCE_X_next;
            ROUTING_SOURCE_Y <= ROUTING_SOURCE_Y_next;
            RRESP_DESTINATION_X <= RRESP_DESTINATION_X_next;
            RRESP_DESTINATION_Y <= RRESP_DESTINATION_Y_next;
            BRESP_DESTINATION_X <= BRESP_DESTINATION_X_next;
            BRESP_DESTINATION_Y <= BRESP_DESTINATION_Y_next;
        end
    end


    always_comb begin
        routing_header_req_i = s_axis_req_i.data.TDATA;
        routing_header_resp_i = s_axis_resp_i.data.TDATA;

        aw_subheader_i = s_axis_req_i.data.TDATA;
        w_data_i = s_axis_req_i.data.TDATA;
        b_subheader_i = s_axis_resp_i.data.TDATA;
        ar_subheader_i = s_axis_req_i.data.TDATA;
        r_data_i = s_axis_resp_i.data.TDATA;
    end

    always_comb begin
        if (s_axis_req_i.TVALID) begin
            case (s_axis_req_i.data.TID)
                ROUTING_HEADER: begin
                    RRESP_LEN_next = RRESP_LEN;

                    ROUTING_SOURCE_X_next = routing_header_req_i.SOURCE_X;
                    ROUTING_SOURCE_Y_next = routing_header_req_i.SOURCE_Y;

                    RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                    RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                    BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                    BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                    s_axis_req_o.TREADY = '1;

                    m_axi_o.AWVALID = '0;
                    m_axi_o.data.aw.AWID = '0;
                    m_axi_o.data.aw.AWADDR = '0;
                    m_axi_o.data.aw.AWLEN = '0;
                    m_axi_o.data.aw.AWSIZE = '0;
                    m_axi_o.data.aw.AWBURST = '0;

                    m_axi_o.ARVALID = '0;
                    m_axi_o.data.ar.ARID = '0;
                    m_axi_o.data.ar.ARADDR = '0;
                    m_axi_o.data.ar.ARLEN = '0;
                    m_axi_o.data.ar.ARSIZE = '0;
                    m_axi_o.data.ar.ARBURST = '0;

                    m_axi_o.WVALID = '0;
                    m_axi_o.data.w.WDATA = '0;
                    m_axi_o.data.w.WLAST = '0;
                    m_axi_o.data.w.WSTRB = '0;
                end
                AW_SUBHEADER: begin
                    RRESP_LEN_next = RRESP_LEN;

                    ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                    ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                    RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                    RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;

                    if (m_axi_o.AWREADY) begin
                        BRESP_DESTINATION_X_next = ROUTING_SOURCE_X;
                        BRESP_DESTINATION_Y_next = ROUTING_SOURCE_Y;
                    end
                    else begin
                        BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                        BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;
                    end

                    s_axis_req_o.TREADY = m_axi_o.AWREADY;

                    m_axi_o.AWVALID = s_axis_req_i.TVALID;
                    m_axi_o.data.aw.AWID = aw_subheader_i.ID;
                    m_axi_o.data.aw.AWADDR = aw_subheader_i.ADDR;
                    m_axi_o.data.aw.AWLEN = aw_subheader_i.LEN;
                    m_axi_o.data.aw.AWSIZE = aw_subheader_i.SIZE;
                    m_axi_o.data.aw.AWBURST = aw_subheader_i.BURST;

                    m_axi_o.ARVALID = '0;
                    m_axi_o.data.ar.ARID = '0;
                    m_axi_o.data.ar.ARADDR = '0;
                    m_axi_o.data.ar.ARLEN = '0;
                    m_axi_o.data.ar.ARSIZE = '0;
                    m_axi_o.data.ar.ARBURST = '0;

                    m_axi_o.WVALID = '0;
                    m_axi_o.data.w.WDATA = '0;
                    m_axi_o.data.w.WLAST = '0;
                    m_axi_o.data.w.WSTRB = '0;              
                end
                AR_SUBHEADER: begin
                    RRESP_LEN_next = ar_subheader_i.LEN + 1;

                    ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                    ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                    BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                    BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                    if (m_axi_o.ARREADY) begin
                        RRESP_DESTINATION_X_next = ROUTING_SOURCE_X;
                        RRESP_DESTINATION_Y_next = ROUTING_SOURCE_Y;
                    end
                    else begin
                        RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                        RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                    end

                    s_axis_req_o.TREADY = m_axi_o.ARREADY;

                    m_axi_o.AWVALID = '0;
                    m_axi_o.data.aw.AWID = '0;
                    m_axi_o.data.aw.AWADDR = '0;
                    m_axi_o.data.aw.AWLEN = '0;
                    m_axi_o.data.aw.AWSIZE = '0;
                    m_axi_o.data.aw.AWBURST = '0;

                    m_axi_o.ARVALID = s_axis_req_i.TVALID;
                    m_axi_o.data.ar.ARID = ar_subheader_i.ID;
                    m_axi_o.data.ar.ARADDR = ar_subheader_i.ADDR;
                    m_axi_o.data.ar.ARLEN = ar_subheader_i.LEN;
                    m_axi_o.data.ar.ARSIZE = ar_subheader_i.SIZE;
                    m_axi_o.data.ar.ARBURST = ar_subheader_i.BURST;

                    m_axi_o.WVALID = '0;
                    m_axi_o.data.w.WDATA = '0;
                    m_axi_o.data.w.WLAST = '0;
                    m_axi_o.data.w.WSTRB = '0;             
                end
                W_DATA: begin
                    RRESP_LEN_next = RRESP_LEN;

                    ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                    ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                    RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                    RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                    BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                    BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                    s_axis_req_o.TREADY = m_axi_o.WREADY;

                    m_axi_o.AWVALID = '0;
                    m_axi_o.data.aw.AWID = '0;
                    m_axi_o.data.aw.AWADDR = '0;
                    m_axi_o.data.aw.AWLEN = '0;
                    m_axi_o.data.aw.AWSIZE = '0;
                    m_axi_o.data.aw.AWBURST = '0;

                    m_axi_o.ARVALID = '0;
                    m_axi_o.data.ar.ARID = '0;
                    m_axi_o.data.ar.ARADDR = '0;
                    m_axi_o.data.ar.ARLEN = '0;
                    m_axi_o.data.ar.ARSIZE = '0;
                    m_axi_o.data.ar.ARBURST = '0;

                    m_axi_o.WVALID = s_axis_req_i.TVALID;
                    m_axi_o.data.w.WDATA = w_data_i.DATA;
                    m_axi_o.data.w.WSTRB = s_axis_req_i.data.TSTRB;
                    m_axi_o.data.w.WLAST = s_axis_req_i.data.TLAST;
                end
                default: begin
                    RRESP_LEN_next = RRESP_LEN;

                    ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                    ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                    RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                    RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                    BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                    BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                    s_axis_req_o.TREADY = '1;

                    m_axi_o.AWVALID = '0;
                    m_axi_o.data.aw.AWID = '0;
                    m_axi_o.data.aw.AWADDR = '0;
                    m_axi_o.data.aw.AWLEN = '0;
                    m_axi_o.data.aw.AWSIZE = '0;
                    m_axi_o.data.aw.AWBURST = '0;

                    m_axi_o.ARVALID = '0;
                    m_axi_o.data.ar.ARID = '0;
                    m_axi_o.data.ar.ARADDR = '0;
                    m_axi_o.data.ar.ARLEN = '0;
                    m_axi_o.data.ar.ARSIZE = '0;
                    m_axi_o.data.ar.ARBURST = '0;

                    m_axi_o.WVALID = '0;
                    m_axi_o.data.w.WDATA = '0;
                    m_axi_o.data.w.WLAST = '0;
                    m_axi_o.data.w.WSTRB = '0;
                end
            endcase
        end
        else begin
            RRESP_LEN_next = RRESP_LEN;

            ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
            ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

            RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
            RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
            BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
            BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

            s_axis_req_o.TREADY = '1;

            m_axi_o.AWVALID = '0;
            m_axi_o.data.aw.AWID = '0;
            m_axi_o.data.aw.AWADDR = '0;
            m_axi_o.data.aw.AWLEN = '0;
            m_axi_o.data.aw.AWSIZE = '0;
            m_axi_o.data.aw.AWBURST = '0;

            m_axi_o.ARVALID = '0;
            m_axi_o.data.ar.ARID = '0;
            m_axi_o.data.ar.ARADDR = '0;
            m_axi_o.data.ar.ARLEN = '0;
            m_axi_o.data.ar.ARSIZE = '0;
            m_axi_o.data.ar.ARBURST = '0;

            m_axi_o.WVALID = '0;
            m_axi_o.data.w.WDATA = '0;
            m_axi_o.data.w.WLAST = '0;
            m_axi_o.data.w.WSTRB = '0;
        end
    end

    always_comb begin
        if (s_axis_resp_i.TVALID) begin
            case (s_axis_resp_i.data.TID)
                ROUTING_HEADER: begin
                    s_axis_resp_o.TREADY = '1;
                    
                    s_axi_o.BVALID = '0;
                    s_axi_i.data.b.BID = '0;

                    s_axi_o.RVALID = '0;
                    s_axi_i.data.r.RID = '0;
                    s_axi_i.data.r.RDATA = '0;
                    s_axi_i.data.r.RLAST = '0;
                end
                B_SUBHEADER: begin
                    s_axis_resp_o.TREADY = s_axi_i.data.BREADY;

                    s_axi_o.BVALID = s_axis_resp_i.TVALID;
                    s_axi_i.data.b.BID = b_subheader_i.ID;

                    s_axi_o.RVALID = '0;
                    s_axi_i.data.r.RID = '0;
                    s_axi_i.data.r.RDATA = '0;
                    s_axi_i.data.r.RLAST = '0;
                end
                R_DATA: begin
                    s_axis_resp_o.TREADY = s_axi_i.data.RREADY;

                    s_axi_o.BVALID = '0;
                    s_axi_i.data.b.BID = '0;

                    s_axi_o.RVALID = s_axis_resp_i.TVALID;
                    s_axi_i.data.r.RID = r_data_i.ID;
                    s_axi_i.data.r.RDATA = r_data_i.DATA;
                    s_axi_i.data.r.RLAST = s_axis_resp_i.data.TLAST;                
                end
                default: begin
                    s_axis_resp_o.TREADY = '1;

                    s_axi_o.BVALID = '0;
                    s_axi_i.data.b.BID = '0;

                    s_axi_o.RVALID = '0;
                    s_axi_i.data.r.RID = '0;
                    s_axi_i.data.r.RDATA = '0;
                    s_axi_i.data.r.RLAST = '0;
                end
            endcase
        end
        else begin
            s_axis_resp_o.TREADY = '1;

            s_axi_o.BVALID = '0;
            s_axi_i.data.b.BID = '0;

            s_axi_o.RVALID = '0;
            s_axi_i.data.r.RID = '0;
            s_axi_i.data.r.RDATA = '0;
            s_axi_i.data.r.RLAST = '0;
        end
    end


endmodule