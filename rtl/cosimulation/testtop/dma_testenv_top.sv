module dma_testenv_top #(
    parameter     DMA_CHANNEL_COUNT                     = 16         ,

    parameter     DMA_BYTES_WIDTH                       = 22         ,
    parameter     DMA_OFFFSET_WIDTH                     = 22         ,

    parameter int DMA_WORD_BYTES    [DMA_CHANNEL_COUNT] = '{16{16  }},
    parameter int DMA_WQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{1024}},
    parameter int DMA_RQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{1024}},
    parameter     DMA_TQ_DEPTH                          = 8          ,

    parameter int MAX_WQ_DEPTH                          = 1024       ,
    parameter int MAX_RQ_DEPTH                          = 1024       ,
    
    parameter     BAR_DATA_WIDTH                        = 128        ,
    parameter     BAR_ADDR_WIDTH                        = 12         ,

    parameter     TX_DATA_WIDTH                         = 128        ,
    parameter     TX_ADDR_WIDTH                         = 64         ,
    parameter     TX_BURST_WIDTH                        = 6          ,

    parameter     AXI_LD_FIFO_DEPTH                     = 64         ,

    parameter     PMU_METRIC_COUNT                      = 19         ,
    parameter     PMU_DATA_WIDTH                        = 32         ,

    parameter int ROUTERS_COUNT     [DMA_CHANNEL_COUNT] = '{16{16  }},
    parameter     MAX_ROUTERS_COUNT                     = 16         ,

    parameter int AXI_DATA_WIDTH    [DMA_CHANNEL_COUNT] = '{16{32  }},
    parameter int AXI_ADDR_WIDTH    [DMA_CHANNEL_COUNT] = '{16{16  }},
    parameter int AXI_ID_W_WIDTH    [DMA_CHANNEL_COUNT] = '{16{5   }},
    parameter int AXI_ID_R_WIDTH    [DMA_CHANNEL_COUNT] = '{16{5   }},
    parameter     MAX_AXI_DATA_WIDTH                    = 32         ,

    
    parameter ROUTERS_COUNT_WIDTH = MAX_ROUTERS_COUNT == 1 ? 1 : $clog2(MAX_ROUTERS_COUNT),
    parameter BAR_DATA_BYTES      = BAR_DATA_WIDTH / 8                                    ,
    parameter TX_DATA_BYTES       = TX_DATA_WIDTH / 8                                     ,
    parameter DMA_WQ_ADDR_WIDTH   = $clog2(MAX_WQ_DEPTH)                                  ,
    parameter DMA_RQ_ADDR_WIDTH   = $clog2(MAX_RQ_DEPTH)                                  
) (
    input  logic                       clk_dma                                    ,
    input  logic                       rst_n_dma                                  ,

    input  logic                       csr_s_chipselect                           ,
    input  logic [BAR_DATA_BYTES-1:0]  csr_s_byteenable                           ,
    output logic [BAR_DATA_WIDTH-1:0]  csr_s_readdata                             ,
    input  logic [BAR_DATA_WIDTH-1:0]  csr_s_writedata                            ,
    input  logic                       csr_s_read                                 ,
    input  logic                       csr_s_write                                ,
    output logic                       csr_s_readdatavalid                        ,
    output logic                       csr_s_waitrequest                          ,
    input  logic [BAR_ADDR_WIDTH-1:0]  csr_s_address                              ,

    input  logic                       msix_s_chipselect                          ,
    input  logic [BAR_DATA_BYTES-1:0]  msix_s_byteenable                          ,
    output logic [BAR_DATA_WIDTH-1:0]  msix_s_readdata                            ,
    input  logic [BAR_DATA_WIDTH-1:0]  msix_s_writedata                           ,
    input  logic                       msix_s_read                                ,
    input  logic                       msix_s_write                               ,
    output logic                       msix_s_readdatavalid                       ,
    output logic                       msix_s_waitrequest                         ,
    input  logic [BAR_ADDR_WIDTH-1:0]  msix_s_address                             ,

    input  logic                       dec_s_chipselect                           ,
    input  logic [BAR_DATA_BYTES-1:0]  dec_s_byteenable                           ,
    output logic [BAR_DATA_WIDTH-1:0]  dec_s_readdata                             ,
    input  logic [BAR_DATA_WIDTH-1:0]  dec_s_writedata                            ,
    input  logic                       dec_s_read                                 ,
    input  logic                       dec_s_write                                ,
    output logic                       dec_s_readdatavalid                        ,
    output logic                       dec_s_waitrequest                          ,
    input  logic [BAR_ADDR_WIDTH-1:0]  dec_s_address                              ,
    
    output logic                       msix_m_chipselect                          ,
    output logic [TX_DATA_BYTES-1:0]   msix_m_byteenable                          ,
    input  logic [TX_DATA_WIDTH-1:0]   msix_m_readdata                            ,
    output logic [TX_DATA_WIDTH-1:0]   msix_m_writedata                           ,
    output logic                       msix_m_read                                ,
    output logic                       msix_m_write                               ,
    output logic [TX_BURST_WIDTH-1:0]  msix_m_burstcount                          ,
    input  logic                       msix_m_readdatavalid                       ,
    input  logic                       msix_m_waitrequest                         ,
    output logic [TX_ADDR_WIDTH-1:0]   msix_m_address                             ,

    input  logic                       env_csr_s_chipselect                       ,
    input  logic [BAR_DATA_BYTES-1:0]  env_csr_s_byteenable                       ,
    output logic [BAR_DATA_WIDTH-1:0]  env_csr_s_readdata                         ,
    input  logic [BAR_DATA_WIDTH-1:0]  env_csr_s_writedata                        ,
    input  logic                       env_csr_s_read                             ,
    input  logic                       env_csr_s_write                            ,
    output logic                       env_csr_s_readdatavalid                    ,
    output logic                       env_csr_s_waitrequest                      ,
    input  logic [BAR_ADDR_WIDTH-1:0]  env_csr_s_address                          ,

    output logic                       tx_chipselect           [DMA_CHANNEL_COUNT],
    output logic [TX_DATA_BYTES-1:0]   tx_byteenable           [DMA_CHANNEL_COUNT],
    input  logic [TX_DATA_WIDTH-1:0]   tx_readdata             [DMA_CHANNEL_COUNT],
    output logic [TX_DATA_WIDTH-1:0]   tx_writedata            [DMA_CHANNEL_COUNT],
    output logic                       tx_read                 [DMA_CHANNEL_COUNT],
    output logic                       tx_write                [DMA_CHANNEL_COUNT],
    output logic [TX_BURST_WIDTH-1:0]  tx_burstcount           [DMA_CHANNEL_COUNT],
    input  logic                       tx_readdatavalid        [DMA_CHANNEL_COUNT],
    input  logic                       tx_waitrequest          [DMA_CHANNEL_COUNT],
    output logic [TX_ADDR_WIDTH-1:0]   tx_address              [DMA_CHANNEL_COUNT],

    input  logic                       clk_noc                                    
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
    logic [DMA_CHANNEL_COUNT-1:0] ld_start;
    logic [DMA_CHANNEL_COUNT-1:0] ld_read_pmu;

    logic [MAX_ROUTERS_COUNT-1:0]   ld_idle           [DMA_CHANNEL_COUNT];
    logic [MAX_ROUTERS_COUNT-1:0]   ld_masked         [DMA_CHANNEL_COUNT];
    logic [MAX_ROUTERS_COUNT-1:0]   ld_finished       [DMA_CHANNEL_COUNT];
    logic [ROUTERS_COUNT_WIDTH-1:0] ld_rdata_selector [DMA_CHANNEL_COUNT];
    logic [MAX_AXI_DATA_WIDTH-1:0]  ld_rdata          [DMA_CHANNEL_COUNT];

    logic testenv_rst_status;
    logic testenv_rst_assert;

    logic testenv_rst_sync_axi;
    
    logic rst_n_dma_csr, rst_n_noc;
    
    sync_rst #(
        .FF3 (0)
    ) u_sync_rst_to_noc (
        .rst_n_i (~testenv_rst_assert),

        .clk_tgt (clk_noc            ),
        .rst_n_o (rst_n_noc          )
    );
    
    sync_rst #(
        .FF3 (0)
    ) u_sync_rst_to_dma (
        .rst_n_i (~testenv_rst_assert),

        .clk_tgt (clk_dma            ),
        .rst_n_o (rst_n_dma_csr      )
    );

    sync_ff #(
        .FF3        (0),
        .DATA_WIDTH (1)
    ) u_sync_ff_rst_reverse (
        .data_i   (rst_n_noc         ),

        .clk_rd   (clk_dma           ),
        .rst_n_rd (rst_n_dma         ),
        .data_o   (testenv_rst_status)
    );

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

        .BAR_DATA_WIDTH    (BAR_DATA_WIDTH   ),
        .BAR_ADDR_WIDTH    (BAR_ADDR_WIDTH   ),

        .TX_DATA_WIDTH     (TX_DATA_WIDTH    ),
        .TX_ADDR_WIDTH     (TX_ADDR_WIDTH    ),
        .TX_BURST_WIDTH    (TX_BURST_WIDTH   )
    ) u_avmm_dma_top (
        .clk                  (clk_dma              ),
        .rst_n                (rst_n_dma            ),

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
        
        .user_irq_i           (user_irq_i           ),

        .msix_m_chipselect    (msix_m_chipselect    ),
        .msix_m_byteenable    (msix_m_byteenable    ),
        .msix_m_readdata      (msix_m_readdata      ),
        .msix_m_writedata     (msix_m_writedata     ),
        .msix_m_read          (msix_m_read          ),
        .msix_m_write         (msix_m_write         ),
        .msix_m_burstcount    (msix_m_burstcount    ),
        .msix_m_readdatavalid (msix_m_readdatavalid ),
        .msix_m_waitrequest   (msix_m_waitrequest   ),
        .msix_m_address       (msix_m_address       ),

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

        .dma_wrdata_valid_i   (dma_wrdata_valid     ),
        .dma_wrdata_ready_o   (dma_wrdata_ready     ),
        .dma_wrdata_count_i   (dma_wrdata_count     ),
        .dma_wrdata_data_i    (dma_wrdata_data      ),

        .dma_rddata_valid_o   (dma_rddata_valid     ),
        .dma_rddata_ready_i   (dma_rddata_ready     ),
        .dma_rddata_free_i    (dma_rddata_free      ),
        .dma_rddata_data_o    (dma_rddata_data      )
    );

    avmm_testenv_csr #(
        .DMA_CHANNEL_COUNT  (DMA_CHANNEL_COUNT ),
        .MAX_ROUTERS_COUNT  (MAX_ROUTERS_COUNT ),
        .MAX_AXI_DATA_WIDTH (MAX_AXI_DATA_WIDTH),

        .BAR_DATA_WIDTH     (BAR_DATA_WIDTH    ),
        .BAR_ADDR_WIDTH     (BAR_ADDR_WIDTH    )
    ) u_avmm_testenv_csr (
        .clk                  (clk_dma                ),
        .rst_n                (rst_n_dma              ),

        .avmm_s_chipselect    (env_csr_s_chipselect   ),
        .avmm_s_byteenable    (env_csr_s_byteenable   ),
        .avmm_s_readdata      (env_csr_s_readdata     ),
        .avmm_s_writedata     (env_csr_s_writedata    ),
        .avmm_s_read          (env_csr_s_read         ),
        .avmm_s_write         (env_csr_s_write        ),
        .avmm_s_readdatavalid (env_csr_s_readdatavalid),
        .avmm_s_waitrequest   (env_csr_s_waitrequest  ),
        .avmm_s_address       (env_csr_s_address      ),

        .ld_start_o           (ld_start               ),
        .ld_read_pmu_o        (ld_read_pmu            ),
        .ld_rdata_selector_o  (ld_rdata_selector      ),
        .ld_rdata_i           (ld_rdata               ),
        .ld_idle_i            (ld_idle                ),
        .ld_masked_o          (ld_masked              ),

        .testenv_rst_status_i (testenv_rst_status     ),
        .testenv_rst_assert_o (testenv_rst_assert     )
    );
    
    generate
        genvar i;

        for (i = 0; i < DMA_CHANNEL_COUNT; i++) begin : testenvs

            logic                       command_valid;
            logic                       command_ready;
            logic [TX_DATA_WIDTH-1:0]   command_data ;

            logic                       pmu_valid;
            logic                       pmu_ready;
            logic [TX_DATA_WIDTH-1:0]   pmu_data ;

            logic ld_read_pmu_loc, ld_read_pmu_waiter, ld_read_pmu_ready;

            logic [ROUTERS_COUNT[i]-1:0]  ld_masked_loc                     ;
            logic [ROUTERS_COUNT[i]-1:0]  ld_idle_loc                       ;
            logic [ROUTERS_COUNT[i]-1:0]  ld_finished_loc                   ;
            logic [AXI_DATA_WIDTH[i]-1:0] ld_rdata_loc    [ROUTERS_COUNT[i]];

            assign ld_masked_loc  = ld_masked[i];

            assign user_irq_i[i]  = &(ld_finished_loc | ld_masked_loc);
            assign ld_idle[i]     = {{MAX_ROUTERS_COUNT -ROUTERS_COUNT[i] {1'b0}}, ld_idle_loc    };
            assign ld_finished[i] = {{MAX_ROUTERS_COUNT -ROUTERS_COUNT[i] {1'b0}}, ld_finished_loc};
            assign ld_rdata[i]    = {{MAX_AXI_DATA_WIDTH-AXI_DATA_WIDTH[i]{1'b0}}, ld_rdata_loc[ld_rdata_selector[i] >= ROUTERS_COUNT[i] ? '0 : ld_rdata_selector[i]]};

            axi_if #(
                .AXI_DATA_WIDTH (AXI_DATA_WIDTH[i]),
                .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH[i]),
                .AXI_ID_W_WIDTH (AXI_ID_W_WIDTH[i]),
                .AXI_ID_R_WIDTH (AXI_ID_R_WIDTH[i])
            ) u_axi_if[ROUTERS_COUNT[i]](), u_axi_if_ram[ROUTERS_COUNT[i]]();

            cdc_stream_afifo #(
                .DATA_WIDTH (1),
                .ADDR_WIDTH (2)
            ) u_cdc_stream_afifo_ld_read_pmu_resync (
                .clk_wr   (clk_dma           ),
                .rst_n_wr (rst_n_dma_csr     ),

                .data_i   (ld_read_pmu_waiter),
                .valid_i  ('1                ),
                .ready_o  (ld_read_pmu_ready ),
                .free_o   (                  ),

                .clk_rd   (clk_noc           ),
                .rst_n_rd (rst_n_noc         ),

                .data_o   (ld_read_pmu_loc   ),
                .valid_o  (                  ),
                .ready_i  ('1                ),
                .count_o  (                  )
            );

            always @(posedge clk_dma or negedge rst_n_dma_csr) begin
                if (!rst_n_dma_csr) begin
                    ld_read_pmu_waiter <= '0;
                end
                else begin
                    if (ld_read_pmu[i]) begin
                        ld_read_pmu_waiter <= '1;
                    end
                    if (ld_read_pmu_waiter && ld_read_pmu_ready) begin
                        ld_read_pmu_waiter <= '0;
                    end
                end
            end

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
                .ROUTERS_COUNT       (ROUTERS_COUNT[i] ),

                .AXI_DATA_WIDTH      (AXI_DATA_WIDTH[i]),
                .AXI_ADDR_WIDTH      (AXI_ADDR_WIDTH[i]),
                .AXI_ID_W_WIDTH      (AXI_ID_W_WIDTH[i]),
                .AXI_ID_R_WIDTH      (AXI_ID_R_WIDTH[i]),

                .EXT_FIFO_DATA_WIDTH (TX_DATA_WIDTH    ),

                .AXI_LD_FIFO_DEPTH   (AXI_LD_FIFO_DEPTH),

                .PMU_METRIC_COUNT    (PMU_METRIC_COUNT ),
                .PMU_DATA_WIDTH      (PMU_DATA_WIDTH   )
            ) u_axi_testenv (
                .clk_in          (clk_dma        ),
                .rst_n_in        (rst_n_dma_csr  ),

                .command_data_i  (command_data   ),
                .command_valid_i (command_valid  ),
                .command_ready_o (command_ready  ),

                .pmu_data_o      (pmu_data       ),
                .pmu_valid_o     (pmu_valid      ),
                .pmu_ready_i     (pmu_ready      ),

                .ld_start_i      (ld_start[i]    ),
                .ld_read_pmu_i   (ld_read_pmu_loc),
                
                .ld_idle_o       (ld_idle_loc    ),
                .ld_finished_o   (ld_finished_loc),
                .ld_rdata_o      (ld_rdata_loc   ),

                .clk_axi         (clk_noc        ),
                .rst_n_axi       (rst_n_noc      ),

                .m_axi_if_o      (u_axi_if       )                           
            );

            // NOC GOES HERE 
            //     vvvv
            mesh #(.AXI_DATA_WIDTH(AXI_DATA_WIDTH[i]),
                .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH[i]),
                .AXI_ID_W_WIDTH(AXI_ID_W_WIDTH[i]),
                .AXI_ID_R_WIDTH(AXI_ID_R_WIDTH[i]),
                .MAX_ROUTERS_X(4),
                .MAX_ROUTERS_Y(4),
                .VIRTUAL_CHANNEL_NUMBER(2),
                .VIRTUAL_NETWORKS('{1, 1}),
                //.ALGORITHM("EWn_SNe"),
                .BUFFER_ALLOCATOR("KeepInNetwork"),
                .SIMULTANIOUS_VIRTUAL_NETWORK_ROUTING(1)
            ) dut (
                .ACLK   (clk_noc     ),
                .ARESETn(rst_n_noc   ),

                .s_axi_i(u_axi_if    ),
                .m_axi_o(u_axi_if_ram)
            );

            genvar j;
            for (j = 0; j < ROUTERS_COUNT[i]; j++) begin : rams
                axi_ram #(
                    .AXI_DATA_WIDTH (AXI_DATA_WIDTH[i]),
                    .AXI_ID_W_WIDTH (AXI_ID_W_WIDTH[i]),
                    .AXI_ID_R_WIDTH (AXI_ID_R_WIDTH[i]),
                    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH[i])
                ) u_axi_ram (
                    .clk_i   (clk_noc    ),
                    .rst_n_i (rst_n_noc  ),
                    
                    .s_axi_i (u_axi_if_ram[j])
                );
            end
            //     ^^^^
            // NOC GOES HERE
        end
    endgenerate
    
endmodule