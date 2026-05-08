module tb_dma_with_testenv;

parameter     FIFO_DEPTH                            = 64         ;

parameter     PMU_METRIC_COUNT                      = 19         ;
parameter     PMU_DATA_WIDTH                        = 32         ;
parameter     DMA_DATA_WIDTH                        = 128        ;

parameter     DMA_CHANNEL_COUNT                     = 8          ;

parameter     DMA_BYTES_WIDTH                       = 22         ;
parameter     DMA_OFFFSET_WIDTH                     = 22         ;

parameter int DMA_WORD_BYTES    [DMA_CHANNEL_COUNT] = '{8 {16  }};
parameter int DMA_WQ_DEPTH      [DMA_CHANNEL_COUNT] = '{8 {1024}};
parameter int DMA_RQ_DEPTH      [DMA_CHANNEL_COUNT] = '{8 {1024}};
parameter int DMA_TQ_DEPTH      [DMA_CHANNEL_COUNT] = '{8 {16  }};

parameter int MAX_WQ_DEPTH                          = 1024       ;
parameter int MAX_RQ_DEPTH                          = 1024       ;
parameter int MAX_TQ_DEPTH                          = 16         ;

parameter     BAR_DATA_WIDTH                        = 128        ;
parameter     BAR_ADDR_WIDTH                        = 12         ;

parameter     TX_DATA_WIDTH                         = 128        ;
parameter     TX_ADDR_WIDTH                         = 64         ;
parameter     TX_BURST_WIDTH                        = 6          ;

parameter int ROUTERS_COUNT     [DMA_CHANNEL_COUNT] = '{8 {16  }};
parameter     MAX_ROUTERS_COUNT                     = 16         ;
parameter int AXI_DATA_WIDTH    [DMA_CHANNEL_COUNT] = '{8 {32  }};
parameter int AXI_ADDR_WIDTH    [DMA_CHANNEL_COUNT] = '{8 {16  }};
parameter int AXI_ID_W_WIDTH    [DMA_CHANNEL_COUNT] = '{8 {5   }};
parameter int AXI_ID_R_WIDTH    [DMA_CHANNEL_COUNT] = '{8 {5   }};
parameter     MAX_AXI_DATA_WIDTH                    = 32         ;
parameter     MAX_AXI_ADDR_WIDTH                    = 16         ;
parameter     MAX_AXI_ID_W_WIDTH                    = 5          ;
parameter     MAX_AXI_ID_R_WIDTH                    = 5          ;

parameter PMU_ADDR_WIDTH = PMU_METRIC_COUNT == 1 ? 1 : $clog2(PMU_METRIC_COUNT);

parameter MSI_COUNT               = DMA_CHANNEL_COUNT                     ;
parameter BAR_DATA_BYTES          = BAR_DATA_WIDTH / 8                    ;
parameter TX_DATA_BYTES           = TX_DATA_WIDTH / 8                     ;
parameter DMA_WQ_ADDR_WIDTH       = $clog2(MAX_WQ_DEPTH)                  ;
parameter DMA_RQ_ADDR_WIDTH       = $clog2(MAX_RQ_DEPTH)                  ;
parameter DMA_TQ_ADDR_WIDTH       = $clog2(MAX_TQ_DEPTH)                  ;
parameter PBA_COUNT               = MSI_COUNT / 64 + (MSI_COUNT % 64 != 0);
parameter DMA_BURST_WIDTH         = DMA_BYTES_WIDTH - 4                   ;
parameter DMA_CHANNEL_COUNT_WIDTH = $clog2(DMA_CHANNEL_COUNT)             ;


parameter ROUTERS_COUNT_WIDTH  = (MAX_ROUTERS_COUNT == 1) ? 1 : $clog2(MAX_ROUTERS_COUNT)                                                    ;
parameter AXI_MAX_ID_WIDTH     = (MAX_AXI_ID_W_WIDTH > MAX_AXI_ID_R_WIDTH) ? MAX_AXI_ID_W_WIDTH : MAX_AXI_ID_R_WIDTH                         ;

parameter ROUTERS_COUNT_BYTES  = ROUTERS_COUNT_WIDTH / 8 + (ROUTERS_COUNT_WIDTH % 8 != 0)                                                    ;
parameter AXI_DATA_BYTES       = MAX_AXI_DATA_WIDTH  / 8 + (MAX_AXI_DATA_WIDTH  % 8 != 0)                                                    ;
parameter AXI_MAX_ID_BYTES     = AXI_MAX_ID_WIDTH    / 8 + (AXI_MAX_ID_WIDTH    % 8 != 0)                                                    ;
parameter AXI_ADDR_BYTES       = MAX_AXI_ADDR_WIDTH  / 8 + (MAX_AXI_ADDR_WIDTH  % 8 != 0)                                                    ;
parameter AXI_WSTRB_BYTES      = AXI_DATA_BYTES      / 8 + (AXI_DATA_BYTES      % 8 != 0)                                                    ;

parameter AXI_CUMULATIVE_WIDTH = (ROUTERS_COUNT_BYTES + 1 + AXI_MAX_ID_BYTES + 1 + AXI_ADDR_BYTES + 1 + AXI_DATA_BYTES + AXI_WSTRB_BYTES) * 8;

parameter WIDTH_RATIO          = AXI_CUMULATIVE_WIDTH / DMA_DATA_WIDTH + (AXI_CUMULATIVE_WIDTH % DMA_DATA_WIDTH != 0)                        ;
parameter WIDTH_REMAINDER      = (AXI_CUMULATIVE_WIDTH % DMA_DATA_WIDTH == 0) ? DMA_DATA_WIDTH : (AXI_CUMULATIVE_WIDTH % DMA_DATA_WIDTH)     ;

parameter PMU_WIDTH_RATIO      = (PMU_METRIC_COUNT*PMU_DATA_WIDTH / DMA_DATA_WIDTH) + (PMU_METRIC_COUNT*PMU_DATA_WIDTH % DMA_DATA_WIDTH != 0);

parameter DMA_PMU_READ_BYTES   = (PMU_WIDTH_RATIO*DMA_DATA_WIDTH / 8) * MAX_ROUTERS_COUNT;

int queue_sizes [DMA_CHANNEL_COUNT];

generate
    for (genvar i = 0; i < DMA_CHANNEL_COUNT; i++) begin : task_files
        logic [AXI_CUMULATIVE_WIDTH-1:0] task_file_queue [$];
        logic [DMA_DATA_WIDTH-1:0] tx_readdata_queue [$];

        logic [AXI_CUMULATIVE_WIDTH-1:0] current_task;
        int current_slice;

        initial begin

            for (int iter = 0; iter < 2; iter++) begin
                for (int j = 0; j < FIFO_DEPTH*ROUTERS_COUNT[i]; j++) begin : create_tasks
                    task_file_queue.push_back({ (ROUTERS_COUNT_BYTES*8)'(                        j / FIFO_DEPTH),
                                                                (1*8  )'(                                     0),
                                                (AXI_MAX_ID_BYTES*8   )'(      $urandom(                      )),
                                                                (1*8  )'(                                     1),
                                                    (AXI_ADDR_BYTES*8 )'(                                    '0),
                                                                (1*8  )'(                                     4),
                                                    (AXI_DATA_BYTES*8 )'(      $urandom(                      )),
                                                    (AXI_WSTRB_BYTES*8)'(      $urandom(                      ))
                                            });
                end

                for (int j = 0; j < FIFO_DEPTH*ROUTERS_COUNT[i]; j++) begin : create_tasks
                    task_file_queue.push_back({ (ROUTERS_COUNT_BYTES*8)'(                        j / FIFO_DEPTH),
                                                                (1*8  )'(                                     0),
                                                (AXI_MAX_ID_BYTES*8   )'(      $urandom(                      )),
                                                                (1*8  )'(                                     0),
                                                    (AXI_ADDR_BYTES*8 )'(                                    '0),
                                                                (1*8  )'(                                      2),
                                                    (AXI_DATA_BYTES*8 )'(      $urandom(                      )),
                                                    (AXI_WSTRB_BYTES*8)'(      $urandom(                      ))
                                            });
                end

                while (task_file_queue.size()) begin
                    current_slice = 0;
                    current_task = task_file_queue.pop_front();

                    while (current_slice < WIDTH_RATIO) begin
                        if (current_slice + 1 < WIDTH_RATIO) begin
                            tx_readdata_queue.push_back(current_task[current_slice*DMA_DATA_WIDTH +: DMA_DATA_WIDTH]);
                        end
                        else begin
                            tx_readdata_queue.push_back(current_task[current_slice*DMA_DATA_WIDTH +: WIDTH_REMAINDER]);
                        end
                        current_slice = current_slice + 1;
                    end
                end
                tx_readdata_queue.push_back('1);
            end
            
            queue_sizes[i] = tx_readdata_queue.size();
        end
    end
endgenerate


logic        test_done           ;
logic [15:0] current_struct      ;

logic                       clk                                     ;
logic                       rst_n                                   ;

logic                       clk_axi                                 ;
logic                       rst_n_axi                               ;

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

logic                       user_msix_m_chipselect                  ;
logic [TX_DATA_BYTES-1:0]   user_msix_m_byteenable                  ;
logic [TX_DATA_WIDTH-1:0]   user_msix_m_readdata                    ;
logic [TX_DATA_WIDTH-1:0]   user_msix_m_writedata                   ;
logic                       user_msix_m_read                        ;
logic                       user_msix_m_write                       ;
logic [TX_BURST_WIDTH-1:0]  user_msix_m_burstcount                  ;
logic                       user_msix_m_readdatavalid               ;
logic                       user_msix_m_waitrequest                 ;
logic [TX_ADDR_WIDTH-1:0]   user_msix_m_address                     ;

logic                       env_csr_s_chipselect                    ;
logic [BAR_DATA_BYTES-1:0]  env_csr_s_byteenable                    ;
logic [BAR_DATA_WIDTH-1:0]  env_csr_s_readdata                      ;
logic [BAR_DATA_WIDTH-1:0]  env_csr_s_writedata                     ;
logic                       env_csr_s_read                          ;
logic                       env_csr_s_write                         ;
logic                       env_csr_s_readdatavalid                 ;
logic                       env_csr_s_waitrequest                   ;
logic [BAR_ADDR_WIDTH-1:0]  env_csr_s_address                       ;

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


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        user_msix_m_waitrequest <= '1;
    end
    else begin
        user_msix_m_waitrequest <= $urandom();
    end
end

generate
    for (genvar i = 0; i < DMA_CHANNEL_COUNT; i++) begin : multiply_pmu_dumps
        logic [PMU_WIDTH_RATIO*DMA_DATA_WIDTH-1:0] pmu_dump [ROUTERS_COUNT[i]];
        for (genvar j = 0; j < ROUTERS_COUNT[i]; j++) begin : extract_all_pmus
            assign pmu_dump[j] = {u_dma_testenv_top.testenvs[i].u_axi_testenv.pmus_and_generators[j].u_axi_pmu.clock_counter,
                                  u_dma_testenv_top.testenvs[i].u_axi_testenv.pmus_and_generators[j].u_axi_pmu.wc,
                                  u_dma_testenv_top.testenvs[i].u_axi_testenv.pmus_and_generators[j].u_axi_pmu.rc};
        end
    end
endgenerate

generate
    for (genvar i = 0; i < DMA_CHANNEL_COUNT; i++) begin : log_queues
        logic [DMA_DATA_WIDTH-1:0] tx_writedata_queue [$];

        always_ff @(posedge clk) begin
            if (tx_write[i] && !tx_waitrequest[i]) begin
                if (!((tx_address[i] == {32'('hFEE00000), 32'((i/4)*16)}) && (tx_byteenable[i] == ('h000F << ((i%4)*4))) && (tx_writedata[i] == (32'('hDEADBEE0 + i) << ((i%4)*32))))) begin
                    tx_writedata_queue.push_back(tx_writedata[i]);
                end
            end
        end
    end
endgenerate

generate
    for (genvar i = 0; i < DMA_CHANNEL_COUNT; i++) begin : tx_read_logic
        logic rdvalid_gate;
        logic [31:0] reads_pipelined;

        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                tx_waitrequest[i] <= '1;
                tx_readdata[i]    <= task_files[i].tx_readdata_queue.pop_front();
            end
            else begin
                tx_waitrequest[i] <= '0;
                if (tx_readdatavalid[i]) begin
                    tx_readdata[i] <= task_files[i].tx_readdata_queue.pop_front();
                end
            end
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                reads_pipelined <= '0;
            end
            else begin
                if (tx_chipselect[i] && tx_read[i] && !tx_waitrequest[i]) begin
                    reads_pipelined <= reads_pipelined + tx_burstcount[i] - tx_readdatavalid[i];
                end
                else if (tx_readdatavalid[i]) begin
                    reads_pipelined <= reads_pipelined - 1;
                end
            end
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                rdvalid_gate <= '0;
            end
            else begin
                rdvalid_gate <= $urandom();
            end
        end

        assign tx_readdatavalid[i] = (reads_pipelined != 0) & rdvalid_gate;
    end

    for (genvar i = 0; i < DMA_CHANNEL_COUNT; i++) begin : convenience
        logic                       loc_tx_chipselect   ;
        logic [TX_DATA_BYTES-1:0]   loc_tx_byteenable   ;
        logic [TX_DATA_WIDTH-1:0]   loc_tx_readdata     ;
        logic [TX_DATA_WIDTH-1:0]   loc_tx_writedata    ;
        logic                       loc_tx_read         ;
        logic                       loc_tx_write        ;
        logic [TX_BURST_WIDTH-1:0]  loc_tx_burstcount   ;
        logic                       loc_tx_readdatavalid;
        logic                       loc_tx_waitrequest  ;
        logic [TX_ADDR_WIDTH-1:0]   loc_tx_address      ;

        assign loc_tx_chipselect    = tx_chipselect   [i];
        assign loc_tx_byteenable    = tx_byteenable   [i];
        assign loc_tx_readdata      = tx_readdata     [i];
        assign loc_tx_writedata     = tx_writedata    [i];
        assign loc_tx_read          = tx_read         [i];
        assign loc_tx_write         = tx_write        [i];
        assign loc_tx_burstcount    = tx_burstcount   [i];
        assign loc_tx_readdatavalid = tx_readdatavalid[i];
        assign loc_tx_waitrequest   = tx_waitrequest  [i];
        assign loc_tx_address       = tx_address      [i];
    end
endgenerate

dma_testenv_top #(
    .DMA_CHANNEL_COUNT  (DMA_CHANNEL_COUNT ),

    .DMA_BYTES_WIDTH    (DMA_BYTES_WIDTH   ),
    .DMA_OFFFSET_WIDTH  (DMA_OFFFSET_WIDTH ),

    .DMA_WORD_BYTES     (DMA_WORD_BYTES    ),
    .DMA_WQ_DEPTH       (DMA_WQ_DEPTH      ),
    .DMA_RQ_DEPTH       (DMA_RQ_DEPTH      ),
    .DMA_TQ_DEPTH       (DMA_TQ_DEPTH      ),

    .MAX_WQ_DEPTH       (MAX_WQ_DEPTH      ),
    .MAX_RQ_DEPTH       (MAX_RQ_DEPTH      ),
    .MAX_TQ_DEPTH       (MAX_TQ_DEPTH      ),

    .BAR_DATA_WIDTH     (BAR_DATA_WIDTH    ),
    .BAR_ADDR_WIDTH     (BAR_ADDR_WIDTH    ),

    .TX_DATA_WIDTH      (TX_DATA_WIDTH     ),
    .TX_ADDR_WIDTH      (TX_ADDR_WIDTH     ),
    .TX_BURST_WIDTH     (TX_BURST_WIDTH    ),

    .AXI_LD_FIFO_DEPTH  (FIFO_DEPTH        ),

    .PMU_METRIC_COUNT   (PMU_METRIC_COUNT  ),
    .PMU_DATA_WIDTH     (PMU_DATA_WIDTH    ),

    .ROUTERS_COUNT      (ROUTERS_COUNT     ),
    .MAX_ROUTERS_COUNT  (MAX_ROUTERS_COUNT ),

    .AXI_DATA_WIDTH     (AXI_DATA_WIDTH    ),
    .AXI_ADDR_WIDTH     (AXI_ADDR_WIDTH    ),
    .AXI_ID_W_WIDTH     (AXI_ID_W_WIDTH    ),
    .AXI_ID_R_WIDTH     (AXI_ID_R_WIDTH    ),
    .MAX_AXI_DATA_WIDTH (MAX_AXI_DATA_WIDTH)
) u_dma_testenv_top (
    .clk_dma                   (clk                      ),
    .rst_n_dma                 (rst_n                    ),

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

    .env_csr_s_chipselect      (env_csr_s_chipselect     ),
    .env_csr_s_byteenable      (env_csr_s_byteenable     ),
    .env_csr_s_readdata        (env_csr_s_readdata       ),
    .env_csr_s_writedata       (env_csr_s_writedata      ),
    .env_csr_s_read            (env_csr_s_read           ),
    .env_csr_s_write           (env_csr_s_write          ),
    .env_csr_s_readdatavalid   (env_csr_s_readdatavalid  ),
    .env_csr_s_waitrequest     (env_csr_s_waitrequest    ),
    .env_csr_s_address         (env_csr_s_address        ),

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

    .clk_noc                   (clk_axi                  )
);

always #4  clk = ~clk;
always #10 clk_axi = ~clk_axi;

logic start_validate, finish_validate;

initial begin
    test_done = '0;
    start_validate = 0;

    clk = '1;
    rst_n = '0;

    clk_axi = '1;
    rst_n_axi = '0;

    csr_s_chipselect  = '0;
    csr_s_byteenable  = '0;
    csr_s_writedata   = '0;
    csr_s_read        = '0;
    csr_s_write       = '0;
    csr_s_address     = '0;

    msix_s_chipselect = '0;
    msix_s_byteenable = '0;
    msix_s_writedata  = '0;
    msix_s_read       = '0;
    msix_s_write      = '0;
    msix_s_address    = '0;

    dec_s_chipselect  = '0;
    dec_s_byteenable  = '0;
    dec_s_writedata   = '0;
    dec_s_read        = '0;
    dec_s_write       = '0;
    dec_s_address     = '0;

    #15;
    rst_n = '1;
    rst_n_axi = '1;
    @(posedge clk);

    csr_s_chipselect = '1;
    csr_s_byteenable = 'h000F;
    csr_s_read       = '1;
    csr_s_write      = '0;
    csr_s_writedata  = '0;
    csr_s_address    = '0;
    @(posedge clk);
    csr_s_read       = '0;
    while (!csr_s_readdatavalid) begin
        @(posedge clk);
    end
    current_struct = csr_s_readdata[31:16];
    $display("DMA channels: %d;", csr_s_readdata[15:0]);
    $display("Address of struct 0: 0x%x;", csr_s_readdata[31:16]);

    // DMA configuration
    for (int i = 0; i < DMA_CHANNEL_COUNT; i++) begin
        // Write DMA ADDR LO
        csr_s_chipselect = '1;
        csr_s_byteenable = 'h00F0;
        csr_s_read       = '0;
        csr_s_write      = '1;
        csr_s_writedata  = '0;
        csr_s_address    = current_struct;
        @(posedge clk);
        while (csr_s_waitrequest) begin
            @(posedge clk);
        end

        // Write DMA ADDR HI
        csr_s_chipselect = '1;
        csr_s_byteenable = 'h0F00;
        csr_s_read       = '0;
        csr_s_write      = '1;
        csr_s_writedata  = (i << 64) << 28;
        csr_s_address    = current_struct;
        @(posedge clk);
        while (csr_s_waitrequest) begin
            @(posedge clk);
        end

        csr_s_chipselect = '1;
        csr_s_byteenable = 'h000F;
        csr_s_read       = '1;
        csr_s_write      = '0;
        csr_s_writedata  = '0;
        csr_s_address    = current_struct;
        @(posedge clk);
        csr_s_read       = '0;
        while (!csr_s_readdatavalid) begin
            @(posedge clk);
        end
        current_struct = csr_s_readdata[31:0];
        $write("DMA address for channel %u: 0x%x; ", 4'(i), u_dma_testenv_top.u_avmm_dma_top.dma_addr[i]);
        $display("Next address: 0x%x;", current_struct);
    end

    for (int i = 0; i < DMA_CHANNEL_COUNT; i++) begin
        // Write MSIX
        msix_s_chipselect = '1;
        msix_s_byteenable = 'hFFFF;
        msix_s_read       = '0;
        msix_s_write      = '1;
        msix_s_writedata  = {32'('0), 32'('hDEADBEE0 + i), 32'('hFEE00000), 32'(i*4)}; // ctrl, data, addr_hi, addr_lo
        msix_s_address    = i * 'h10;
        @(posedge clk);
        while (csr_s_waitrequest) begin
            @(posedge clk);
        end
        @(posedge clk);
        $write("MSI-X for DMA channel %u: mask 0x%x, data 0x%x, addr 0x%x;\n",
                4'(i), u_dma_testenv_top.u_avmm_dma_top.dma_msix_mask[i][0], u_dma_testenv_top.u_avmm_dma_top.dma_msix_data[i], u_dma_testenv_top.u_avmm_dma_top.dma_msix_addrs[i]);
    end

    for (int i = DMA_CHANNEL_COUNT; i < DMA_CHANNEL_COUNT*2; i++) begin
        int index;
        index = i - DMA_CHANNEL_COUNT;
        // Write MSIX
        msix_s_chipselect = '1;
        msix_s_byteenable = 'hFFFF;
        msix_s_read       = '0;
        msix_s_write      = '1;
        msix_s_writedata  = {32'(0), 32'('hDEADBEE0 + i), 32'('hFEE00000), 32'(i*4)}; // ctrl, data, addr_hi, addr_lo
        msix_s_address    = i * 'h10;
        @(posedge clk);
        while (csr_s_waitrequest) begin
            @(posedge clk);
        end
        @(posedge clk);
        $write("MSI-X for user %u: mask 0x%x, data 0x%x, addr 0x%x;\n",
                4'(index), u_dma_testenv_top.u_avmm_dma_top.user_msix_mask[index][0], u_dma_testenv_top.u_avmm_dma_top.user_msix_data[index], u_dma_testenv_top.u_avmm_dma_top.user_msix_addrs[index]);
    end

    for (int iter = 0; iter < 2; iter++) begin
        // Reset stuff
        env_csr_s_chipselect = '1;
        env_csr_s_byteenable = 'h0F00;
        env_csr_s_writedata  = '1;
        env_csr_s_write      = '1;
        env_csr_s_address    = '0;
        @(posedge clk);
        while (dec_s_waitrequest) begin
            @(posedge clk);
        end
        env_csr_s_chipselect = '1;
        env_csr_s_byteenable = 'h0F00;
        env_csr_s_writedata  = '1;
        env_csr_s_write      = '0;
        env_csr_s_address    = '0;
        @(posedge clk);
        while (dec_s_waitrequest) begin
            @(posedge clk);
        end
        env_csr_s_write      = '0;

        // DMA action
        for (int i = 0; i < DMA_CHANNEL_COUNT; i++) begin
            dec_s_chipselect = '1;
            dec_s_byteenable = 'hFF00;
            dec_s_read       = '0;
            dec_s_write      = '1;
            dec_s_writedata  = (((22'(queue_sizes[i]/2*16)) << 32) | 22'('h100)) << 64;
            dec_s_address    = i << 4;
            @(posedge clk);
            while (dec_s_waitrequest) begin
                @(posedge clk);
            end
            dec_s_write      = '0;
        end
        repeat (10000) @(posedge clk);

        for (int i = 0; i < DMA_CHANNEL_COUNT; i++) begin
            dec_s_chipselect = '1;
            dec_s_byteenable = 'h00FF;
            dec_s_read       = '0;
            dec_s_write      = '1;
            dec_s_writedata  = ((22'(DMA_PMU_READ_BYTES)) << 32) | 22'('h0);
            dec_s_address    = i << 4;
            @(posedge clk);
            while (dec_s_waitrequest) begin
                @(posedge clk);
            end
            dec_s_write      = '0;
        end
        repeat (1000) @(posedge clk);
        
        start_validate = 1;
        repeat (4) @(posedge clk);
        start_validate = 0;

        while (finish_validate == 0) begin
            @(posedge clk);
        end
    end

    test_done = '1;
    
end

generate
    for (genvar i = 0; i < DMA_CHANNEL_COUNT; i++) begin
        logic [DMA_DATA_WIDTH-1:0] current_tx_writedata;
        logic [DMA_DATA_WIDTH-1:0] expected;
        int current_slice;
        int current_router;
        
        initial begin
            for (int iter = 0; iter < 2; iter++) begin
                current_slice = 0;
                current_router = 0;
                finish_validate = 0;

                while (start_validate == 0) begin
                    @(posedge clk);
                end

                assert (log_queues[i].tx_writedata_queue.size() == DMA_PMU_READ_BYTES / (DMA_DATA_WIDTH/8))
                else begin
                    $error("%d Channel %d no writedata from DMA: expected %d, got %d", 22'($time), i, DMA_PMU_READ_BYTES / (DMA_DATA_WIDTH/8), log_queues[i].tx_writedata_queue.size());
                    $finish();
                end

                while (log_queues[i].tx_writedata_queue.size()) begin
                    current_tx_writedata = log_queues[i].tx_writedata_queue.pop_front();

                    expected = (multiply_pmu_dumps[i].pmu_dump[current_router][current_slice +: DMA_DATA_WIDTH]);
                    assert (current_tx_writedata == expected)
                    else   begin
                        $error("%d Wrong PMU data router %d slice %d:%d through DMA channel %d: expected %h, got %h",
                                22'($time), current_router, current_slice+DMA_DATA_WIDTH, current_slice, i, expected, current_tx_writedata);
                        $finish();
                    end
                    $display("%d Real PMU data router %d slice %d:%d through DMA channel %d: expected %h, got %h",
                            22'($time), current_router, current_slice+DMA_DATA_WIDTH, current_slice, i, expected, current_tx_writedata);

                    current_router = (current_slice + DMA_DATA_WIDTH >= PMU_DATA_WIDTH*PMU_METRIC_COUNT) ? current_router + 1 : current_router;
                    current_slice = (current_slice + DMA_DATA_WIDTH >= PMU_DATA_WIDTH*PMU_METRIC_COUNT) ? '0 : current_slice + DMA_DATA_WIDTH;
                end

                finish_validate = 1;
                repeat (5) @(posedge clk);
            end
        end
    end
endgenerate

endmodule