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


logic                         clk               ;
logic                         rst_n             ;

logic                         dma_task_valid_i  ;
logic                         dma_task_ready_o  ;
logic [DMA_BURST_WIDTH-1:0]   dma_task_burst_i  ;
logic [DMA_OFFFSET_WIDTH-1:0] dma_task_offset_i ;
logic                         dma_task_write_i  ;

logic                         dma_wrdata_valid_i;
logic                         dma_wrdata_ready_o;
logic [DMA_WQ_ADDR_WIDTH:0]   dma_wrdata_count_i;
logic [TX_DATA_WIDTH-1:0]     dma_wrdata_data_i ;

logic                         dma_rddata_valid_o;
logic                         dma_rddata_ready_i;
logic [DMA_RQ_ADDR_WIDTH:0]   dma_rddata_free_i ;
logic [TX_DATA_WIDTH-1:0]     dma_rddata_data_o ;

logic                         tx_chipselect     ;
logic [TX_DATA_BYTES-1:0]     tx_byteenable     ;
logic [TX_DATA_WIDTH-1:0]     tx_readdata       ;
logic [TX_DATA_WIDTH-1:0]     tx_writedata      ;
logic                         tx_read           ;
logic                         tx_write          ;
logic [TX_BURST_WIDTH-1:0]    tx_burstcount     ;
logic                         tx_readdatavalid  ;
logic                         tx_waitrequest    ;
logic [TX_ADDR_WIDTH-1:0]     tx_address        ;


logic test_done;

logic [TX_DATA_WIDTH-1:0] fifo_data;
logic [TX_DATA_WIDTH-1:0] tx_data  ;
logic [31:0]              iter     ;

logic [31:0] reads_pipelined;
logic        rdvalid_gate   ;

logic [TX_DATA_WIDTH-1:0] dma_fifo_write [$];
logic [TX_DATA_WIDTH-1:0] dma_fifo_read  [$];

logic [TX_DATA_WIDTH-1:0] dma_tx_write [$];
logic [TX_DATA_WIDTH-1:0] dma_tx_read  [$];

always_ff @(posedge clk) begin
    if (dma_wrdata_valid_i && dma_wrdata_ready_o) begin
        dma_fifo_write.push_back(dma_wrdata_data_i);
    end
    if (dma_rddata_valid_o && dma_rddata_ready_i) begin
        dma_fifo_read.push_back(dma_rddata_data_o);
    end

    
    if (tx_write && !tx_waitrequest) begin
        if (!(tx_address == 'h20202020 && tx_writedata == 'hDEADBEEF)) begin
            dma_tx_write.push_back(tx_writedata);
        end
    end
    if (tx_readdatavalid) begin
        dma_tx_read.push_back(tx_readdata);
    end
end

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

    .dma_addr_i         (64'h10101010       ),

    .dma_task_valid_i   (dma_task_valid_i   ),
    .dma_task_ready_o   (dma_task_ready_o   ),
    .dma_task_burst_i   (dma_task_burst_i   ),
    .dma_task_offset_i  (dma_task_offset_i  ),
    .dma_task_write_i   (dma_task_write_i   ),

    .dma_wrdata_valid_i (dma_wrdata_valid_i ),
    .dma_wrdata_ready_o (dma_wrdata_ready_o ),
    .dma_wrdata_count_i (dma_wrdata_count_i ),
    .dma_wrdata_data_i  (dma_wrdata_data_i  ),

    .dma_rddata_valid_o (dma_rddata_valid_o ),
    .dma_rddata_ready_i (dma_rddata_ready_i ),
    .dma_rddata_free_i  (dma_rddata_free_i  ),
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

typedef enum logic [2:0] {
    IDLE    ,
    READ    ,
    WRITE   ,
    GEN_MSI ,
    WAIT_MSI
} state_t;

always #10 clk = ~clk;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_waitrequest <= '1;
        dma_wrdata_data_i <= '0;
        tx_readdata <= '0;
    end
    else begin
        tx_waitrequest <= $urandom();
        if (dma_wrdata_valid_i && dma_wrdata_ready_o) begin
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

    dma_wrdata_valid_i = '0;
    dma_wrdata_count_i = '0;

    dma_rddata_ready_i = '0;
    dma_rddata_free_i = '0;

    {dma_task_burst_i, dma_task_offset_i, dma_task_write_i} = '0;

    #15;
    rst_n = '1;

    // Short write
    @(posedge clk);
    dma_task_valid_i = '1;
    {dma_task_burst_i, dma_task_offset_i, dma_task_write_i} = {(DMA_BURST_WIDTH)'('h10), (DMA_OFFFSET_WIDTH)'('h200), 1'b1};
    @(posedge clk);
    while (!dma_task_ready_o) begin
        @(posedge clk);
    end
    dma_task_valid_i = '0;

    while (u_avmm_dma_engine.state != WRITE) begin
        @(posedge clk);
    end

    // Validate count condition
    while (dma_wrdata_count_i != (DMA_BURST_WIDTH)'('h10)) begin
        repeat (5) @(posedge clk);
        assert (tx_chipselect == 0) 
        else   begin
            $error("Started DMA write but not enough FIFO entries: %d, but 16 needed", dma_wrdata_count_i);
            $finish();
        end
        dma_wrdata_count_i = dma_wrdata_count_i + 1;
        dma_wrdata_valid_i = '1;
    end


    // Short read
    dma_task_valid_i = '1;
    {dma_task_burst_i, dma_task_offset_i, dma_task_write_i} = {(DMA_BURST_WIDTH)'('h10), (DMA_OFFFSET_WIDTH)'('h200), 1'b0};
    @(posedge clk);
    while (!dma_task_ready_o) begin
        @(posedge clk);
    end
    dma_task_valid_i = '0;

    while (u_avmm_dma_engine.state != READ) begin
        @(posedge clk);
    end

    // Validate count condition
    while (dma_rddata_free_i != (DMA_BURST_WIDTH)'('h10)) begin
        repeat (5) @(posedge clk);
        assert (tx_chipselect == 0) 
        else   begin
            $error("Started DMA read but not enough FIFO free spaces: %d, but 16 needed", dma_rddata_free_i);
            $finish();
        end
        dma_rddata_free_i  = dma_rddata_free_i + 1;
        dma_rddata_ready_i = '1;
    end


    // Long write
    dma_task_valid_i = '1;
    {dma_task_burst_i, dma_task_offset_i, dma_task_write_i} = {(DMA_BURST_WIDTH)'('hFF), (DMA_OFFFSET_WIDTH)'('h200), 1'b1};
    @(posedge clk);
    while (!dma_task_ready_o) begin
        @(posedge clk);
    end
    dma_task_valid_i = '0;

    while (u_avmm_dma_engine.state != WRITE) begin
        @(posedge clk);
    end

    // Validate count condition
    while (dma_wrdata_count_i != 6'h3F) begin
        repeat (5) @(posedge clk);
        assert (tx_chipselect == 0) 
        else   begin
            $error("Started DMA write but not enough FIFO entries: %d, but 63 needed", dma_wrdata_count_i);
            $finish();
        end
        dma_wrdata_count_i = dma_wrdata_count_i + 1;
        dma_wrdata_valid_i = '1;
    end

    // Long read
    dma_task_valid_i = '1;
    {dma_task_burst_i, dma_task_offset_i, dma_task_write_i} = {(DMA_BURST_WIDTH)'('hFF), (DMA_OFFFSET_WIDTH)'('h200), 1'b0};
    @(posedge clk);
    while (!dma_task_ready_o) begin
        @(posedge clk);
    end
    dma_task_valid_i = '0;

    while (u_avmm_dma_engine.state != READ) begin
        @(posedge clk);
    end

    // Validate count condition
    while (dma_rddata_free_i != 6'h3F) begin
        repeat (5) @(posedge clk);
        assert (tx_chipselect == 0) 
        else   begin
            $error("Started DMA read but not enough FIFO free spaces: %d, but 63 needed", dma_rddata_free_i);
            $finish();
        end
        dma_rddata_free_i  = dma_rddata_free_i + 1;
        dma_rddata_ready_i = '1;
    end

    while (!(tx_chipselect && !tx_waitrequest && tx_write && (tx_writedata == 32'hDEADBEEF) && (tx_address == 64'h20202020))) begin
        @(posedge clk);
    end

    // Validate contents
    
    iter = 0;
    assert (dma_fifo_write.size() == dma_tx_write.size()) 
    else   begin
        $error("Mismatched write sizes: %d dma_fifo, %d dma_tx", dma_fifo_write.size(), dma_tx_write.size());
        $finish();
    end

    while (dma_fifo_write.size()) begin
        fifo_data = dma_fifo_write.pop_front();
        tx_data   = dma_tx_write.pop_front();

        assert (fifo_data == tx_data) 
        else   begin
            $error("Erroneous write data: iter %d, %x dma_fifo, %x dma_tx", iter, fifo_data, tx_data);
            $finish();
        end
        iter = iter + 1;
    end


    iter = 0;
    assert (dma_fifo_read.size() == dma_tx_read.size()) 
    else   begin
        $error("Mismatched read sizes: %d dma_fifo, %d dma_tx", iter, dma_fifo_read.size(), dma_tx_read.size());
        $finish();
    end

    while (dma_fifo_read.size()) begin
        fifo_data = dma_fifo_read.pop_front();
        tx_data   = dma_tx_read.pop_front();

        assert (fifo_data == tx_data) 
        else   begin
            $error("Erroneous read data: iter %d, %x dma_fifo, %x dma_tx", iter, fifo_data, tx_data);
            $finish();
        end
        iter = iter + 1;
    end
    
    test_done = '1;

end

endmodule