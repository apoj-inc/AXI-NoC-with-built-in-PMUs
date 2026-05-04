`include "defines.svh"
`include "axi_defines.svh"

module axi_master_loader #(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 16,
    parameter AXI_ID_W_WIDTH = 5 ,
    parameter AXI_ID_R_WIDTH = 5 ,

    parameter FIFO_DEPTH     = 64,
    parameter LOADER_ID      = 0 ,

    parameter FIFO_ADDR_WIDTH = FIFO_DEPTH == 1 ? 1 : $clog2(FIFO_DEPTH)                            ,
    parameter AXI_DATA_BYTES = AXI_DATA_WIDTH / 8 + (AXI_DATA_WIDTH % 8 != 0)                       ,
    parameter AXI_MAX_ID_WIDTH = (AXI_ID_W_WIDTH > AXI_ID_R_WIDTH) ? AXI_ID_W_WIDTH : AXI_ID_R_WIDTH
) (
    input  logic                        clk_in      ,
    input  logic                        rst_n_in    ,

    input  logic                        resp_wait_i ,
    input  logic [AXI_MAX_ID_WIDTH-1:0] id_i        ,
    input  logic                        write_i     ,
    input  logic [AXI_ADDR_WIDTH-1:0]   axaddr_i    ,
    input  logic [7:0]                  axlen_i     ,
    input  logic [AXI_DATA_WIDTH-1:0]   wdata_i     ,
    input  logic [AXI_DATA_BYTES-1:0]   wstrb_i     ,
    input  logic                        fifo_push_i ,

    input  logic                        clk_axi     ,
    input  logic                        rst_n_axi   ,

    input  logic                        start_i     ,
    output logic                        idle_o      ,

    output logic [AXI_DATA_WIDTH-1:0]   rdata_o     ,

    axi_if.m                            m_axi_if_o  
);

    `GENERATE_AXI_TYPEDEFS

    axi_mosi_t m_axi_o;
    axi_miso_t m_axi_i;
    `AXI_INTERFACE_MASTER2TYPEDEF(m_axi_if_o, m_axi_o, m_axi_i)

    typedef enum logic[1:0] {
        IDLE,
        MOSI,
        MISO
    } states_t;

    states_t state_w, state_w_next;
    states_t state_r, state_r_next;

    logic [AXI_DATA_WIDTH-1:0] wdata_rd;
    logic [AXI_DATA_BYTES-1:0] wstrb_rd;
    logic [AXI_ADDR_WIDTH-1:0] awaddr_rd, araddr_rd;
    logic [AXI_MAX_ID_WIDTH-1:0] awid_rd, arid_rd;
    logic [7:0] awlen_rd, arlen_rd;
    logic w_resp_wait_rd, r_resp_wait_rd;
    logic w_fifo_valid_rd, w_fifo_ready_rd, r_fifo_valid_rd, r_fifo_ready_rd;
    
    logic [7:0] w_hand_counter;
    logic [7:0] b_wait_cnt, b_wait_cnt_next, r_wait_cnt, r_wait_cnt_next;

    logic w_idle, r_idle;

    logic awlen_fifo_valid_rd, awlen_fifo_ready_rd;
    logic awlen_resp_wait_rd, awlen_wait;
    logic [7:0] awlen_current;


    assign m_axi_o.data.aw.AWID    = awid_rd;
    assign m_axi_o.data.aw.AWADDR  = awaddr_rd;
    assign m_axi_o.data.aw.AWLEN   = awlen_rd;
    assign m_axi_o.data.aw.AWSIZE  = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_o.data.aw.AWBURST = 2'b01;

    assign m_axi_o.data.w.WDATA   = wdata_rd;
    assign m_axi_o.data.w.WSTRB   = wstrb_rd;

    assign m_axi_o.BREADY  = 1'b1;

    assign m_axi_o.data.ar.ARID    = arid_rd;
    assign m_axi_o.data.ar.ARADDR  = araddr_rd;
    assign m_axi_o.data.ar.ARLEN   = arlen_rd;
    assign m_axi_o.data.ar.ARSIZE  = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_o.data.ar.ARBURST = 2'b01;

    assign m_axi_o.RREADY = 1'b1;

    assign idle_o = w_idle & r_idle;

    always_ff @(posedge clk_axi or negedge rst_n_axi) begin
        if (!rst_n_axi) begin
            rdata_o <= '0;
        end
        else begin
            if (m_axi_i.RVALID) begin
                rdata_o <= m_axi_i.data.r.RDATA;
            end
        end
    end

    /* --- W SECTION --- */

    cdc_stream_afifo #(
        .DATA_WIDTH (AXI_ADDR_WIDTH + AXI_MAX_ID_WIDTH + 1 + 8),
        .ADDR_WIDTH (FIFO_ADDR_WIDTH)
    ) u_stream_fifo_w (
        .clk_wr   (clk_in                                        ),
        .rst_n_wr (rst_n_in                                      ),

        .data_i   ({resp_wait_i, axaddr_i, axlen_i, id_i}        ),
        .valid_i  (fifo_push_i & write_i                         ),
        .ready_o  (                                              ), // NC
        .free_o   (                                              ), // NC

        .clk_rd   (clk_axi                                       ),
        .rst_n_rd (rst_n_axi                                     ),

        .data_o   ({w_resp_wait_rd, awaddr_rd, awlen_rd, awid_rd}),
        .valid_o  (w_fifo_valid_rd                               ),
        .ready_i  (w_fifo_ready_rd                               ),
        .count_o  (                                              )  // NC
    );

    always_ff @(posedge clk_axi or negedge rst_n_axi) begin
        if (!rst_n_axi) begin
            state_w <= IDLE;
            b_wait_cnt <= '0;
        end
        else begin
            state_w <= state_w_next;
            b_wait_cnt <= b_wait_cnt_next;
        end
    end

    always_comb begin
        case (state_w)
            IDLE: begin
                if (w_fifo_valid_rd && start_i) begin
                    state_w_next = MOSI;
                end
                else begin
                    state_w_next = IDLE; 
                end
            end
            MOSI: begin
                if (!w_fifo_valid_rd || (m_axi_o.AWVALID && m_axi_i.AWREADY && w_resp_wait_rd)) begin
                    state_w_next = MISO;
                end
                else begin
                    state_w_next = MOSI;
                end
            end
            MISO: begin
                if (b_wait_cnt == 0) begin
                    if (w_fifo_valid_rd) begin
                        state_w_next = MOSI;
                    end
                    else begin
                        state_w_next = IDLE;
                    end
                end
                else begin
                    state_w_next = MISO;
                end
            end
            default: begin
            end
        endcase
    end

    always_comb begin
        w_idle = '0;
        w_fifo_ready_rd = '0;

        m_axi_o.AWVALID = '0;

        b_wait_cnt_next = b_wait_cnt;

        case (state_w)
            IDLE: begin
                w_idle = '1;
            end
            MOSI: begin
                w_fifo_ready_rd = m_axi_i.AWREADY;

                if (w_fifo_valid_rd) begin
                    m_axi_o.AWVALID = '1;
                end

                b_wait_cnt_next = b_wait_cnt + (m_axi_o.AWVALID & m_axi_i.AWREADY) - (m_axi_i.BVALID & m_axi_o.BREADY);
            end
            MISO: begin
                b_wait_cnt_next = b_wait_cnt + (m_axi_o.AWVALID & m_axi_i.AWREADY) - (m_axi_i.BVALID & m_axi_o.BREADY);
            end
            default: begin
            end
        endcase
    end


    cdc_stream_afifo #(
        .DATA_WIDTH (1 + 8 + AXI_DATA_WIDTH + AXI_DATA_BYTES),
        .ADDR_WIDTH (FIFO_ADDR_WIDTH)
    ) u_stream_fifo_awlen (
        .clk_wr   (clk_in                                                 ),
        .rst_n_wr (rst_n_in                                               ),

        .data_i   ({resp_wait_i, axlen_i, wdata_i, wstrb_i}               ),
        .valid_i  (fifo_push_i & write_i                                  ),
        .ready_o  (                                                       ), // NC
        .free_o   (                                                       ), // NC

        .clk_rd   (clk_axi                                                ),
        .rst_n_rd (rst_n_axi                                              ),

        .data_o   ({awlen_resp_wait_rd, awlen_current, wdata_rd, wstrb_rd}),
        .valid_o  (awlen_fifo_valid_rd                                    ),
        .ready_i  (awlen_fifo_ready_rd                                    ),
        .count_o  (                                                       )  // NC
    );

    assign m_axi_o.WVALID = awlen_fifo_valid_rd & ~awlen_wait & (state_w != IDLE);
    assign m_axi_o.data.w.WLAST = (w_hand_counter == awlen_current);
    assign awlen_fifo_ready_rd = m_axi_o.WVALID & m_axi_i.WREADY & m_axi_o.data.w.WLAST;

    always_ff @(posedge clk_axi or negedge rst_n_axi) begin : blockName
        if (!rst_n_axi) begin
            w_hand_counter <= '0;
            awlen_wait <= '0;
        end
        else begin
            if (m_axi_o.WVALID && m_axi_i.WREADY) begin
                if (w_hand_counter == awlen_current) begin
                    w_hand_counter <= '0;
                end
                else begin
                    w_hand_counter <= w_hand_counter + 1;
                end
            end

            awlen_wait <= (awlen_wait | (awlen_resp_wait_rd & m_axi_o.WVALID & m_axi_i.WREADY & m_axi_o.data.w.WLAST)) & (b_wait_cnt != 0);
        end
    end


    /* --- R SECTION --- */
    cdc_stream_afifo #(
        .DATA_WIDTH (AXI_ADDR_WIDTH + AXI_MAX_ID_WIDTH + 1 + 8),
        .ADDR_WIDTH (FIFO_ADDR_WIDTH)
    ) u_stream_fifo_r (
        .clk_wr   (clk_in                                        ),
        .rst_n_wr (rst_n_in                                      ),

        .data_i   ({resp_wait_i, axaddr_i, axlen_i, id_i}        ),
        .valid_i  (fifo_push_i & ~write_i                        ),
        .ready_o  (                                              ), // NC
        .free_o   (                                              ), // NC

        .clk_rd   (clk_axi                                       ),
        .rst_n_rd (rst_n_axi                                     ),

        .data_o   ({r_resp_wait_rd, araddr_rd, arlen_rd, arid_rd}),
        .valid_o  (r_fifo_valid_rd                               ),
        .ready_i  (r_fifo_ready_rd                               ),
        .count_o  (                                              )  // NC
    );

    always_ff @(posedge clk_axi or negedge rst_n_axi) begin
        if (!rst_n_axi) begin
            state_r <= IDLE;
            r_wait_cnt <= '0;
        end
        else begin
            state_r <= state_r_next;
            r_wait_cnt <= r_wait_cnt_next;
        end
    end

    always_comb begin
        case (state_r)
            IDLE: begin
                if (r_fifo_valid_rd && start_i) begin
                    state_r_next = MISO;
                end
                else begin
                    state_r_next = IDLE; 
                end
            end
            MOSI: begin
                if (!r_fifo_valid_rd || (m_axi_o.ARVALID && m_axi_i.ARREADY && r_resp_wait_rd)) begin
                    state_r_next = MISO;
                end
                else begin
                    state_r_next = MOSI;
                end
            end
            MISO: begin
                if (r_wait_cnt == 0) begin
                    if (r_fifo_valid_rd) begin
                        state_r_next = MOSI;
                    end
                    else begin
                        state_r_next = IDLE;
                    end
                end
                else begin
                    state_r_next = MISO;
                end
            end
            default: begin
            end
        endcase
    end

    always_comb begin
        r_idle = '0;
        r_fifo_ready_rd = '0;

        m_axi_o.ARVALID = '0;

        r_wait_cnt_next = r_wait_cnt;

        case (state_r)
            IDLE: begin
                r_idle = '1;
            end
            MOSI: begin
                r_fifo_ready_rd = m_axi_i.ARREADY;

                if (r_fifo_valid_rd) begin
                    m_axi_o.ARVALID = '1;
                end

                r_wait_cnt_next = r_wait_cnt + (m_axi_o.ARVALID & m_axi_i.ARREADY) - (m_axi_i.RVALID & m_axi_o.RREADY & m_axi_i.data.r.RLAST);
            end
            MISO: begin
                r_wait_cnt_next = r_wait_cnt + (m_axi_o.ARVALID & m_axi_i.ARREADY) - (m_axi_i.RVALID & m_axi_o.RREADY & m_axi_i.data.r.RLAST);
            end
            default: begin
            end
        endcase
    end
    
endmodule