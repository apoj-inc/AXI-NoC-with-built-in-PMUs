`include "axi_defines.svh"

module axi_testenv #(
    parameter ROUTERS_COUNT       = 16 ,

    parameter AXI_DATA_WIDTH      = 32 ,
    parameter AXI_ADDR_WIDTH      = 16 ,
    parameter AXI_ID_W_WIDTH      = 5  ,
    parameter AXI_ID_R_WIDTH      = 5  ,

    parameter EXT_FIFO_DATA_WIDTH = 128,

    parameter AXI_LD_FIFO_DEPTH   = 64 ,

    parameter PMU_METRIC_COUNT    = 19 ,
    parameter PMU_DATA_WIDTH      = 32 ,

    parameter AXI_DATA_BYTES   = AXI_DATA_WIDTH / 8                                                 ,
    parameter AXI_MAX_ID_WIDTH = (AXI_ID_W_WIDTH > AXI_ID_R_WIDTH) ? AXI_ID_W_WIDTH : AXI_ID_R_WIDTH,
    parameter PMU_ADDR_WIDTH   = PMU_METRIC_COUNT == 1 ? 1 : $clog2(PMU_METRIC_COUNT)               
) (
    input  logic                           clk_in                         ,
    input  logic                           rst_n_in                       ,

    input  logic [EXT_FIFO_DATA_WIDTH-1:0] command_data_i                 ,
    input  logic                           command_valid_i                ,
    output logic                           command_ready_o                ,

    output logic [EXT_FIFO_DATA_WIDTH-1:0] pmu_data_o                     ,
    output logic                           pmu_valid_o                    ,
    input  logic                           pmu_ready_i                    ,

    input  logic                           clk_axi                        ,
    input  logic                           rst_n_axi                      ,

    output logic [ROUTERS_COUNT-1:0]       ld_idle_o                      ,
    output logic [AXI_DATA_WIDTH-1:0]      ld_rdata_o      [ROUTERS_COUNT],

    axi_if.m                               m_axi_if_o      [ROUTERS_COUNT]                           
);

    logic [ROUTERS_COUNT-1:0]    ld_valid  ;
    logic                        resp_wait ;
    logic [AXI_MAX_ID_WIDTH-1:0] id        ;
    logic                        write     ;
    logic [AXI_ADDR_WIDTH-1:0]   axaddr    ;
    logic [7:0]                  axlen     ;
    logic [AXI_DATA_WIDTH-1:0]   wdata     ;
    logic [AXI_DATA_BYTES-1:0]   wstrb     ;
    
    logic start, start_resynced, start_waiter;

    logic [ROUTERS_COUNT-1:0] ld_idle, ld_idle_resynced;

    logic [PMU_ADDR_WIDTH-1:0] pmu_addr                ;
    logic [PMU_DATA_WIDTH-1:0] pmu_data [ROUTERS_COUNT];

    
    logic [EXT_FIFO_DATA_WIDTH-1:0] pmu_resync_fifo_data ;
    logic                           pmu_resync_fifo_valid;
    logic                           pmu_resync_fifo_ready;


    assign ld_idle_o = ld_idle_resynced;
    assign command_ready_o = '1;


    dma_task_dispatcher #(
        .EXT_FIFO_DATA_WIDTH (EXT_FIFO_DATA_WIDTH),

        .ROUTERS_COUNT       (ROUTERS_COUNT      ),

        .AXI_DATA_WIDTH      (AXI_DATA_WIDTH     ),
        .AXI_ID_W_WIDTH      (AXI_ID_W_WIDTH     ),
        .AXI_ID_R_WIDTH      (AXI_ID_R_WIDTH     ),
        .AXI_ADDR_WIDTH      (AXI_ADDR_WIDTH     )
    ) u_dma_task_dispatcher (
        .clk         (clk_in              ),
        .rst_n       (rst_n_in            ),

        .dma_valid_i (command_valid_i),
        .dma_data_i  (command_data_i ),

        .ld_valid_o  (ld_valid            ),
        .resp_wait_o (resp_wait           ),
        .id_o        (id                  ),
        .write_o     (write               ),
        .axaddr_o    (axaddr              ),
        .axlen_o     (axlen               ),
        .wdata_o     (wdata               ),
        .wstrb_o     (wstrb               ),

        .start_o     (start               )
    );

    cdc_stream_afifo #(
        .DATA_WIDTH (1),
        .ADDR_WIDTH (2)
    ) u_cdc_stream_afifo_start_resync (
        .clk_wr   (clk_in            ),
        .rst_n_wr (rst_n_in          ),

        .data_i   (start_waiter      ),
        .valid_i  ('1                ),
        .ready_o  (start_resync_ready),
        .free_o   (                  ),

        .clk_rd   (clk_axi           ),
        .rst_n_rd (rst_n_axi         ),

        .data_o   (start_resynced    ),
        .valid_o  (                  ),
        .ready_i  ('1                ),
        .count_o  (                  )
    );

    always @(posedge clk_in or negedge rst_n_in) begin
        if (!rst_n_in) begin
            start_waiter <= '0;
        end
        else begin
            if (start) begin
                start_waiter <= '1;
            end
            if (start_waiter && start_resync_ready) begin
                start_waiter <= '0;
            end
        end
    end

    dma_pmu_collector #(
        .PMU_METRIC_COUNT    (PMU_METRIC_COUNT   ),
        .PMU_DATA_WIDTH      (PMU_DATA_WIDTH     ),

        .ROUTERS_COUNT       (ROUTERS_COUNT      ),

        .EXT_FIFO_DATA_WIDTH (EXT_FIFO_DATA_WIDTH)
    ) u_dma_pmu_collector (
        .clk         (clk_axi  ),
        .rst_n       (rst_n_axi),

        .pmu_addr_o  (pmu_addr ),
        .pmu_data_i  (pmu_data ),

        .ld_idle_i   (ld_idle  ),

        .dma_valid_o (pmu_resync_fifo_valid),
        .dma_ready_i (pmu_resync_fifo_ready),
        .dma_data_o  (pmu_resync_fifo_data )
    );
    
    cdc_stream_afifo #(
        .DATA_WIDTH (EXT_FIFO_DATA_WIDTH),
        .ADDR_WIDTH (2                  )
    ) u_cdc_stream_afifo_pmu_resync (
        .clk_wr   (clk_axi              ),
        .rst_n_wr (rst_n_axi            ),

        .data_i   (pmu_resync_fifo_data ),
        .valid_i  (pmu_resync_fifo_valid),
        .ready_o  (pmu_resync_fifo_ready),
        .free_o   (                     ),

        .clk_rd   (clk_in               ),
        .rst_n_rd (rst_n_in             ),

        .data_o   (pmu_data_o      ),
        .valid_o  (pmu_valid_o     ),
        .ready_i  (pmu_ready_i     ),
        .count_o  (                     )
    );

    generate
        genvar i;

        for (i = 0; i < ROUTERS_COUNT; i++) begin : pmus_and_generators
            logic [AXI_DATA_WIDTH-1:0] ld_rdata, ld_rdata_resynced;
            
            axi_if #(
                .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
                .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
                .AXI_ID_W_WIDTH (AXI_ID_W_WIDTH),
                .AXI_ID_R_WIDTH (AXI_ID_R_WIDTH)
            ) u_axi_if_monitor();

            `AXI_INTERFACE2INTERFACE_MONITOR(m_axi_if_o[i], u_axi_if_monitor)

            assign ld_rdata_o[i] = ld_rdata_resynced;

            sync_ff #(
                .FF3        (1), // if 0 - 2FF used, if 1 - 3FF used
                .DATA_WIDTH (1 + AXI_DATA_WIDTH)
            ) u_sync_ff_from_ld (
                .data_i   ({ld_idle[i]         , ld_rdata         }),

                .clk_rd   (clk_in                                  ),
                .rst_n_rd (rst_n_in                                ),
                .data_o   ({ld_idle_resynced[i], ld_rdata_resynced})
            );

            axi_master_loader #(
                .AXI_DATA_WIDTH (AXI_DATA_WIDTH   ),
                .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH   ),
                .AXI_ID_W_WIDTH (AXI_ID_W_WIDTH   ),
                .AXI_ID_R_WIDTH (AXI_ID_R_WIDTH   ),

                .FIFO_DEPTH     (AXI_LD_FIFO_DEPTH),
                .LOADER_ID      (i                )
            ) u_axi_master_loader (
                .clk_in      (clk_in         ),
                .rst_n_in    (rst_n_in       ),

                .resp_wait_i (resp_wait      ),
                .id_i        (id             ),
                .write_i     (write          ),
                .axaddr_i    (axaddr         ),
                .axlen_i     (axlen          ),
                .wdata_i     (wdata          ),
                .wstrb_i     (wstrb          ),
                .fifo_push_i (ld_valid[i]    ),

                .clk_axi     (clk_axi        ),
                .rst_n_axi   (rst_n_axi      ),

                .start_i     (start_resynced ),
                .idle_o      (ld_idle[i]     ),

                .rdata_o     (ld_rdata       ),

                .m_axi_if_o  (m_axi_if_o[i]  )
            );

            axi_pmu #(
                .AXI_DATA_WIDTH   (AXI_DATA_WIDTH  ),
                .AXI_ADDR_WIDTH   (AXI_ADDR_WIDTH  ),
                .AXI_ID_R_WIDTH   (AXI_ID_R_WIDTH  ),
                .AXI_ID_W_WIDTH   (AXI_ID_W_WIDTH  ),

                .PMU_METRIC_COUNT (PMU_METRIC_COUNT),
                .PMU_DATA_WIDTH   (PMU_DATA_WIDTH  )
            ) u_axi_pmu (
                .aclk      (clk_axi         ),
                .aresetn   (rst_n_axi       ),
                .enable    (!ld_idle[i]     ),

                .mon_axi_i (u_axi_if_monitor),

                .addr_i    (pmu_addr        ),
                .data_o    (pmu_data[i]     )
            );
        end
    endgenerate
    
endmodule