module avmm_dma_engine #(
    parameter DMA_OFFFSET_WIDTH = 22  ,
    parameter DMA_BYTES_WIDTH   = 22  ,

    parameter DMA_WQ_DEPTH      = 1024,
    parameter DMA_RQ_DEPTH      = 1024,

    parameter TX_DATA_WIDTH     = 128 ,
    parameter TX_ADDR_WIDTH     = 64  ,
    parameter TX_BURST_WIDTH    = 6   ,

    parameter DMA_BURST_WIDTH     = DMA_BYTES_WIDTH - 4                    ,
    parameter DMA_TASK_WIDTH      = 1 + DMA_OFFFSET_WIDTH + DMA_BURST_WIDTH,

    parameter TX_DATA_BYTES       = TX_DATA_WIDTH / 8                      ,
    parameter TX_DATA_BYTES_WIDTH = $clog2(TX_DATA_BYTES)                  ,
    parameter DMA_WQ_ADDR_WIDTH   = $clog2(DMA_WQ_DEPTH)                   ,
    parameter DMA_RQ_ADDR_WIDTH   = $clog2(DMA_RQ_DEPTH)                   
) (
    input  logic                       clk               ,
    input  logic                       rst_n             ,

    // MSIX table
    input  logic [31:0]                msix_mask_i       ,
    input  logic [31:0]                msix_data_i       ,
    input  logic [63:0]                msix_addr_i       ,

    input  logic                       pba_status_i      ,
    output logic                       pba_control_o     ,

    // CSR
    input  logic [63:0]                dma_addr_i        ,

    // DMA task channel
    input  logic                       dma_task_valid_i  ,
    output logic                       dma_task_ready_o  ,
    input  logic [DMA_TASK_WIDTH-1:0]  dma_task_data_i   ,

    // DMAWR data channel
    input  logic                       dma_wrdata_valid_i,
    output logic                       dma_wrdata_ready_o,
    input  logic [DMA_WQ_ADDR_WIDTH:0] dma_wrdata_count_i,
    input  logic [TX_DATA_WIDTH-1:0]   dma_wrdata_data_i ,

    // DMARD data channel
    output logic                       dma_rddata_valid_o,
    input  logic                       dma_rddata_ready_i,
    input  logic [DMA_RQ_ADDR_WIDTH:0] dma_rddata_free_i ,
    output logic [TX_DATA_WIDTH-1:0]   dma_rddata_data_o ,

    // To PC data channel
    output logic                       tx_chipselect     ,
    output logic [TX_DATA_BYTES-1:0]   tx_byteenable     ,
    input  logic [TX_DATA_WIDTH-1:0]   tx_readdata       ,
    output logic [TX_DATA_WIDTH-1:0]   tx_writedata      ,
    output logic                       tx_read           ,
    output logic                       tx_write          ,
    output logic [TX_BURST_WIDTH-1:0]  tx_burstcount     ,
    input  logic                       tx_readdatavalid  ,
    input  logic                       tx_waitrequest    ,
    output logic [TX_ADDR_WIDTH-1:0]   tx_address        
);

    assign tx_byteenable = '1;

    /* Write logic */

    typedef enum logic [2:0] {
        IDLE    ,
        READ    ,
        WRITE   ,
        GEN_MSI ,
        WAIT_MSI
    } state_t;

    typedef struct packed {
        logic [63:0]                  curr_addr  ;
        logic [5:0]                   curr_burst ;
        logic [DMA_BURST_WIDTH-1:0]   reads_left ;
        logic [DMA_BURST_WIDTH-1:0]   bursts_left;
        logic [DMA_BURST_WIDTH-1:0]   burstcount ;
        logic [DMA_OFFFSET_WIDTH-1:0] offset     ;
        logic                         write      ;
    } dma_descriptor_t;
    
    dma_descriptor_t dma_descriptor, dma_descriptor_next;
    dma_descriptor_t dma_task_decoder;
    
    state_t state, state_next;

    logic                      tx_chipselect_next;
    logic [TX_DATA_WIDTH-1:0]  tx_writedata_next ;
    logic                      tx_write_next     ;
    logic                      tx_read_next      ;
    logic [TX_BURST_WIDTH-1:0] tx_burstcount_next;
    logic [TX_ADDR_WIDTH-1:0]  tx_address_next   ;

    assign dma_task_decoder = {{64{1'b0}}, {6{1'b0}}, {DMA_BURST_WIDTH{1'b0}}, {DMA_BURST_WIDTH{1'b0}}, dma_task_data_i};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;

            dma_descriptor <= '0;

            tx_chipselect <= '0;
            tx_writedata  <= '0;
            tx_write      <= '0;
            tx_read       <= '0;
            tx_burstcount <= '0;
            tx_address    <= '0;
        end
        else begin
            state <= state_next;

            dma_descriptor <= dma_descriptor_next;

            tx_chipselect <= tx_chipselect_next;
            tx_writedata  <= tx_writedata_next ;
            tx_write      <= tx_write_next     ;
            tx_read       <= tx_read_next      ;
            tx_burstcount <= tx_burstcount_next;
            tx_address    <= tx_address_next   ;
        end
    end

    always_comb begin
        state_next = state;

        case (state)
            IDLE    : begin
                if (dma_task_valid_i && dma_task_ready_o) begin
                    if (dma_task_decoder.write) begin
                        state_next = WRITE;
                    end
                    else if (!dma_task_decoder.write) begin
                        state_next = READ;
                    end
                    else begin
                        state_next = state;
                    end
                end
                else begin
                    state_next = state;
                end
            end
            WRITE   : begin
                if (tx_chipselect && tx_write && !tx_waitrequest && dma_descriptor.bursts_left == 1) begin
                    state_next = GEN_MSI;
                end
                else begin
                    state_next = state;
                end
            end
            READ    : begin
                if (tx_chipselect && tx_readdatavalid && dma_descriptor.reads_left == 1) begin
                    state_next = GEN_MSI;
                end
                else begin
                    state_next = state;
                end
            end
            GEN_MSI : begin
                if (tx_chipselect && tx_write && !tx_waitrequest) begin
                    state_next = WAIT_MSI;
                end
                else begin
                    state_next = state;
                end
            end
            WAIT_MSI: begin
                if (!pba_status_i || msix_mask_i[0]) begin
                    state_next = IDLE;
                end
                else begin
                    state_next = state;
                end
            end
            default: begin
                
            end
        endcase
    end

    always_comb begin
        dma_task_ready_o = '0;

        dma_wrdata_ready_o = '0;
        dma_rddata_valid_o = '0;
        dma_rddata_data_o  = '0;

        pba_control_o = '0;

        dma_descriptor_next = dma_descriptor;

        tx_chipselect_next = tx_chipselect;
        tx_writedata_next  = tx_writedata ;
        tx_write_next      = tx_write     ;
        tx_read_next       = tx_read      ;
        tx_burstcount_next = tx_burstcount;
        tx_address_next    = tx_address   ;

        case (state)
            IDLE    : begin
                if (dma_task_valid_i) begin
                    if (dma_task_decoder.write && (dma_task_decoder.burstcount <= dma_wrdata_count_i)) begin
                        dma_task_ready_o = '1;
                    end
                    else if (!dma_task_decoder.write && (dma_task_decoder.burstcount <= dma_rddata_free_i)) begin
                        dma_task_ready_o = '1;
                    end
                    else begin
                        dma_task_ready_o = '0;
                    end
                end
                else begin
                    dma_task_ready_o = '0;
                end

                if (dma_task_valid_i && dma_task_ready_o) begin
                    dma_descriptor_next.burstcount  = dma_task_decoder.burstcount;
                    dma_descriptor_next.offset      = dma_task_decoder.offset    ;
                    dma_descriptor_next.write       = dma_task_decoder.write     ;

                    dma_descriptor_next.curr_burst  = (dma_task_decoder.burstcount > {TX_BURST_WIDTH{1'b1}}) ? {TX_BURST_WIDTH{1'b1}} : dma_task_decoder.burstcount;
                    dma_descriptor_next.curr_addr   = dma_addr_i + dma_task_decoder.offset;
                    dma_descriptor_next.bursts_left = dma_task_decoder.burstcount;
                    if (!dma_descriptor_next.write) begin
                        dma_descriptor_next.reads_left = dma_task_decoder.burstcount;
                    end
                    else begin
                        dma_descriptor_next.reads_left = '0;
                    end

                    tx_chipselect_next = '1                            ;
                    tx_writedata_next  = dma_wrdata_data_i             ;
                    tx_write_next      = dma_descriptor_next.write     ;
                    tx_read_next       = !dma_descriptor_next.write    ;
                    tx_burstcount_next = dma_descriptor_next.curr_burst;
                    tx_address_next    = dma_descriptor_next.curr_addr ;

                    dma_wrdata_ready_o = dma_descriptor_next.write     ;
                end
            end
            WRITE   : begin
                if (tx_chipselect && tx_write && !tx_waitrequest) begin
                    dma_descriptor_next.curr_addr   = dma_descriptor.curr_addr + TX_DATA_BYTES;
                    dma_descriptor_next.bursts_left = dma_descriptor.bursts_left - 1;

                    if (dma_descriptor.curr_burst == 1) begin
                        dma_descriptor_next.curr_burst = ((dma_descriptor.bursts_left - 1) > {TX_BURST_WIDTH{1'b1}}) ?
                                                            {TX_BURST_WIDTH{1'b1}} : dma_descriptor.bursts_left - 1;
                    end
                    else begin
                        dma_descriptor_next.curr_burst = dma_descriptor.curr_burst - 1;
                    end

                    if (dma_descriptor.bursts_left == 1) begin
                        tx_chipselect_next = '0                            ;
                        tx_write_next      = '0                            ;
                        tx_read_next       = '0                            ;
                    end
                    else begin
                        tx_chipselect_next = '1                            ;
                        tx_writedata_next  = dma_wrdata_data_i             ;
                        tx_write_next      = '1                            ;
                        tx_read_next       = '0                            ;
                        tx_burstcount_next = dma_descriptor_next.curr_burst;
                        tx_address_next    = dma_descriptor_next.curr_addr ;

                        dma_wrdata_ready_o = '1                            ;
                    end
                end
            end
            READ    : begin
                if (tx_chipselect && tx_read && !tx_waitrequest) begin
                    dma_descriptor_next.curr_addr   = dma_descriptor.curr_addr + (dma_descriptor.curr_burst << TX_DATA_BYTES_WIDTH);
                    dma_descriptor_next.bursts_left = dma_descriptor.bursts_left - dma_descriptor.curr_burst;
                    dma_descriptor_next.curr_burst  = ((dma_descriptor.bursts_left - dma_descriptor.curr_burst) > {TX_BURST_WIDTH{1'b1}}) ?
                                                        {TX_BURST_WIDTH{1'b1}} : dma_descriptor.bursts_left - dma_descriptor.curr_burst;

                    if (dma_descriptor.bursts_left == dma_descriptor.curr_burst) begin
                        tx_write_next      = '0                            ;
                        tx_read_next       = '0                            ;
                    end
                    else begin
                        tx_write_next      = '0                            ;
                        tx_read_next       = '1                            ;
                        tx_burstcount_next = dma_descriptor_next.curr_burst;
                        tx_address_next    = dma_descriptor_next.curr_addr ;
                    end
                end

                if (tx_chipselect && tx_readdatavalid && dma_descriptor.reads_left == 1) begin
                    tx_chipselect_next = '0;
                end
                else begin
                    tx_chipselect_next = '1;
                end
    
                dma_rddata_valid_o = tx_chipselect & tx_readdatavalid;
                dma_rddata_data_o  = tx_readdata;

                dma_descriptor_next.reads_left = dma_descriptor.reads_left - dma_rddata_valid_o;
            end
            GEN_MSI : begin
                if (tx_chipselect_next == 0) begin
                    pba_control_o = '1;
                end
                else begin
                    pba_control_o = '0;
                end

                tx_chipselect_next = '1         ;
                tx_writedata_next  = msix_data_i;
                tx_write_next      = '1         ;
                tx_read_next       = '0         ;
                tx_burstcount_next = 1          ;
                tx_address_next    = msix_addr_i;

                if (tx_chipselect && tx_write && !tx_waitrequest) begin
                    tx_chipselect_next = '0;
                    tx_write_next      = '0;
                    tx_read_next       = '0;
                end
            end
            WAIT_MSI: begin
            end
            default: begin
            end
        endcase
    end

endmodule