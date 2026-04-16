module tb_dma;

parameter DMA_CH_COUNT   = 16;

parameter DMA_TQ_DEPTH   = 16;

parameter DMA_WQ_DEPTH   = 1024;
parameter DMA_RQ_DEPTH   = 1024;

parameter BAR_DATA_WIDTH = 128;
parameter BAR_ADDR_WIDTH = 64;

parameter CRA_DATA_WIDTH = 32;
parameter CRA_ADDR_WIDTH = 14;

parameter TX_DATA_WIDTH  = 128;
parameter TX_ADDR_WIDTH  = 64;
parameter TX_BURST_WIDTH = 6;

parameter BAR_DATA_BYTES    = BAR_DATA_WIDTH / 8;
parameter CRA_DATA_BYTES    = CRA_DATA_WIDTH / 8;
parameter TX_DATA_BYTES     = TX_DATA_WIDTH / 8;
parameter DMA_WQ_ADDR_WIDTH = $clog2(DMA_WQ_DEPTH);
parameter DMA_RQ_ADDR_WIDTH = $clog2(DMA_RQ_DEPTH);

logic test_done;

logic clk, rst_n;

logic         bar_chipselect   ;
logic [15:0]  bar_byteenable   ;
logic [127:0] bar_readdata     ;
logic [127:0] bar_writedata    ;
logic         bar_read         ;
logic         bar_write        ;
logic         bar_readdatavalid;
logic         bar_waitrequest  ;
logic [11:0]  bar_address      ;

logic         bar_0_chipselect   ;
logic [15:0]  bar_0_byteenable   ;
logic [127:0] bar_0_readdata     ;
logic [127:0] bar_0_writedata    ;
logic         bar_0_read         ;
logic         bar_0_write        ;
logic         bar_0_readdatavalid;
logic         bar_0_waitrequest  ;
logic [11:0]  bar_0_address      ;


logic         tx_chipselect   ;
logic [15:0]  tx_byteenable   ;
logic [127:0] tx_readdata     ;
logic [127:0] tx_writedata    ;
logic         tx_read         ;
logic         tx_write        ;
logic [5:0]   tx_burstcount   ;
logic         tx_readdatavalid;
logic         tx_waitrequest  ;
logic [127:0] tx_address      ;

logic [31:0]  msix_mask   [16];
logic [31:0]  msix_data   [16];
logic [63:0]  msix_addrs  [16];
logic [127:0] pba_control [1];
logic [127:0] pba_status  [1];

avmm_dma_msix_table #(
    .BAR_DATA_WIDTH (128 ),
    .BAR_ADDR_WIDTH (12  ),
    .MSI_COUNT      (16  ) 
) u_avmm_dma_msix_table (
    .clk                  (clk                ),
    .rst_n                (rst_n              ),

    .avmm_s_chipselect    (bar_chipselect   ),
    .avmm_s_byteenable    (bar_byteenable   ),
    .avmm_s_readdata      (bar_readdata     ),
    .avmm_s_writedata     (bar_writedata    ),
    .avmm_s_read          (bar_read         ),
    .avmm_s_write         (bar_write        ),
    .avmm_s_readdatavalid (bar_readdatavalid),
    .avmm_s_waitrequest   (bar_waitrequest  ),
    .avmm_s_address       (bar_address      ),

    .msix_mask_o          (msix_mask          ),
    .msix_data_o          (msix_data          ),
    .msix_addrs_o         (msix_addrs         ),
    .pba_control_i        (pba_control        ),
    .pba_status_o         (pba_status         )
);

avmm_msix_tester #(
    .TX_DATA_WIDTH  (128 ),
    .TX_ADDR_WIDTH  (64  ),
    .TX_BURST_WIDTH (6   ),

    .BAR_DATA_WIDTH (128 ),
    .BAR_ADDR_WIDTH (12  ),

    .MSI_COUNT      (16  )
) u_avmm_msix_tester (
    .clk              (clk),
    .rst_n            (rst_n),

    .msix_mask_i      (msix_mask  ),
    .msix_data_i      (msix_data  ),
    .msix_addrs_i     (msix_addrs ),
    .pba_control_o    (pba_control),
    .pba_status_i     (pba_status ),

    .bar_chipselect   (bar_0_chipselect   ),
    .bar_byteenable   (bar_0_byteenable   ),
    .bar_readdata     (bar_0_readdata     ),
    .bar_writedata    (bar_0_writedata    ),
    .bar_read         (bar_0_read         ),
    .bar_write        (bar_0_write        ),
    .bar_readdatavalid(bar_0_readdatavalid),
    .bar_waitrequest  (bar_0_waitrequest  ),
    .bar_address      (bar_0_address      ),

    .tx_chipselect    (tx_chipselect    ),
    .tx_byteenable    (tx_byteenable    ),
    .tx_readdata      (tx_readdata      ),
    .tx_writedata     (tx_writedata     ),
    .tx_read          (tx_read          ),
    .tx_write         (tx_write         ),
    .tx_burstcount    (tx_burstcount    ),
    .tx_readdatavalid (tx_readdatavalid ),
    .tx_waitrequest   (tx_waitrequest   ),
    .tx_address       (tx_address       )
);


always #10 clk = ~clk;

initial begin

    test_done = '0;

    bar_chipselect = '0;
    bar_byteenable = '0;
    bar_writedata = '0;
    bar_read = '0;
    bar_write = '0;
    bar_address = '0;

    bar_0_chipselect = '0;
    bar_0_byteenable = '0;
    bar_0_writedata = '0;
    bar_0_read = '0;
    bar_0_write = '0;
    bar_0_address = '0;

    tx_waitrequest = '1;

    rst_n = '0;
    clk = '1;
    #25;
    rst_n = '1;

    @(posedge clk);
    @(posedge clk);

    for (int i = 0; i < DMA_CH_COUNT+1; i++) begin
        for (int j = 0; j < 4; j++) begin
            @(posedge clk);
            bar_write             = '0;
            @(posedge clk);
            bar_address           = i*16;
            bar_byteenable        = 'hF << j*4;
            bar_chipselect        = '1;
            bar_write             = '1;
            bar_writedata[127:96] = $urandom();
            bar_writedata[95:64]  = $urandom();
            bar_writedata[63:32]  = $urandom();
            bar_writedata[31:0]   = $urandom();
        end
    end

    bar_write = '0;
    for (int i = 0; i < DMA_CH_COUNT+1; i++) begin
        for (int j = 0; j < 4; j++) begin
            @(posedge clk);
            bar_read       = '0;
            @(posedge clk);
            bar_address    = i*16;
            bar_byteenable = 'hF << j*4;
            bar_chipselect = '1;
            bar_read       = '1;
        end
    end

    @(posedge clk);
    @(posedge clk);
    for (int i = 0; i < DMA_CH_COUNT; i++) begin
        @(posedge clk);
        bar_0_write             = '0;
        @(posedge clk);
        bar_0_address           = '0;
        bar_0_byteenable        = '1;
        bar_0_chipselect        = '1;
        bar_0_write             = '1;
        bar_0_writedata         = i;
    end

    tx_waitrequest = '0;

    repeat (100) @(posedge clk);
    
    test_done = '1;

end


endmodule