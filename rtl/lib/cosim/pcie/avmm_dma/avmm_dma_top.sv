module avmm_dma_top #(
    parameter     DMA_CHANNEL_COUNT                     = 16         ,
    
    parameter     DMA_BYTES_WIDTH                       = 22         ,
    parameter     DMA_OFFFSET_WIDTH                     = 22         ,

    parameter int DMA_WORD_BYTES    [DMA_CHANNEL_COUNT] = '{16{16  }},
    parameter int DMA_WQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{1024}},
    parameter int DMA_RQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{1024}},
    parameter int DMA_TQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{16  }},

    parameter int MAX_WQ_DEPTH                          = 1024       ,
    parameter int MAX_RQ_DEPTH                          = 1024       ,
    parameter int MAX_TQ_DEPTH                          = 16         ,
    
    parameter     BAR_DATA_WIDTH                        = 128        ,
    parameter     BAR_ADDR_WIDTH                        = 12         ,

    parameter     TX_DATA_WIDTH                         = 128        ,
    parameter     TX_ADDR_WIDTH                         = 12         ,
    parameter     TX_BURST_WIDTH                        = 6          ,

    parameter MSI_COUNT               = DMA_CHANNEL_COUNT                                     ,
    parameter BAR_DATA_BYTES          = BAR_DATA_WIDTH / 8                                    ,
    parameter TX_DATA_BYTES           = TX_DATA_WIDTH / 8                                     ,
    parameter DMA_WQ_ADDR_WIDTH       = $clog2(MAX_WQ_DEPTH)                                  ,
    parameter DMA_RQ_ADDR_WIDTH       = $clog2(MAX_RQ_DEPTH)                                  ,
    parameter DMA_TQ_ADDR_WIDTH       = $clog2(MAX_TQ_DEPTH)                                  ,
    parameter PBA_COUNT               = MSI_COUNT / 64 + (MSI_COUNT % 64 != 0)                ,
    parameter DMA_BURST_WIDTH         = DMA_BYTES_WIDTH - 4                                   ,
    parameter DMA_CHANNEL_COUNT_WIDTH = DMA_CHANNEL_COUNT == 1 ? 1 : $clog2(DMA_CHANNEL_COUNT)
) (
    input  logic                       clk                                     ,
    input  logic                       rst_n                                   ,

    // CSR AVMM bus
    input  logic                       csr_s_chipselect                        ,
    input  logic [BAR_DATA_BYTES-1:0]  csr_s_byteenable                        ,
    output logic [BAR_DATA_WIDTH-1:0]  csr_s_readdata                          ,
    input  logic [BAR_DATA_WIDTH-1:0]  csr_s_writedata                         ,
    input  logic                       csr_s_read                              ,
    input  logic                       csr_s_write                             ,
    output logic                       csr_s_readdatavalid                     ,
    output logic                       csr_s_waitrequest                       ,
    input  logic [BAR_ADDR_WIDTH-1:0]  csr_s_address                           ,

    // MSI-X AVMM bus
    input  logic                       msix_s_chipselect                       ,
    input  logic [BAR_DATA_BYTES-1:0]  msix_s_byteenable                       ,
    output logic [BAR_DATA_WIDTH-1:0]  msix_s_readdata                         ,
    input  logic [BAR_DATA_WIDTH-1:0]  msix_s_writedata                        ,
    input  logic                       msix_s_read                             ,
    input  logic                       msix_s_write                            ,
    output logic                       msix_s_readdatavalid                    ,
    output logic                       msix_s_waitrequest                      ,
    input  logic [BAR_ADDR_WIDTH-1:0]  msix_s_address                          ,

    // Decoder AVMM bus
    input  logic                       dec_s_chipselect                        ,
    input  logic [BAR_DATA_BYTES-1:0]  dec_s_byteenable                        ,
    output logic [BAR_DATA_WIDTH-1:0]  dec_s_readdata                          ,
    input  logic [BAR_DATA_WIDTH-1:0]  dec_s_writedata                         ,
    input  logic                       dec_s_read                              ,
    input  logic                       dec_s_write                             ,
    output logic                       dec_s_readdatavalid                     ,
    output logic                       dec_s_waitrequest                       ,
    input  logic [BAR_ADDR_WIDTH-1:0]  dec_s_address                           ,
    
    // TX AVMM buses
    output logic                       tx_chipselect        [DMA_CHANNEL_COUNT],
    output logic [TX_DATA_BYTES-1:0]   tx_byteenable        [DMA_CHANNEL_COUNT],
    input  logic [TX_DATA_WIDTH-1:0]   tx_readdata          [DMA_CHANNEL_COUNT],
    output logic [TX_DATA_WIDTH-1:0]   tx_writedata         [DMA_CHANNEL_COUNT],
    output logic                       tx_read              [DMA_CHANNEL_COUNT],
    output logic                       tx_write             [DMA_CHANNEL_COUNT],
    output logic [TX_BURST_WIDTH-1:0]  tx_burstcount        [DMA_CHANNEL_COUNT],
    input  logic                       tx_readdatavalid     [DMA_CHANNEL_COUNT],
    input  logic                       tx_waitrequest       [DMA_CHANNEL_COUNT],
    output logic [TX_ADDR_WIDTH-1:0]   tx_address           [DMA_CHANNEL_COUNT],

    // DMAWR FIFO
    input  logic                       dma_wrdata_valid_i   [DMA_CHANNEL_COUNT],
    output logic                       dma_wrdata_ready_o   [DMA_CHANNEL_COUNT],
    input  logic [DMA_WQ_ADDR_WIDTH:0] dma_wrdata_count_i   [DMA_CHANNEL_COUNT],
    input  logic [TX_DATA_WIDTH-1:0]   dma_wrdata_data_i    [DMA_CHANNEL_COUNT],

    // DMARD FIFO
    output logic                       dma_rddata_valid_o   [DMA_CHANNEL_COUNT],
    input  logic                       dma_rddata_ready_i   [DMA_CHANNEL_COUNT],
    input  logic [DMA_RQ_ADDR_WIDTH:0] dma_rddata_free_i    [DMA_CHANNEL_COUNT],
    output logic [TX_DATA_WIDTH-1:0]   dma_rddata_data_o    [DMA_CHANNEL_COUNT]
);

    logic [63:0] dma_addr [DMA_CHANNEL_COUNT];

    logic [31:0] msix_mask  [MSI_COUNT];
    logic [31:0] msix_data  [MSI_COUNT];
    logic [63:0] msix_addrs [MSI_COUNT];

    logic                               dma_task_valid_wr  , dma_task_valid_rd  ;
    logic                               dma_task_ready_wr  , dma_task_ready_rd  ;
    logic [DMA_CHANNEL_COUNT_WIDTH-1:0] dma_task_channel_wr, dma_task_channel_rd;
    logic [DMA_BURST_WIDTH-1:0]         dma_task_burst_wr  , dma_task_burst_rd  ;
    logic [DMA_OFFFSET_WIDTH-1:0]       dma_task_offset_wr , dma_task_offset_rd ;
    logic                               dma_task_write_wr  , dma_task_write_rd  ;

    logic [DMA_CHANNEL_COUNT-1:0] dma_task_valid_demuxed                     ;
    logic [DMA_CHANNEL_COUNT-1:0] dma_task_ready_demuxed                     ;
    logic [DMA_BURST_WIDTH-1:0]   dma_task_burst_demuxed  [DMA_CHANNEL_COUNT];
    logic [DMA_OFFFSET_WIDTH-1:0] dma_task_offset_demuxed [DMA_CHANNEL_COUNT];
    logic [DMA_CHANNEL_COUNT-1:0] dma_task_write_demuxed                     ;

    logic [DMA_TQ_ADDR_WIDTH:0] task_fifo_free;

    avmm_dma_csr #(
        .DMA_CHANNEL_COUNT (DMA_CHANNEL_COUNT),

        .BAR_DATA_WIDTH    (BAR_DATA_WIDTH   ),
        .BAR_ADDR_WIDTH    (BAR_ADDR_WIDTH   ),

        .DMA_WORD_BYTES    (DMA_WORD_BYTES   ),
        .DMA_WQ_DEPTH      (DMA_WQ_DEPTH     ),
        .DMA_RQ_DEPTH      (DMA_RQ_DEPTH     ),
        .DMA_TQ_DEPTH      (DMA_TQ_DEPTH     ),

        .MAX_WQ_DEPTH      (MAX_WQ_DEPTH     ),
        .MAX_RQ_DEPTH      (MAX_RQ_DEPTH     ),
        .MAX_TQ_DEPTH      (MAX_TQ_DEPTH     )
    ) u_avmm_dma_csr (
        .clk                  (clk                 ),
        .rst_n                (rst_n               ),

        .avmm_s_chipselect    (csr_s_chipselect    ),
        .avmm_s_byteenable    (csr_s_byteenable    ),
        .avmm_s_readdata      (csr_s_readdata      ),
        .avmm_s_writedata     (csr_s_writedata     ),
        .avmm_s_read          (csr_s_read          ),
        .avmm_s_write         (csr_s_write         ),
        .avmm_s_readdatavalid (csr_s_readdatavalid ),
        .avmm_s_waitrequest   (csr_s_waitrequest   ),
        .avmm_s_address       (csr_s_address       ),

        .dma_addr_o           (dma_addr            ),

        .wdata_fifo_count_i   (dma_wrdata_count_i  ),
        .rdata_fifo_free_i    (dma_rddata_free_i   ),
        .task_fifo_free_i     (task_fifo_free      )
    );

    avmm_dma_msix_table #(
        .BAR_DATA_WIDTH (BAR_DATA_WIDTH),
        .BAR_ADDR_WIDTH (BAR_ADDR_WIDTH),
        .MSI_COUNT      (MSI_COUNT     )
    ) u_avmm_dma_msix_table (
        .clk                  (clk                 ),
        .rst_n                (rst_n               ),

        .avmm_s_chipselect    (msix_s_chipselect   ),
        .avmm_s_byteenable    (msix_s_byteenable   ),
        .avmm_s_readdata      (msix_s_readdata     ),
        .avmm_s_writedata     (msix_s_writedata    ),
        .avmm_s_read          (msix_s_read         ),
        .avmm_s_write         (msix_s_write        ),
        .avmm_s_readdatavalid (msix_s_readdatavalid),
        .avmm_s_waitrequest   (msix_s_waitrequest  ),
        .avmm_s_address       (msix_s_address      ),

        .msix_mask_o          (msix_mask           ),
        .msix_data_o          (msix_data           ),
        .msix_addrs_o         (msix_addrs          ),

        .pba_control_i        ('{PBA_COUNT{'0}}    ),
        .pba_status_o         (                    ) // NC
    );

    avmm_dma_decoder #(
        .BAR_DATA_WIDTH    (BAR_DATA_WIDTH   ),
        .BAR_ADDR_WIDTH    (BAR_ADDR_WIDTH   ),

        .DMA_CHANNEL_COUNT (DMA_CHANNEL_COUNT),
        .DMA_OFFFSET_WIDTH (DMA_OFFFSET_WIDTH),
        .DMA_BYTES_WIDTH   (DMA_BYTES_WIDTH  ) 
    ) u_avmm_dma_decoder (
        .clk                  (clk                 ),
        .rst_n                (rst_n               ),

        .avmm_s_chipselect    (dec_s_chipselect    ),
        .avmm_s_byteenable    (dec_s_byteenable    ),
        .avmm_s_readdata      (dec_s_readdata      ),
        .avmm_s_writedata     (dec_s_writedata     ),
        .avmm_s_read          (dec_s_read          ),
        .avmm_s_write         (dec_s_write         ),
        .avmm_s_readdatavalid (dec_s_readdatavalid ),
        .avmm_s_waitrequest   (dec_s_waitrequest   ),
        .avmm_s_address       (dec_s_address       ),

        .dma_task_valid_o     (dma_task_valid_wr   ),
        .dma_task_ready_i     (dma_task_ready_wr   ),
        .dma_task_channel_o   (dma_task_channel_wr ),
        .dma_task_burst_o     (dma_task_burst_wr   ),
        .dma_task_offset_o    (dma_task_offset_wr  ),
        .dma_task_write_o     (dma_task_write_wr   )
    );

    stream_fifo #(
        .DATA_WIDTH (1 + DMA_CHANNEL_COUNT_WIDTH + DMA_BURST_WIDTH + DMA_OFFFSET_WIDTH),
        .FIFO_DEPTH (MAX_TQ_DEPTH)
    ) u_stream_fifo_tasks (
       .ACLK    (clk                                                                            ),
       .ARESETn (rst_n                                                                          ),

       .data_i  ({dma_task_write_wr, dma_task_channel_wr, dma_task_burst_wr, dma_task_offset_wr}),
       .valid_i (dma_task_valid_wr                                                              ),
       .ready_o (dma_task_ready_wr                                                              ),
       .free_o  (task_fifo_free                                                                 ),

       .data_o  ({dma_task_write_rd, dma_task_channel_rd, dma_task_burst_rd, dma_task_offset_rd}),
       .valid_o (dma_task_valid_rd                                                              ),
       .ready_i (dma_task_ready_rd                                                              ),
       .count_o (                                                                               ) // NC
    );

    avmm_dma_task_demux #(
       .DMA_CHANNEL_COUNT (DMA_CHANNEL_COUNT),
       .DMA_OFFFSET_WIDTH (DMA_OFFFSET_WIDTH),
       .DMA_BYTES_WIDTH   (DMA_BYTES_WIDTH  )
    ) u_avmm_dma_task_demux (
        .clk                   (clk                     ),
        .rst_n                 (rst_n                   ),

        .in_dma_task_valid_i   (dma_task_valid_rd       ),
        .in_dma_task_ready_o   (dma_task_ready_rd       ),
        .in_dma_task_channel_i (dma_task_channel_rd     ),
        .in_dma_task_burst_i   (dma_task_burst_rd       ),
        .in_dma_task_offset_i  (dma_task_offset_rd      ),
        .in_dma_task_write_i   (dma_task_write_rd       ),

        .out_dma_task_valid_o  (dma_task_valid_demuxed  ),
        .out_dma_task_ready_i  (dma_task_ready_demuxed  ),
        .out_dma_task_burst_o  (dma_task_burst_demuxed  ),
        .out_dma_task_offset_o (dma_task_offset_demuxed ),
        .out_dma_task_write_o  (dma_task_write_demuxed  )
    );

    generate
        genvar i;

        for (i = 0; i < DMA_CHANNEL_COUNT; i++) begin : dma_channels
            avmm_dma_engine #(
                .DMA_OFFFSET_WIDTH (DMA_OFFFSET_WIDTH),
                .DMA_BYTES_WIDTH   (DMA_BYTES_WIDTH  ),

                .DMA_WQ_DEPTH      (DMA_WQ_DEPTH[i]  ),
                .DMA_RQ_DEPTH      (DMA_RQ_DEPTH[i]  ),

                .TX_DATA_WIDTH     (TX_DATA_WIDTH    ),
                .TX_ADDR_WIDTH     (TX_ADDR_WIDTH    ),
                .TX_BURST_WIDTH    (TX_BURST_WIDTH   )
            ) u_avmm_dma_engine (
                .clk                (clk                       ),
                .rst_n              (rst_n                     ),

                .msix_mask_i        (msix_mask[i]              ),
                .msix_data_i        (msix_data[i]              ),
                .msix_addr_i        (msix_addrs[i]             ),

                .dma_addr_i         (dma_addr[i]               ),

                .dma_task_valid_i   (dma_task_valid_demuxed [i]),
                .dma_task_ready_o   (dma_task_ready_demuxed [i]),
                .dma_task_burst_i   (dma_task_burst_demuxed [i]),
                .dma_task_offset_i  (dma_task_offset_demuxed[i]),
                .dma_task_write_i   (dma_task_write_demuxed [i]),

                .dma_wrdata_valid_i (dma_wrdata_valid_i[i]     ),
                .dma_wrdata_ready_o (dma_wrdata_ready_o[i]     ),
                .dma_wrdata_count_i (dma_wrdata_count_i[i]     ),
                .dma_wrdata_data_i  (dma_wrdata_data_i [i]     ),

                .dma_rddata_valid_o (dma_rddata_valid_o[i]     ),
                .dma_rddata_ready_i (dma_rddata_ready_i[i]     ),
                .dma_rddata_free_i  (dma_rddata_free_i [i]     ),
                .dma_rddata_data_o  (dma_rddata_data_o [i]     ),

                .tx_chipselect      (tx_chipselect   [i]       ),
                .tx_byteenable      (tx_byteenable   [i]       ),
                .tx_readdata        (tx_readdata     [i]       ),
                .tx_writedata       (tx_writedata    [i]       ),
                .tx_read            (tx_read         [i]       ),
                .tx_write           (tx_write        [i]       ),
                .tx_burstcount      (tx_burstcount   [i]       ),
                .tx_readdatavalid   (tx_readdatavalid[i]       ),
                .tx_waitrequest     (tx_waitrequest  [i]       ),
                .tx_address         (tx_address      [i]       )
            );
        end
    endgenerate

endmodule