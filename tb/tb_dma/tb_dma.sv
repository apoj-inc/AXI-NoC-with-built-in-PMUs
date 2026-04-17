module tb_dma;


parameter     DMA_CHANNEL_COUNT                     = 16         ;

parameter     DMA_BYTES_WIDTH                       = 22         ;
parameter     DMA_OFFFSET_WIDTH                     = 22         ;

parameter int DMA_WORD_BYTES    [DMA_CHANNEL_COUNT] = '{16{16  }};
parameter int DMA_WQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{1024}};
parameter int DMA_RQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{1024}};
parameter int DMA_TQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{16  }};

parameter int MAX_WQ_DEPTH                          = 1024       ;
parameter int MAX_RQ_DEPTH                          = 1024       ;
parameter int MAX_TQ_DEPTH                          = 16         ;

parameter     BAR_DATA_WIDTH                        = 128        ;
parameter     BAR_ADDR_WIDTH                        = 12         ;

parameter     TX_DATA_WIDTH                         = 128        ;
parameter     TX_ADDR_WIDTH                         = 12         ;
parameter     TX_BURST_WIDTH                        = 6          ;

parameter MSI_COUNT               = DMA_CHANNEL_COUNT                     ;
parameter BAR_DATA_BYTES          = BAR_DATA_WIDTH / 8                    ;
parameter TX_DATA_BYTES           = TX_DATA_WIDTH / 8                     ;
parameter DMA_WQ_ADDR_WIDTH       = $clog2(MAX_WQ_DEPTH)                  ;
parameter DMA_RQ_ADDR_WIDTH       = $clog2(MAX_RQ_DEPTH)                  ;
parameter DMA_TQ_ADDR_WIDTH       = $clog2(MAX_TQ_DEPTH)                  ;
parameter PBA_COUNT               = MSI_COUNT / 64 + (MSI_COUNT % 64 != 0);
parameter DMA_BURST_WIDTH         = DMA_BYTES_WIDTH - 4                   ;
parameter DMA_CHANNEL_COUNT_WIDTH = $clog2(DMA_CHANNEL_COUNT)             ;

logic                       clk                                     ;
logic                       rst_n                                   ;

logic                       csr_s_chipselect                        ;
logic [BAR_DATA_BYTES-1:0]  csr_s_byteenable                        ;
logic [BAR_DATA_WIDTH-1:0]  csr_s_readdata                          ;
logic [BAR_DATA_WIDTH-1:0]  csr_s_writedata                         ;
logic                       csr_s_read                              ;
logic                       csr_s_write                             ;
logic                       csr_s_readdatavalid                     ;
logic                       csr_s_waitrequest                       ;
logic [BAR_ADDR_WIDTH-1:0]  csr_s_address                           ;

logic                       msix_s_chipselect                       ;
logic [BAR_DATA_BYTES-1:0]  msix_s_byteenable                       ;
logic [BAR_DATA_WIDTH-1:0]  msix_s_readdata                         ;
logic [BAR_DATA_WIDTH-1:0]  msix_s_writedata                        ;
logic                       msix_s_read                             ;
logic                       msix_s_write                            ;
logic                       msix_s_readdatavalid                    ;
logic                       msix_s_waitrequest                      ;
logic [BAR_ADDR_WIDTH-1:0]  msix_s_address                          ;

logic                       dec_s_chipselect                        ;
logic [BAR_DATA_BYTES-1:0]  dec_s_byteenable                        ;
logic [BAR_DATA_WIDTH-1:0]  dec_s_readdata                          ;
logic [BAR_DATA_WIDTH-1:0]  dec_s_writedata                         ;
logic                       dec_s_read                              ;
logic                       dec_s_write                             ;
logic                       dec_s_readdatavalid                     ;
logic                       dec_s_waitrequest                       ;
logic [BAR_ADDR_WIDTH-1:0]  dec_s_address                           ;

logic                       tx_chipselect        [DMA_CHANNEL_COUNT];
logic [TX_DATA_BYTES-1:0]   tx_byteenable        [DMA_CHANNEL_COUNT];
logic [TX_DATA_WIDTH-1:0]   tx_readdata          [DMA_CHANNEL_COUNT];
logic [TX_DATA_WIDTH-1:0]   tx_writedata         [DMA_CHANNEL_COUNT];
logic                       tx_read              [DMA_CHANNEL_COUNT];
logic                       tx_write             [DMA_CHANNEL_COUNT];
logic [TX_BURST_WIDTH-1:0]  tx_burstcount        [DMA_CHANNEL_COUNT];
logic                       tx_readdatavalid     [DMA_CHANNEL_COUNT];
logic                       tx_waitrequest       [DMA_CHANNEL_COUNT];
logic [TX_ADDR_WIDTH-1:0]   tx_address           [DMA_CHANNEL_COUNT];

logic                       dma_wrdata_valid_i   [DMA_CHANNEL_COUNT];
logic                       dma_wrdata_ready_o   [DMA_CHANNEL_COUNT];
logic [DMA_WQ_ADDR_WIDTH:0] dma_wrdata_count_i   [DMA_CHANNEL_COUNT];
logic [TX_DATA_WIDTH-1:0]   dma_wrdata_data_i    [DMA_CHANNEL_COUNT];

logic                       dma_rddata_valid_o   [DMA_CHANNEL_COUNT];
logic                       dma_rddata_ready_i   [DMA_CHANNEL_COUNT];
logic [DMA_RQ_ADDR_WIDTH:0] dma_rddata_free_i    [DMA_CHANNEL_COUNT];
logic [TX_DATA_WIDTH-1:0]   dma_rddata_data_o    [DMA_CHANNEL_COUNT];


avmm_dma_top #(
    .DMA_CHANNEL_COUNT (DMA_CHANNEL_COUNT ),

    .DMA_BYTES_WIDTH   (DMA_BYTES_WIDTH   ),
    .DMA_OFFFSET_WIDTH (DMA_OFFFSET_WIDTH ),

    .DMA_WORD_BYTES    (DMA_WORD_BYTES    ),
    .DMA_WQ_DEPTH      (DMA_WQ_DEPTH      ),
    .DMA_RQ_DEPTH      (DMA_RQ_DEPTH      ),
    .DMA_TQ_DEPTH      (DMA_TQ_DEPTH      ),

    .MAX_WQ_DEPTH      (MAX_WQ_DEPTH      ),
    .MAX_RQ_DEPTH      (MAX_RQ_DEPTH      ),
    .MAX_TQ_DEPTH      (MAX_TQ_DEPTH      ),

    .BAR_DATA_WIDTH    (BAR_DATA_WIDTH    ),
    .BAR_ADDR_WIDTH    (BAR_ADDR_WIDTH    ),

    .TX_DATA_WIDTH     (TX_DATA_WIDTH     ),
    .TX_ADDR_WIDTH     (TX_ADDR_WIDTH     ),
    .TX_BURST_WIDTH    (TX_BURST_WIDTH    )
) u_avmm_dma_top (
    .clk                  (clk                  ),
    .rst_n                (rst_n                ),

    .csr_s_chipselect     (csr_s_chipselect     ),
    .csr_s_byteenable     (csr_s_byteenable     ),
    .csr_s_readdata       (csr_s_readdata       ),
    .csr_s_writedata      (csr_s_writedata      ),
    .csr_s_read           (csr_s_read           ),
    .csr_s_write          (csr_s_write          ),
    .csr_s_readdatavalid  (csr_s_readdatavalid  ),
    .csr_s_waitrequest    (csr_s_waitrequest    ),
    .csr_s_address        (csr_s_address        ),

    .msix_s_chipselect    (msix_s_chipselect    ),
    .msix_s_byteenable    (msix_s_byteenable    ),
    .msix_s_readdata      (msix_s_readdata      ),
    .msix_s_writedata     (msix_s_writedata     ),
    .msix_s_read          (msix_s_read          ),
    .msix_s_write         (msix_s_write         ),
    .msix_s_readdatavalid (msix_s_readdatavalid ),
    .msix_s_waitrequest   (msix_s_waitrequest   ),
    .msix_s_address       (msix_s_address       ),

    .dec_s_chipselect     (dec_s_chipselect     ),
    .dec_s_byteenable     (dec_s_byteenable     ),
    .dec_s_readdata       (dec_s_readdata       ),
    .dec_s_writedata      (dec_s_writedata      ),
    .dec_s_read           (dec_s_read           ),
    .dec_s_write          (dec_s_write          ),
    .dec_s_readdatavalid  (dec_s_readdatavalid  ),
    .dec_s_waitrequest    (dec_s_waitrequest    ),
    .dec_s_address        (dec_s_address        ),

    .tx_chipselect        (tx_chipselect        ),
    .tx_byteenable        (tx_byteenable        ),
    .tx_readdata          (tx_readdata          ),
    .tx_writedata         (tx_writedata         ),
    .tx_read              (tx_read              ),
    .tx_write             (tx_write             ),
    .tx_burstcount        (tx_burstcount        ),
    .tx_readdatavalid     (tx_readdatavalid     ),
    .tx_waitrequest       (tx_waitrequest       ),
    .tx_address           (tx_address           ),

    .dma_wrdata_valid_i   (dma_wrdata_valid_i   ),
    .dma_wrdata_ready_o   (dma_wrdata_ready_o   ),
    .dma_wrdata_count_i   (dma_wrdata_count_i   ),
    .dma_wrdata_data_i    (dma_wrdata_data_i    ),

    .dma_rddata_valid_o   (dma_rddata_valid_o   ),
    .dma_rddata_ready_i   (dma_rddata_ready_i   ),
    .dma_rddata_free_i    (dma_rddata_free_i    ),
    .dma_rddata_data_o    (dma_rddata_data_o    )
);

endmodule