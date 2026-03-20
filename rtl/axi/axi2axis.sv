`include "defines.svh"
`include "axi_defines.svh"
`include "axis_defines.svh"
`include "axi2axis_typedef.svh"

module axi2axis #(
    parameter        AXI_DATA_WIDTH  = 32,
    parameter        AXI_ADDR_WIDTH  = 16,
    parameter        AXI_ID_W_WIDTH  = 4,
    parameter        AXI_ID_R_WIDTH  = 4,
    
    parameter        AXIS_DATA_WIDTH = 40,
    parameter        AXIS_ID_WIDTH   = 4,
    parameter        AXIS_DEST_WIDTH = 4,
    parameter        AXIS_USER_WIDTH = 4,

    parameter string COORDINATES = "N",

    parameter        ROUTER_X      = 0,
    parameter        ROUTER_Y      = 0,
    parameter        MAX_ROUTERS_X = 4,
    parameter        MAX_ROUTERS_Y = 4,

    parameter        ROUTER_N = 0,
    parameter        ROUTERS_COUNT = 16,

    parameter        MAX_ROUTERS_X_WIDTH = $clog2(MAX_ROUTERS_X),
    parameter        MAX_ROUTERS_Y_WIDTH = $clog2(MAX_ROUTERS_Y),

    parameter        ROUTERS_COUNT_WIDTH = $clog2(ROUTERS_COUNT)
) (
    input ACLK, ARESETn,

    axi_if.s  s_axi_if_i,
    axi_if.m  m_axi_if_o,

    axis_if.s s_axis_if_resp_i,
    axis_if.m m_axis_if_resp_o,

    axis_if.s s_axis_if_req_i,
    axis_if.m m_axis_if_req_o
    
);

    `GENERATE_AXI_TYPEDEFS


    axi_mosi_t dummy_mosi;
    axi_miso_t dummy_miso;

    localparam AW_WIDTH     = $bits(dummy_mosi.data.aw);
    localparam W_WIDTH      = $bits(dummy_mosi.data.w);
    localparam B_WIDTH      = $bits(dummy_miso.data.b);
    localparam AR_WIDTH     = $bits(dummy_mosi.data.ar);
    localparam R_WIDTH      = $bits(dummy_miso.data.r);

    localparam AW_REMAINDER = AW_WIDTH % AXIS_DATA_WIDTH;
    localparam W_REMAINDER  = W_WIDTH % AXIS_DATA_WIDTH;
    localparam B_REMAINDER  = B_WIDTH % AXIS_DATA_WIDTH;
    localparam AR_REMAINDER = AR_WIDTH % AXIS_DATA_WIDTH;
    localparam R_REMAINDER  = R_WIDTH % AXIS_DATA_WIDTH;

    localparam AW_FILLER    = AXIS_DATA_WIDTH - AW_REMAINDER;
    localparam W_FILLER     = AXIS_DATA_WIDTH - W_REMAINDER;
    localparam B_FILLER     = AXIS_DATA_WIDTH - B_REMAINDER;
    localparam AR_FILLER    = AXIS_DATA_WIDTH - AR_REMAINDER;
    localparam R_FILLER     = AXIS_DATA_WIDTH - R_REMAINDER;



    axi_mosi_t s_axi_i, m_axi_o;
    axi_miso_t s_axi_o, m_axi_i;
    `AXI_INTERFACE_SLAVE2TYPEDEF(s_axi_if_i, s_axi_i, s_axi_o)
    `AXI_INTERFACE_MASTER2TYPEDEF(m_axi_if_o, m_axi_o, m_axi_i)
    

    `GENERATE_AXIS_TYPEDEFS

    axis_mosi_t s_axis_resp_i, m_axis_resp_o;
    axis_miso_t s_axis_resp_o, m_axis_resp_i;
    `AXIS_INTERFACE_SLAVE2TYPEDEF(s_axis_if_resp_i, s_axis_resp_i, s_axis_resp_o)
    `AXIS_INTERFACE_MASTER2TYPEDEF(m_axis_if_resp_o, m_axis_resp_o, m_axis_resp_i)
    
    axis_mosi_t s_axis_req_i, m_axis_req_o;
    axis_miso_t s_axis_req_o, m_axis_req_i;
    `AXIS_INTERFACE_SLAVE2TYPEDEF(s_axis_if_req_i, s_axis_req_i, s_axis_req_o)
    `AXIS_INTERFACE_MASTER2TYPEDEF(m_axis_if_req_o, m_axis_req_o, m_axis_req_i)

    typedef struct packed {
        logic [AXIS_DATA_WIDTH - ((MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH) * 2) - 1:0] RESERVED;
        logic [MAX_ROUTERS_X_WIDTH-1:0] SOURCE_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] SOURCE_Y;
        logic [MAX_ROUTERS_X_WIDTH-1:0] DESTINATION_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] DESTINATION_Y;
    } routing_header_XY_t;

    typedef struct packed {
        logic [AXIS_DATA_WIDTH - (ROUTERS_COUNT_WIDTH * 2) - 1:0] RESERVED;
        logic [ROUTERS_COUNT_WIDTH-1:0] SOURCE_N;
        logic [ROUTERS_COUNT_WIDTH-1:0] DESTINATION_N;
    } routing_header_N_t;

    // response coordinate logic XY
    logic [MAX_ROUTERS_X_WIDTH-1:0] TEMP_X, TEMP_X_next;
    logic [MAX_ROUTERS_X_WIDTH-1:0] TEMP_Y, TEMP_Y_next;
    logic [MAX_ROUTERS_X_WIDTH-1:0] RRESP_DESTINATION_X, RRESP_DESTINATION_X_next;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] RRESP_DESTINATION_Y, RRESP_DESTINATION_Y_next;
    logic [MAX_ROUTERS_X_WIDTH-1:0] BRESP_DESTINATION_X, BRESP_DESTINATION_X_next;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] BRESP_DESTINATION_Y, BRESP_DESTINATION_Y_next;

    // response coordinate logic N
    logic [ROUTERS_COUNT_WIDTH-1:0] TEMP_N, TEMP_N_next;
    logic [ROUTERS_COUNT_WIDTH-1:0] RRESP_DESTINATION_N, RRESP_DESTINATION_N_next;
    logic [ROUTERS_COUNT_WIDTH-1:0] BRESP_DESTINATION_N, BRESP_DESTINATION_N_next;


    logic [2:0] request_data_o, response_data_o;
    logic request_valid_o, response_valid_o;
    logic request_ready_i, response_ready_i;

    routing_header_XY_t routing_header_req_XY_o, routing_header_resp_XY_o;
    routing_header_N_t routing_header_req_N_o, routing_header_resp_N_o;

    logic w_send, w_send_next;
    logic [63:0] aw_send_bits_count, aw_send_bits_count_next;
    logic [63:0] w_send_bits_count, w_send_bits_count_next;
    logic [63:0] b_send_bits_count, b_send_bits_count_next;
    logic [63:0] ar_send_bits_count, ar_send_bits_count_next;
    logic [63:0] r_send_bits_count, r_send_bits_count_next;

    logic w_receive, w_receive_next;
    logic [63:0] aw_receive_bits_count, aw_receive_bits_count_next;
    logic [63:0] w_receive_bits_count, w_receive_bits_count_next;
    logic [63:0] b_receive_bits_count, b_receive_bits_count_next;
    logic [63:0] ar_receive_bits_count, ar_receive_bits_count_next;
    logic [63:0] r_receive_bits_count, r_receive_bits_count_next;

    axi_data_aw_t m_axi_o_data_aw_next;
    axi_data_w_t m_axi_o_data_w_next;
    axi_data_ar_t m_axi_o_data_ar_next;

    axi_data_b_t s_axi_o_data_b_next;
    axi_data_r_t s_axi_o_data_r_next;
    
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
        .valid_i({m_axi_i.BVALID, m_axi_i.RVALID}),
        // .ready_o(READY_arbiter_o),

        .data_o(response_data_o),
        .valid_o(response_valid_o),
        .ready_i(response_ready_i)
    );


    enum {GENERATE_HEADER, WRITE_SEND, READ_SEND} out_resp_state, out_resp_state_next, out_req_state, out_req_state_next;


    // --- req fsm ---

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            out_req_state <= GENERATE_HEADER;
            aw_send_bits_count <= '0;
            w_send_bits_count <= '0;
            ar_send_bits_count <= '0;
            w_send <= '0;
        end
        else begin
            out_req_state <= out_req_state_next;
            aw_send_bits_count <= aw_send_bits_count_next;
            w_send_bits_count <= w_send_bits_count_next;
            ar_send_bits_count <= ar_send_bits_count_next;
            w_send <= w_send_next;
        end
    end

    always_comb begin
        out_req_state_next = out_req_state;

        case (out_req_state)
            GENERATE_HEADER: begin
                if (request_valid_o && m_axis_req_i.TREADY) begin
                    case (request_data_o)
                        AW: out_req_state_next = WRITE_SEND;
                        AR: out_req_state_next = READ_SEND;
                    endcase
                end
                else begin
                    out_req_state_next = GENERATE_HEADER;
                end
            end
            WRITE_SEND, READ_SEND: begin
                if (m_axis_req_o.TVALID && m_axis_req_o.data.TLAST && m_axis_req_i.TREADY) begin
                    out_req_state_next = GENERATE_HEADER;
                end
                else begin
                    out_req_state_next = out_req_state;
                end
            end
            default: begin
                out_req_state_next = GENERATE_HEADER;
            end
        endcase
    end

    generate
        always_comb begin
            aw_send_bits_count_next = aw_send_bits_count;
            w_send_bits_count_next = w_send_bits_count;
            ar_send_bits_count_next = ar_send_bits_count;
            w_send_next = w_send;

            routing_header_req_XY_o = '0;
            routing_header_req_N_o = '0;

            s_axi_o.AWREADY = '0;
            s_axi_o.ARREADY = '0;
            s_axi_o.WREADY = '0;
            
            m_axis_req_o.data.TDATA = '0;
            m_axis_req_o.TVALID = '0;
            m_axis_req_o.data.TID = ROUTING_HEADER_READ;
            m_axis_req_o.data.TLAST = '0;
            m_axis_req_o.data.TSTRB = '1;

            request_ready_i = m_axis_req_i.TREADY & m_axis_req_o.TVALID & m_axis_req_o.data.TLAST;

            case (out_req_state)
                GENERATE_HEADER: begin

                    if (request_valid_o) begin
                        if (request_data_o == AW) begin
                            m_axis_req_o.data.TID = ROUTING_HEADER_WRITE;
                            routing_header_req_XY_o.DESTINATION_X = (s_axi_i.data.aw.AWID - 1) % MAX_ROUTERS_X;
                            routing_header_req_XY_o.DESTINATION_Y = (s_axi_i.data.aw.AWID - 1) / MAX_ROUTERS_X;
                            routing_header_req_N_o.DESTINATION_N = s_axi_i.data.aw.AWID - 1;
                        end
                        else if (request_data_o == AR) begin
                            m_axis_req_o.data.TID = ROUTING_HEADER_READ;
                            routing_header_req_XY_o.DESTINATION_X = (s_axi_i.data.ar.ARID - 1) % MAX_ROUTERS_X;
                            routing_header_req_XY_o.DESTINATION_Y = (s_axi_i.data.ar.ARID - 1) / MAX_ROUTERS_X;
                            routing_header_req_N_o.DESTINATION_N = s_axi_i.data.ar.ARID - 1;
                        end

                        routing_header_req_XY_o.SOURCE_X = ROUTER_X;
                        routing_header_req_XY_o.SOURCE_Y = ROUTER_Y;
                        routing_header_req_N_o.SOURCE_N = ROUTER_N;

                        if (COORDINATES == "XY") begin
                            m_axis_req_o.data.TDATA = routing_header_req_XY_o;
                        end
                        else if (COORDINATES == "N") begin
                            m_axis_req_o.data.TDATA = routing_header_req_N_o;
                        end
                        
                        m_axis_req_o.TVALID = '1;
                        m_axis_req_o.data.TLAST = '0;
                    end
                end
                WRITE_SEND: begin
                    m_axis_req_o.data.TID = WRITE_REQUEST;

                    if (!w_send) begin
                        if (aw_send_bits_count + AXIS_DATA_WIDTH >= AW_WIDTH) begin
                            if(AW_REMAINDER > 0) begin
                                m_axis_req_o.data.TDATA = {{AW_FILLER{1'b0}}, s_axi_i.data.aw[aw_send_bits_count +: AW_REMAINDER]};
                            end
                            m_axis_req_o.TVALID = s_axi_i.AWVALID;
                            m_axis_req_o.data.TLAST = '0;
                            w_send_next = m_axis_req_i.TREADY && m_axis_req_o.TVALID;
                            
                            s_axi_o.AWREADY = m_axis_req_i.TREADY;

                            aw_send_bits_count_next = m_axis_req_o.TVALID && m_axis_req_i.TREADY ? '0 : aw_send_bits_count;
                        end
                        else begin
                            m_axis_req_o.data.TDATA = s_axi_i.data.aw[aw_send_bits_count +: AXIS_DATA_WIDTH];
                            m_axis_req_o.TVALID = s_axi_i.AWVALID;
                            m_axis_req_o.data.TLAST = '0;

                            s_axi_o.AWREADY = '0;

                            aw_send_bits_count_next = m_axis_req_o.TVALID && m_axis_req_i.TREADY ? aw_send_bits_count + AXIS_DATA_WIDTH : aw_send_bits_count;
                        end
                    end
                    else begin
                        if (w_send_bits_count + AXIS_DATA_WIDTH >= W_WIDTH) begin
                            if(W_REMAINDER > 0) begin
                                m_axis_req_o.data.TDATA = {{W_FILLER{1'b0}}, s_axi_i.data.w[w_send_bits_count +: W_REMAINDER]};
                            end
                            m_axis_req_o.TVALID = s_axi_i.WVALID;
                            m_axis_req_o.data.TLAST = s_axi_i.data.w.WLAST;
                            w_send_next = ~(m_axis_req_o.TVALID & m_axis_req_i.TREADY & m_axis_req_o.data.TLAST);
                            
                            s_axi_o.WREADY = m_axis_req_i.TREADY;

                            w_send_bits_count_next = m_axis_req_o.TVALID && m_axis_req_i.TREADY ? '0 : w_send_bits_count;
                        end
                        else begin
                            m_axis_req_o.data.TDATA = s_axi_i.data.w[w_send_bits_count +: AXIS_DATA_WIDTH];
                            m_axis_req_o.TVALID = s_axi_i.WVALID;
                            m_axis_req_o.data.TLAST = '0;
                            
                            s_axi_o.WREADY = '0;

                            w_send_bits_count_next = m_axis_req_o.TVALID && m_axis_req_i.TREADY ? w_send_bits_count + AXIS_DATA_WIDTH : w_send_bits_count;
                        end
                    end
                end
                READ_SEND: begin
                    m_axis_req_o.data.TID = READ_REQUEST;

                    if (ar_send_bits_count + AXIS_DATA_WIDTH >= AR_WIDTH) begin
                        if(AR_REMAINDER > 0) begin
                            m_axis_req_o.data.TDATA = {{AR_FILLER{1'b0}}, s_axi_i.data.ar[ar_send_bits_count +: AR_REMAINDER]};
                        end
                        m_axis_req_o.TVALID = s_axi_i.ARVALID;
                        m_axis_req_o.data.TLAST = '1;

                        s_axi_o.ARREADY = m_axis_req_i.TREADY;

                        ar_send_bits_count_next = m_axis_req_o.TVALID && m_axis_req_i.TREADY ? '0 : ar_send_bits_count;
                    end
                    else begin
                        m_axis_req_o.data.TDATA = s_axi_i.data.ar[ar_send_bits_count +: AXIS_DATA_WIDTH];
                        m_axis_req_o.TVALID = s_axi_i.ARVALID;
                        m_axis_req_o.data.TLAST = '0;

                        s_axi_o.ARREADY = '0;

                        ar_send_bits_count_next = m_axis_req_o.TVALID && m_axis_req_i.TREADY ? ar_send_bits_count + AXIS_DATA_WIDTH : ar_send_bits_count;
                    end
                end
            endcase
        end
    endgenerate


    // --- resp fsm ---
    
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            out_resp_state <= GENERATE_HEADER;
            b_send_bits_count <= '0;
            r_send_bits_count <= '0;
        end
        else begin
            out_resp_state <= out_resp_state_next;
            b_send_bits_count <= b_send_bits_count_next;
            r_send_bits_count <= r_send_bits_count_next;
        end
    end

    always_comb begin
        out_resp_state_next = out_resp_state;

        case (out_resp_state)
            GENERATE_HEADER: begin
                if (response_valid_o && m_axis_resp_i.TREADY) begin
                    case (response_data_o)
                        B: out_resp_state_next = WRITE_SEND;
                        R: out_resp_state_next = READ_SEND;
                    endcase
                end
                else begin
                    out_resp_state_next = GENERATE_HEADER;
                end
            end
            WRITE_SEND, READ_SEND: begin
                if (m_axis_resp_o.TVALID && m_axis_resp_o.data.TLAST && m_axis_resp_i.TREADY) begin
                    out_resp_state_next = GENERATE_HEADER;
                end
                else begin
                    out_resp_state_next = out_resp_state;
                end
            end
            default: begin
                out_resp_state_next = GENERATE_HEADER;
            end
        endcase
    end

    always_comb begin
        b_send_bits_count_next = b_send_bits_count;
        r_send_bits_count_next = r_send_bits_count;

        routing_header_resp_XY_o = '0;
        routing_header_resp_N_o = '0;

        m_axi_o.BREADY = '0;
        m_axi_o.RREADY = '0;

        m_axis_resp_o.data.TDATA = '0;
        m_axis_resp_o.TVALID = '0;
        m_axis_resp_o.data.TID = ROUTING_HEADER_READ;
        m_axis_resp_o.data.TLAST = '0;
        m_axis_resp_o.data.TSTRB = '1;

        response_ready_i = m_axis_resp_i.TREADY & m_axis_resp_o.TVALID & m_axis_resp_o.data.TLAST;

        case (out_resp_state)
            GENERATE_HEADER: begin

                if (response_valid_o) begin
                    if (response_data_o == B) begin
                        m_axis_resp_o.data.TID = ROUTING_HEADER_WRITE;
                        routing_header_resp_XY_o.DESTINATION_X = BRESP_DESTINATION_X;
                        routing_header_resp_XY_o.DESTINATION_Y = BRESP_DESTINATION_Y;
                        routing_header_resp_N_o.DESTINATION_N = BRESP_DESTINATION_N;
                    end
                    else if (response_data_o == R) begin
                        m_axis_resp_o.data.TID = ROUTING_HEADER_READ;
                        routing_header_resp_XY_o.DESTINATION_X = RRESP_DESTINATION_X;
                        routing_header_resp_XY_o.DESTINATION_Y = RRESP_DESTINATION_Y;
                        routing_header_resp_N_o.DESTINATION_N = RRESP_DESTINATION_N;
                    end

                    routing_header_resp_XY_o.SOURCE_X = ROUTER_X;
                    routing_header_resp_XY_o.SOURCE_Y = ROUTER_Y;
                    routing_header_resp_N_o.SOURCE_N = ROUTER_N;

                    if (COORDINATES == "XY") begin
                        m_axis_resp_o.data.TDATA = routing_header_resp_XY_o;
                    end
                    else if (COORDINATES == "N") begin
                        m_axis_resp_o.data.TDATA = routing_header_resp_N_o;
                    end

                    m_axis_resp_o.TVALID = '1;
                    m_axis_resp_o.data.TLAST = '0;
                end
            end
            WRITE_SEND: begin
                m_axis_resp_o.data.TID = WRITE_RESPONSE;

                if (b_send_bits_count + AXIS_DATA_WIDTH >= B_WIDTH) begin
                    if(B_REMAINDER > 0) begin
                        m_axis_resp_o.data.TDATA = {{B_FILLER{1'b0}}, m_axi_i.data.b[b_send_bits_count +: B_REMAINDER]};
                    end
                    m_axis_resp_o.TVALID = m_axi_i.BVALID;
                    m_axis_resp_o.data.TLAST = '1;

                    m_axi_o.BREADY = m_axis_resp_i.TREADY;

                    b_send_bits_count_next = m_axis_resp_o.TVALID && m_axis_resp_i.TREADY ? '0 : b_send_bits_count;
                end
                else begin
                    m_axis_resp_o.data.TDATA = m_axi_i.data.b[b_send_bits_count +: AXIS_DATA_WIDTH];
                    m_axis_resp_o.TVALID = m_axi_i.BVALID;
                    m_axis_resp_o.data.TLAST = '0;
                    
                    m_axi_o.BREADY = '0;

                    b_send_bits_count_next = m_axis_resp_o.TVALID && m_axis_resp_i.TREADY ? b_send_bits_count + AXIS_DATA_WIDTH : b_send_bits_count;
                end
            end
            READ_SEND: begin
                m_axis_resp_o.data.TID = READ_RESPONSE;

                if (r_send_bits_count + AXIS_DATA_WIDTH >= R_WIDTH) begin
                    if(R_REMAINDER > 0) begin
                        m_axis_resp_o.data.TDATA = {{R_FILLER{1'b0}}, m_axi_i.data.r[r_send_bits_count +: R_REMAINDER]};
                    end
                    m_axis_resp_o.TVALID = m_axi_i.RVALID;
                    m_axis_resp_o.data.TLAST = m_axi_i.data.r.RLAST;

                    m_axi_o.RREADY = m_axis_resp_i.TREADY;

                    r_send_bits_count_next = m_axis_resp_o.TVALID && m_axis_resp_i.TREADY ? '0 : r_send_bits_count;
                end
                else begin
                    m_axis_resp_o.data.TDATA = m_axi_i.data.r[r_send_bits_count +: AXIS_DATA_WIDTH];
                    m_axis_resp_o.TVALID = m_axi_i.RVALID;
                    m_axis_resp_o.data.TLAST = '0;

                    m_axi_o.RREADY = '0;

                    r_send_bits_count_next = m_axis_resp_o.TVALID && m_axis_resp_i.TREADY ? r_send_bits_count + AXIS_DATA_WIDTH : r_send_bits_count;
                end
            end
        endcase
    end

    // --- axis in logic ---

    routing_header_XY_t routing_header_req_XY_i, routing_header_resp_XY_i;
    routing_header_N_t routing_header_req_N_i, routing_header_resp_N_i;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            TEMP_X <= '0;
            TEMP_Y <= '0;
            RRESP_DESTINATION_X <= '0;
            RRESP_DESTINATION_Y <= '0;
            BRESP_DESTINATION_X <= '0;
            BRESP_DESTINATION_Y <= '0;

            TEMP_N <= '0;
            RRESP_DESTINATION_N <= '0;
            BRESP_DESTINATION_N <= '0;

            aw_receive_bits_count <= '0;
            w_receive_bits_count <= '0;
            b_receive_bits_count <= '0;
            ar_receive_bits_count <= '0;
            r_receive_bits_count <= '0;

            w_receive <= '0;
        end
        else begin
            TEMP_X <= TEMP_X_next;
            TEMP_Y <= TEMP_Y_next;
            RRESP_DESTINATION_X <= RRESP_DESTINATION_X_next;
            RRESP_DESTINATION_Y <= RRESP_DESTINATION_Y_next;
            BRESP_DESTINATION_X <= BRESP_DESTINATION_X_next;
            BRESP_DESTINATION_Y <= BRESP_DESTINATION_Y_next;

            TEMP_N <= TEMP_N_next;
            RRESP_DESTINATION_N <= RRESP_DESTINATION_N_next;
            BRESP_DESTINATION_N <= BRESP_DESTINATION_N_next;

            aw_receive_bits_count <= aw_receive_bits_count_next;
            w_receive_bits_count <= w_receive_bits_count_next;
            b_receive_bits_count <= b_receive_bits_count_next;
            ar_receive_bits_count <= ar_receive_bits_count_next;
            r_receive_bits_count <= r_receive_bits_count_next;

            w_receive <= w_receive_next;
        end
    end

    generate
        if (AW_WIDTH != AW_REMAINDER) begin : aw_remainder
            always_ff @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    m_axi_o.data.aw[0 +: AW_WIDTH - AW_REMAINDER] <= '0;
                end
                else begin
                    m_axi_o.data.aw[0 +: AW_WIDTH - AW_REMAINDER] <= m_axi_o_data_aw_next;
                end
            end
        end
        if (W_WIDTH != W_REMAINDER) begin : w_remainder
            always_ff @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    m_axi_o.data.w[0 +: W_WIDTH - W_REMAINDER] <= '0;
                end
                else begin
                    m_axi_o.data.w[0 +: W_WIDTH - W_REMAINDER] <= m_axi_o_data_w_next;
                end
            end
        end
        if (B_WIDTH != B_REMAINDER) begin : b_remainder
            always_ff @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    s_axi_o.data.b[0 +: B_WIDTH - B_REMAINDER] <= '0;
                end
                else begin
                    s_axi_o.data.b[0 +: B_WIDTH - B_REMAINDER] <= s_axi_o_data_b_next;
                end
            end
        end
        if (AR_WIDTH != AR_REMAINDER) begin : ar_remainder
            always_ff @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    m_axi_o.data.ar[0 +: AR_WIDTH - AR_REMAINDER] <= '0;
                end
                else begin
                    m_axi_o.data.ar[0 +: AR_WIDTH - AR_REMAINDER] <= m_axi_o_data_ar_next;
                end
            end
        end
        if (R_WIDTH != R_REMAINDER) begin : r_remainder
            always_ff @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    s_axi_o.data.r[0 +: R_WIDTH - R_REMAINDER] <= '0;
                end
                else begin
                    s_axi_o.data.r[0 +: R_WIDTH - R_REMAINDER] <= s_axi_o_data_r_next;
                end
            end
        end
    endgenerate


    generate
        always_comb begin
            if (COORDINATES == "XY") begin
                routing_header_req_XY_i = s_axis_req_i.data.TDATA;
                routing_header_resp_XY_i = s_axis_resp_i.data.TDATA;
            end
            else if (COORDINATES == "N") begin
                routing_header_req_N_i = s_axis_req_i.data.TDATA;
                routing_header_resp_N_i = s_axis_resp_i.data.TDATA;
            end
            
            if(AW_REMAINDER > 0) begin
                m_axi_o.data.aw[AW_WIDTH-1 -: AW_REMAINDER] = s_axis_req_i.data.TDATA[0 +: AW_REMAINDER];
            end
            if(W_REMAINDER > 0) begin
                m_axi_o.data.w[W_WIDTH-1 -: W_REMAINDER] = s_axis_req_i.data.TDATA[0 +: W_REMAINDER];
            end
            if(B_REMAINDER > 0) begin
                s_axi_o.data.b[B_WIDTH-1 -: B_REMAINDER] = s_axis_resp_i.data.TDATA[0 +: B_REMAINDER];
            end
            if(AR_REMAINDER > 0) begin
                m_axi_o.data.ar[AR_WIDTH-1 -: AR_REMAINDER] = s_axis_req_i.data.TDATA[0 +: AR_REMAINDER];
            end
            if(R_REMAINDER > 0) begin
                s_axi_o.data.r[R_WIDTH-1 -: R_REMAINDER] = s_axis_resp_i.data.TDATA[0 +: R_REMAINDER];
            end
        end
    endgenerate

    generate
        always_comb begin
            TEMP_X_next = TEMP_X;
            TEMP_Y_next = TEMP_Y;
            RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
            RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
            BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
            BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

            TEMP_N_next = TEMP_N;
            RRESP_DESTINATION_N_next = RRESP_DESTINATION_N;
            BRESP_DESTINATION_N_next = BRESP_DESTINATION_N;

            aw_receive_bits_count_next = aw_receive_bits_count;
            w_receive_bits_count_next = w_receive_bits_count;
            ar_receive_bits_count_next = ar_receive_bits_count;

            m_axi_o_data_aw_next = m_axi_o.data.aw;
            m_axi_o_data_w_next = m_axi_o.data.w;
            m_axi_o_data_ar_next = m_axi_o.data.ar;

            w_receive_next = w_receive;

            s_axis_req_o.TREADY = '0;
            
            m_axi_o.AWVALID = '0;
            m_axi_o.WVALID = '0;
            m_axi_o.ARVALID = '0;

            if (s_axis_req_i.TVALID) begin
                case (s_axis_req_i.data.TID)
                    ROUTING_HEADER_WRITE, ROUTING_HEADER_READ: begin
                        s_axis_req_o.TREADY = '1;
                        if (COORDINATES == "XY") begin
                            TEMP_X_next = routing_header_req_XY_i.SOURCE_X;
                            TEMP_Y_next = routing_header_req_XY_i.SOURCE_Y;
                        end
                        else if (COORDINATES == "N") begin
                            TEMP_N_next = routing_header_req_N_i.SOURCE_N;
                        end
                    end
                    WRITE_REQUEST: begin
                        if (!w_receive) begin
                            if (aw_receive_bits_count + AXIS_DATA_WIDTH >= AW_WIDTH) begin
                                if(AW_REMAINDER > 0) begin
                                    m_axi_o_data_aw_next[AW_WIDTH-1 -: AW_REMAINDER] = s_axis_req_i.data.TDATA[0 +: AW_REMAINDER];
                                end
                                m_axi_o.AWVALID = '1;
                                s_axis_req_o.TREADY = m_axi_i.AWREADY;

                                if (s_axis_req_o.TREADY) begin
                                    if (COORDINATES == "XY") begin
                                        BRESP_DESTINATION_X_next = TEMP_X;
                                        BRESP_DESTINATION_Y_next = TEMP_Y;
                                    end
                                    else if (COORDINATES == "N") begin
                                        BRESP_DESTINATION_N_next = TEMP_N;
                                    end
                                end

                                w_receive_next = s_axis_req_o.TREADY && s_axis_req_i.TVALID;

                                aw_receive_bits_count_next = s_axis_req_i.TVALID && s_axis_req_o.TREADY ? '0 : aw_receive_bits_count;
                            end
                            else begin
                                m_axi_o_data_aw_next[aw_receive_bits_count +: AXIS_DATA_WIDTH] = s_axis_req_i.data.TDATA;
                                m_axi_o.AWVALID = '0;
                                s_axis_req_o.TREADY = '1;

                                aw_receive_bits_count_next = s_axis_req_i.TVALID && s_axis_req_o.TREADY ? aw_receive_bits_count + AXIS_DATA_WIDTH : aw_receive_bits_count;
                            end
                        end
                        else begin
                            if (w_receive_bits_count + AXIS_DATA_WIDTH >= W_WIDTH) begin
                                if(W_REMAINDER > 0) begin
                                    m_axi_o_data_w_next[W_WIDTH-1 -: W_REMAINDER] = s_axis_req_i.data.TDATA[0 +: W_REMAINDER];
                                end
                                m_axi_o.WVALID = '1;
                                s_axis_req_o.TREADY = m_axi_i.WREADY;

                                w_receive_next = ~(s_axis_req_i.TVALID & s_axis_req_o.TREADY & s_axis_req_i.data.TLAST);

                                w_receive_bits_count_next = s_axis_req_i.TVALID && s_axis_req_o.TREADY ? '0 : w_receive_bits_count;
                            end
                            else begin
                                m_axi_o_data_w_next[w_receive_bits_count +: AXIS_DATA_WIDTH] = s_axis_req_i.data.TDATA;
                                m_axi_o.WVALID = '0;
                                s_axis_req_o.TREADY = '1;

                                w_receive_bits_count_next = s_axis_req_i.TVALID && s_axis_req_o.TREADY ? w_receive_bits_count + AXIS_DATA_WIDTH : w_receive_bits_count;
                            end
                        end
                    end
                    READ_REQUEST: begin
                        if (ar_receive_bits_count + AXIS_DATA_WIDTH >= AR_WIDTH) begin
                            if(AR_REMAINDER > 0) begin
                                m_axi_o_data_ar_next[AR_WIDTH-1 -: AR_REMAINDER] = s_axis_req_i.data.TDATA[0 +: AR_REMAINDER];
                            end
                            m_axi_o.ARVALID = '1;
                            s_axis_req_o.TREADY = m_axi_i.ARREADY;

                            if (s_axis_req_o.TREADY) begin
                                if (COORDINATES == "XY") begin
                                    RRESP_DESTINATION_X_next = TEMP_X;
                                    RRESP_DESTINATION_Y_next = TEMP_Y;
                                end
                                else if (COORDINATES == "N") begin
                                    RRESP_DESTINATION_N_next = TEMP_N;
                                end
                            end

                            ar_receive_bits_count_next = s_axis_req_i.TVALID && s_axis_req_o.TREADY ? '0 : ar_receive_bits_count;
                        end
                        else begin
                            m_axi_o_data_ar_next[ar_receive_bits_count +: AXIS_DATA_WIDTH] = s_axis_req_i.data.TDATA;
                            m_axi_o.ARVALID = '0;
                            s_axis_req_o.TREADY = '1;

                            ar_receive_bits_count_next = s_axis_req_i.TVALID && s_axis_req_o.TREADY ? ar_receive_bits_count + AXIS_DATA_WIDTH : ar_receive_bits_count;
                        end
                    end
                endcase
            end
        end
    endgenerate

    generate
        always_comb begin
            b_receive_bits_count_next = b_receive_bits_count;
            r_receive_bits_count_next = r_receive_bits_count;

            s_axi_o_data_b_next = s_axi_o.data.b;
            s_axi_o_data_r_next = s_axi_o.data.r;

            s_axis_resp_o.TREADY = '0;
            
            s_axi_o.BVALID = '0;
            s_axi_o.RVALID = '0;

            
            if (s_axis_resp_i.TVALID) begin
                case (s_axis_resp_i.data.TID)
                    ROUTING_HEADER_WRITE, ROUTING_HEADER_READ: begin
                        s_axis_resp_o.TREADY = '1;
                    end
                    WRITE_RESPONSE: begin
                        if (b_receive_bits_count + AXIS_DATA_WIDTH >= B_WIDTH) begin
                            if(B_REMAINDER > 0) begin
                                s_axi_o_data_b_next[B_WIDTH-1 -: B_REMAINDER] = s_axis_resp_i.data.TDATA[0 +: B_REMAINDER];
                            end
                            s_axi_o.BVALID = '1;
                            s_axis_resp_o.TREADY = s_axi_i.BREADY;

                            b_receive_bits_count_next = s_axis_resp_i.TVALID && s_axis_resp_o.TREADY ? '0 : b_receive_bits_count;
                        end
                        else begin
                            s_axi_o_data_b_next[b_receive_bits_count +: AXIS_DATA_WIDTH] = s_axis_resp_i.data.TDATA;
                            s_axi_o.BVALID = '0;
                            s_axis_resp_o.TREADY = '1;

                            b_receive_bits_count_next = s_axis_resp_i.TVALID && s_axis_resp_o.TREADY ? b_receive_bits_count + AXIS_DATA_WIDTH : b_receive_bits_count;
                        end
                    end
                    READ_RESPONSE: begin
                        if (r_receive_bits_count + AXIS_DATA_WIDTH >= R_WIDTH) begin
                            if(R_REMAINDER > 0) begin
                                s_axi_o_data_r_next[R_WIDTH-1 -: R_REMAINDER] = s_axis_resp_i.data.TDATA[0 +: R_REMAINDER];
                            end
                            s_axi_o.RVALID = '1;
                            s_axis_resp_o.TREADY = s_axi_i.RREADY;

                            r_receive_bits_count_next = s_axis_resp_i.TVALID && s_axis_resp_o.TREADY ? '0 : r_receive_bits_count;
                        end
                        else begin
                            s_axi_o_data_r_next[r_receive_bits_count +: AXIS_DATA_WIDTH] = s_axis_resp_i.data.TDATA;
                            s_axi_o.RVALID = '0;
                            s_axis_resp_o.TREADY = '1;

                            r_receive_bits_count_next = s_axis_resp_i.TVALID && s_axis_resp_o.TREADY ? r_receive_bits_count + AXIS_DATA_WIDTH : r_receive_bits_count;
                        end
                    end
                endcase
            end
        end
    endgenerate

endmodule
