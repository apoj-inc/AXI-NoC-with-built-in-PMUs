module dma_testenv_top #(
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
    parameter     TX_ADDR_WIDTH                         = 64         ,
    parameter     TX_BURST_WIDTH                        = 6          ,

    parameter     AXI_LD_FIFO_DEPTH                     = 64         ,

    parameter     PMU_METRIC_COUNT                      = 19         ,
    parameter     PMU_DATA_WIDTH                        = 32         ,

    
    parameter BAR_DATA_BYTES    = BAR_DATA_WIDTH / 8  ,
    parameter TX_DATA_BYTES     = TX_DATA_WIDTH / 8   ,
    parameter DMA_WQ_ADDR_WIDTH = $clog2(MAX_WQ_DEPTH),
    parameter DMA_RQ_ADDR_WIDTH = $clog2(MAX_RQ_DEPTH)
) (
    input  logic                       clk_dma                                       ,
    input  logic                       rst_n_dma                                     ,

    input  logic                       csr_s_chipselect                              ,
    input  logic [BAR_DATA_BYTES-1:0]  csr_s_byteenable                              ,
    output logic [BAR_DATA_WIDTH-1:0]  csr_s_readdata                                ,
    input  logic [BAR_DATA_WIDTH-1:0]  csr_s_writedata                               ,
    input  logic                       csr_s_read                                    ,
    input  logic                       csr_s_write                                   ,
    output logic                       csr_s_readdatavalid                           ,
    output logic                       csr_s_waitrequest                             ,
    input  logic [BAR_ADDR_WIDTH-1:0]  csr_s_address                                 ,

    input  logic                       msix_s_chipselect                             ,
    input  logic [BAR_DATA_BYTES-1:0]  msix_s_byteenable                             ,
    output logic [BAR_DATA_WIDTH-1:0]  msix_s_readdata                               ,
    input  logic [BAR_DATA_WIDTH-1:0]  msix_s_writedata                              ,
    input  logic                       msix_s_read                                   ,
    input  logic                       msix_s_write                                  ,
    output logic                       msix_s_readdatavalid                          ,
    output logic                       msix_s_waitrequest                            ,
    input  logic [BAR_ADDR_WIDTH-1:0]  msix_s_address                                ,

    input  logic                       dec_s_chipselect                              ,
    input  logic [BAR_DATA_BYTES-1:0]  dec_s_byteenable                              ,
    output logic [BAR_DATA_WIDTH-1:0]  dec_s_readdata                                ,
    input  logic [BAR_DATA_WIDTH-1:0]  dec_s_writedata                               ,
    input  logic                       dec_s_read                                    ,
    input  logic                       dec_s_write                                   ,
    output logic                       dec_s_readdatavalid                           ,
    output logic                       dec_s_waitrequest                             ,
    input  logic [BAR_ADDR_WIDTH-1:0]  dec_s_address                                 ,
    
    output logic                       user_msix_m_chipselect                        ,
    output logic [TX_DATA_BYTES-1:0]   user_msix_m_byteenable                        ,
    input  logic [TX_DATA_WIDTH-1:0]   user_msix_m_readdata                          ,
    output logic [TX_DATA_WIDTH-1:0]   user_msix_m_writedata                         ,
    output logic                       user_msix_m_read                              ,
    output logic                       user_msix_m_write                             ,
    output logic [TX_BURST_WIDTH-1:0]  user_msix_m_burstcount                        ,
    input  logic                       user_msix_m_readdatavalid                     ,
    input  logic                       user_msix_m_waitrequest                       ,
    output logic [TX_ADDR_WIDTH-1:0]   user_msix_m_address                           ,

    output logic                       tx_chipselect              [DMA_CHANNEL_COUNT],
    output logic [TX_DATA_BYTES-1:0]   tx_byteenable              [DMA_CHANNEL_COUNT],
    input  logic [TX_DATA_WIDTH-1:0]   tx_readdata                [DMA_CHANNEL_COUNT],
    output logic [TX_DATA_WIDTH-1:0]   tx_writedata               [DMA_CHANNEL_COUNT],
    output logic                       tx_read                    [DMA_CHANNEL_COUNT],
    output logic                       tx_write                   [DMA_CHANNEL_COUNT],
    output logic [TX_BURST_WIDTH-1:0]  tx_burstcount              [DMA_CHANNEL_COUNT],
    input  logic                       tx_readdatavalid           [DMA_CHANNEL_COUNT],
    input  logic                       tx_waitrequest             [DMA_CHANNEL_COUNT],
    output logic [TX_ADDR_WIDTH-1:0]   tx_address                 [DMA_CHANNEL_COUNT],

    input  logic                       clk_noc                                       ,
    input  logic                       rst_n_noc                                     
);

    logic                       dma_wrdata_valid   [DMA_CHANNEL_COUNT];
    logic                       dma_wrdata_ready   [DMA_CHANNEL_COUNT];
    logic [DMA_WQ_ADDR_WIDTH:0] dma_wrdata_count   [DMA_CHANNEL_COUNT];
    logic [TX_DATA_WIDTH-1:0]   dma_wrdata_data    [DMA_CHANNEL_COUNT];

    logic                       dma_rddata_valid   [DMA_CHANNEL_COUNT];
    logic                       dma_rddata_ready   [DMA_CHANNEL_COUNT];
    logic [DMA_RQ_ADDR_WIDTH:0] dma_rddata_free    [DMA_CHANNEL_COUNT];
    logic [TX_DATA_WIDTH-1:0]   dma_rddata_data    [DMA_CHANNEL_COUNT];

    logic [DMA_CHANNEL_COUNT-1:0] user_irq_i;

    avmm_dma_top #(
        .DMA_CHANNEL_COUNT (DMA_CHANNEL_COUNT),

        .DMA_BYTES_WIDTH   (DMA_BYTES_WIDTH  ),
        .DMA_OFFFSET_WIDTH (DMA_OFFFSET_WIDTH),

        .DMA_WORD_BYTES    (DMA_WORD_BYTES   ),
        .DMA_WQ_DEPTH      (DMA_WQ_DEPTH     ),
        .DMA_RQ_DEPTH      (DMA_RQ_DEPTH     ),
        .DMA_TQ_DEPTH      (DMA_TQ_DEPTH     ),

        .MAX_WQ_DEPTH      (MAX_WQ_DEPTH     ),
        .MAX_RQ_DEPTH      (MAX_RQ_DEPTH     ),
        .MAX_TQ_DEPTH      (MAX_TQ_DEPTH     ),

        .BAR_DATA_WIDTH    (BAR_DATA_WIDTH   ),
        .BAR_ADDR_WIDTH    (BAR_ADDR_WIDTH   ),

        .TX_DATA_WIDTH     (TX_DATA_WIDTH    ),
        .TX_ADDR_WIDTH     (TX_ADDR_WIDTH    ),
        .TX_BURST_WIDTH    (TX_BURST_WIDTH   )
    ) u_avmm_dma_top (
        .clk                       (clk_dma                  ),
        .rst_n                     (rst_n_dma                ),

        .csr_s_chipselect          (csr_s_chipselect         ),
        .csr_s_byteenable          (csr_s_byteenable         ),
        .csr_s_readdata            (csr_s_readdata           ),
        .csr_s_writedata           (csr_s_writedata          ),
        .csr_s_read                (csr_s_read               ),
        .csr_s_write               (csr_s_write              ),
        .csr_s_readdatavalid       (csr_s_readdatavalid      ),
        .csr_s_waitrequest         (csr_s_waitrequest        ),
        .csr_s_address             (csr_s_address            ),

        .msix_s_chipselect         (msix_s_chipselect        ),
        .msix_s_byteenable         (msix_s_byteenable        ),
        .msix_s_readdata           (msix_s_readdata          ),
        .msix_s_writedata          (msix_s_writedata         ),
        .msix_s_read               (msix_s_read              ),
        .msix_s_write              (msix_s_write             ),
        .msix_s_readdatavalid      (msix_s_readdatavalid     ),
        .msix_s_waitrequest        (msix_s_waitrequest       ),
        .msix_s_address            (msix_s_address           ),

        .dec_s_chipselect          (dec_s_chipselect         ),
        .dec_s_byteenable          (dec_s_byteenable         ),
        .dec_s_readdata            (dec_s_readdata           ),
        .dec_s_writedata           (dec_s_writedata          ),
        .dec_s_read                (dec_s_read               ),
        .dec_s_write               (dec_s_write              ),
        .dec_s_readdatavalid       (dec_s_readdatavalid      ),
        .dec_s_waitrequest         (dec_s_waitrequest        ),
        .dec_s_address             (dec_s_address            ),
        
        .user_irq_i                (user_irq_i               ),

        .user_msix_m_chipselect    (user_msix_m_chipselect   ),
        .user_msix_m_byteenable    (user_msix_m_byteenable   ),
        .user_msix_m_readdata      (user_msix_m_readdata     ),
        .user_msix_m_writedata     (user_msix_m_writedata    ),
        .user_msix_m_read          (user_msix_m_read         ),
        .user_msix_m_write         (user_msix_m_write        ),
        .user_msix_m_burstcount    (user_msix_m_burstcount   ),
        .user_msix_m_readdatavalid (user_msix_m_readdatavalid),
        .user_msix_m_waitrequest   (user_msix_m_waitrequest  ),
        .user_msix_m_address       (user_msix_m_address      ),

        .tx_chipselect             (tx_chipselect            ),
        .tx_byteenable             (tx_byteenable            ),
        .tx_readdata               (tx_readdata              ),
        .tx_writedata              (tx_writedata             ),
        .tx_read                   (tx_read                  ),
        .tx_write                  (tx_write                 ),
        .tx_burstcount             (tx_burstcount            ),
        .tx_readdatavalid          (tx_readdatavalid         ),
        .tx_waitrequest            (tx_waitrequest           ),
        .tx_address                (tx_address               ),

        .dma_wrdata_valid_i        (dma_wrdata_valid         ),
        .dma_wrdata_ready_o        (dma_wrdata_ready         ),
        .dma_wrdata_count_i        (dma_wrdata_count         ),
        .dma_wrdata_data_i         (dma_wrdata_data          ),

        .dma_rddata_valid_o        (dma_rddata_valid         ),
        .dma_rddata_ready_i        (dma_rddata_ready         ),
        .dma_rddata_free_i         (dma_rddata_free          ),
        .dma_rddata_data_o         (dma_rddata_data          )
    );

    
    generate
        genvar i;

        for (i = 0; i < DMA_CHANNEL_COUNT; i++) begin : testenvs

            parameter ROUTERS_COUNT       = 16 ;

            parameter AXI_DATA_WIDTH      = 32 ;
            parameter AXI_ADDR_WIDTH      = 16 ;
            parameter AXI_ID_W_WIDTH      = 5  ;
            parameter AXI_ID_R_WIDTH      = 5  ;

            parameter EXT_FIFO_DATA_WIDTH = 128;

            parameter AXI_LD_FIFO_DEPTH   = 64 ;

            parameter PMU_METRIC_COUNT    = 19 ;
            parameter PMU_DATA_WIDTH      = 32 ;

            logic                       command_valid;
            logic                       command_ready;
            logic [TX_DATA_WIDTH-1:0]   command_data ;

            logic                       pmu_valid;
            logic                       pmu_ready;
            logic [TX_DATA_WIDTH-1:0]   pmu_data ;

            logic [ROUTERS_COUNT-1:0] ld_finished;

            assign user_irq_i[i] = |ld_finished;

            axi_if #(
                .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
                .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
                .AXI_ID_W_WIDTH (AXI_ID_W_WIDTH),
                .AXI_ID_R_WIDTH (AXI_ID_R_WIDTH)
            ) u_axi_if[ROUTERS_COUNT]();

            stream_fifo #(
                .DATA_WIDTH (TX_DATA_WIDTH  ),
                .FIFO_DEPTH (DMA_WQ_DEPTH[i])
            ) u_stream_fifo_dmawr (
                .ACLK    (clk_dma            ),
                .ARESETn (rst_n_dma          ),

                .data_i  (pmu_data           ),
                .valid_i (pmu_valid          ),
                .ready_o (pmu_ready          ),
                .free_o  (                   ),

                .data_o  (dma_wrdata_data [i]),
                .valid_o (dma_wrdata_valid[i]),
                .ready_i (dma_wrdata_ready[i]),
                .count_o (dma_wrdata_count[i])
            );

            stream_fifo #(
                .DATA_WIDTH (TX_DATA_WIDTH  ),
                .FIFO_DEPTH (DMA_WQ_DEPTH[i])
            ) u_stream_fifo_dmard (
                .ACLK    (clk_dma            ),
                .ARESETn (rst_n_dma          ),

                .data_i  (dma_rddata_data [i]),
                .valid_i (dma_rddata_valid[i]),
                .ready_o (dma_rddata_ready[i]),
                .free_o  (dma_rddata_free [i]),

                .data_o  (command_data       ),
                .valid_o (command_valid      ),
                .ready_i (command_ready      ),
                .count_o (                   )
            );

            axi_testenv #(
                .ROUTERS_COUNT       (ROUTERS_COUNT    ),

                .AXI_DATA_WIDTH      (AXI_DATA_WIDTH   ),
                .AXI_ADDR_WIDTH      (AXI_ADDR_WIDTH   ),
                .AXI_ID_W_WIDTH      (AXI_ID_W_WIDTH   ),
                .AXI_ID_R_WIDTH      (AXI_ID_R_WIDTH   ),

                .EXT_FIFO_DATA_WIDTH (TX_DATA_WIDTH    ),

                .AXI_LD_FIFO_DEPTH   (AXI_LD_FIFO_DEPTH),

                .PMU_METRIC_COUNT    (PMU_METRIC_COUNT ),
                .PMU_DATA_WIDTH      (PMU_DATA_WIDTH   )
            ) u_axi_testenv (
                .clk_in          (clk_dma      ),
                .rst_n_in        (rst_n_dma    ),

                .command_data_i  (command_data ),
                .command_valid_i (command_valid),
                .command_ready_o (command_ready),

                .pmu_data_o      (pmu_data     ),
                .pmu_valid_o     (pmu_valid    ),
                .pmu_ready_i     (pmu_ready    ),

                .clk_axi         (clk_noc      ),
                .rst_n_axi       (rst_n_noc    ),

                .ld_idle_o       (             ), // NC
                .ld_finished_o   (ld_finished  ),
                .ld_rdata_o      (             ), // NC

                .m_axi_if_o      (u_axi_if     )                           
            );

            // NOC GOES HERE 
            //     vvvv
            genvar j;
            for (j = 0; j < ROUTERS_COUNT; j++) begin : rams
                axi_ram #(
                    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
                    .AXI_ID_W_WIDTH (AXI_ID_W_WIDTH),
                    .AXI_ID_R_WIDTH (AXI_ID_R_WIDTH),
                    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH)
                ) u_axi_ram (
                    .clk_i   (clk_noc    ),
                    .rst_n_i (rst_n_noc  ),
                    
                    .s_axi_i (u_axi_if[j])
                );
            end
            //     ^^^^
            // NOC GOES HERE
        end
    endgenerate
    
endmodule