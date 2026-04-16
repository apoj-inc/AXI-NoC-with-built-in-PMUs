module tb_dma_engine;

parameter DMA_OFFFSET_WIDTH = 22  ;
parameter DMA_BYTES_WIDTH   = 22  ;

parameter DMA_WQ_DEPTH      = 1024;
parameter DMA_RQ_DEPTH      = 1024;

parameter TX_DATA_WIDTH     = 128 ;
parameter TX_ADDR_WIDTH     = 64  ;
parameter TX_BURST_WIDTH    = 6   ;

parameter DMA_BURST_WIDTH     = DMA_BYTES_WIDTH - 4                    ;
parameter DMA_TASK_WIDTH      = 1 + DMA_OFFFSET_WIDTH + DMA_BURST_WIDTH;

parameter TX_DATA_BYTES       = TX_DATA_WIDTH / 8                      ;
parameter TX_DATA_BYTES_WIDTH = $clog2(TX_DATA_BYTES)                  ;
parameter DMA_WQ_ADDR_WIDTH   = $clog2(DMA_WQ_DEPTH)                   ;
parameter DMA_RQ_ADDR_WIDTH   = $clog2(DMA_RQ_DEPTH)                   ;

logic                       test_done         ;

logic                       clk               ;
logic                       rst_n             ;

logic                       pba_status_i      ;
logic                       pba_control_o     ;

logic                       dma_task_valid_i  ;
logic                       dma_task_ready_o  ;
logic [DMA_TASK_WIDTH-1:0]  dma_task_data_i   ;

logic                       dma_wrdata_ready_o;
logic [TX_DATA_WIDTH-1:0]   dma_wrdata_data_i ;

logic                       dma_rddata_valid_o;
logic [TX_DATA_WIDTH-1:0]   dma_rddata_data_o ;

logic                       tx_chipselect     ;
logic [TX_DATA_BYTES-1:0]   tx_byteenable     ;
logic [TX_DATA_WIDTH-1:0]   tx_readdata       ;
logic [TX_DATA_WIDTH-1:0]   tx_writedata      ;
logic                       tx_read           ;
logic                       tx_write          ;
logic [TX_BURST_WIDTH-1:0]  tx_burstcount     ;
logic                       tx_readdatavalid  ;
logic                       tx_waitrequest    ;
logic [TX_ADDR_WIDTH-1:0]   tx_address        ;


logic        pba_release    ;
logic [31:0] reads_pipelined;
logic        rdvalid_gate   ;

avmm_dma_engine #(
    .DMA_OFFFSET_WIDTH (DMA_OFFFSET_WIDTH ),
    .DMA_BYTES_WIDTH   (DMA_BYTES_WIDTH   ),

    .DMA_WQ_DEPTH      (DMA_WQ_DEPTH      ),
    .DMA_RQ_DEPTH      (DMA_RQ_DEPTH      ),

    .TX_DATA_WIDTH     (TX_DATA_WIDTH     ),
    .TX_ADDR_WIDTH     (TX_ADDR_WIDTH     ),
    .TX_BURST_WIDTH    (TX_BURST_WIDTH    )
) u_avmm_dma_engine (
    .clk                (clk                ),
    .rst_n              (rst_n              ),

    .msix_mask_i        ('0                 ),
    .msix_data_i        (32'hDEADBEEF       ),
    .msix_addr_i        (64'h20202020       ),

    .pba_status_i       (pba_status_i       ),
    .pba_control_o      (pba_control_o      ),

    .dma_addr_i         (64'h10101010       ),

    .dma_task_valid_i   (dma_task_valid_i   ),
    .dma_task_ready_o   (dma_task_ready_o   ),
    .dma_task_data_i    (dma_task_data_i    ),

    .dma_wrdata_valid_i ('1                 ),
    .dma_wrdata_ready_o (dma_wrdata_ready_o ),
    .dma_wrdata_count_i (11'd1000           ),
    .dma_wrdata_data_i  (dma_wrdata_data_i  ),

    .dma_rddata_valid_o (dma_rddata_valid_o ),
    .dma_rddata_ready_i ('1                 ),
    .dma_rddata_free_i  (11'd1000           ),
    .dma_rddata_data_o  (dma_rddata_data_o  ),

    .tx_chipselect      (tx_chipselect      ),
    .tx_byteenable      (tx_byteenable      ),
    .tx_readdata        (tx_readdata        ),
    .tx_writedata       (tx_writedata       ),
    .tx_read            (tx_read            ),
    .tx_write           (tx_write           ),
    .tx_burstcount      (tx_burstcount      ),
    .tx_readdatavalid   (tx_readdatavalid   ),
    .tx_waitrequest     (tx_waitrequest     ),
    .tx_address         (tx_address         )
);


always #10 clk = ~clk;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pba_status_i <= '0;
    end
    else begin
        if (pba_control_o) begin
            pba_status_i <= '1;
        end
        else if (pba_release) begin
            pba_status_i <= '0;
        end
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_waitrequest <= '1;
        dma_wrdata_data_i <= '0;
        tx_readdata <= '0;
    end
    else begin
        tx_waitrequest <= $urandom();
        if (dma_wrdata_ready_o) begin
            std::randomize(dma_wrdata_data_i);
        end
        if (tx_readdatavalid) begin
            std::randomize(tx_readdata);
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reads_pipelined <= '0;
    end
    else begin
        if (tx_chipselect && tx_read && !tx_waitrequest) begin
            reads_pipelined <= reads_pipelined + tx_burstcount - tx_readdatavalid;
        end
        else if (tx_readdatavalid) begin
            reads_pipelined <= reads_pipelined - 1;
        end
    end
end

assign tx_readdatavalid = (reads_pipelined != 0) & rdvalid_gate;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdvalid_gate <= '0;
    end
    else begin
        rdvalid_gate <= $urandom();
    end
end

initial begin
    test_done = '0;

    clk = '1;
    rst_n = '0;
    dma_task_valid_i = '0;
    dma_task_data_i = '0;
    pba_release = '0;

    #15;
    rst_n = '1;

    // Short write
    @(posedge clk);
    dma_task_valid_i = '1;
    dma_task_data_i = {(DMA_BURST_WIDTH)'('h10), (DMA_OFFFSET_WIDTH)'('h200), 1'b1};
    @(posedge clk);
    dma_task_valid_i = '0;

    while (pba_control_o == 0) begin
        @(posedge clk);
    end
    pba_release = '1;
    @(posedge clk);
    pba_release = '0;
    @(posedge clk);

    // Short read
    @(posedge clk);
    dma_task_valid_i = '1;
    dma_task_data_i = {(DMA_BURST_WIDTH)'('h10), (DMA_OFFFSET_WIDTH)'('h200), 1'b0};
    @(posedge clk);
    dma_task_valid_i = '0;

    while (pba_control_o == 0) begin
        @(posedge clk);
    end
    pba_release = '1;
    @(posedge clk);
    pba_release = '0;
    @(posedge clk);

    

    // Long write
    @(posedge clk);
    dma_task_valid_i = '1;
    dma_task_data_i = {(DMA_BURST_WIDTH)'('hFF), (DMA_OFFFSET_WIDTH)'('h200), 1'b1};
    @(posedge clk);
    dma_task_valid_i = '0;

    while (pba_control_o == 0) begin
        @(posedge clk);
    end
    pba_release = '1;
    @(posedge clk);
    pba_release = '0;
    @(posedge clk);

    // Long read
    @(posedge clk);
    dma_task_valid_i = '1;
    dma_task_data_i = {(DMA_BURST_WIDTH)'('hFF), (DMA_OFFFSET_WIDTH)'('h200), 1'b0};
    @(posedge clk);
    dma_task_valid_i = '0;

    while (pba_control_o == 0) begin
        @(posedge clk);
    end
    pba_release = '1;
    @(posedge clk);
    pba_release = '0;
    @(posedge clk);
    
    test_done = '1;

end

endmodule