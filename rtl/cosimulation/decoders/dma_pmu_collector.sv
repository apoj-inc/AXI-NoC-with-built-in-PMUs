module dma_pmu_collector #(
    parameter PMU_METRIC_COUNT = 19 ,
    parameter PMU_DATA_WIDTH   = 32 ,

    parameter ROUTERS_COUNT    = 16 ,

    parameter DMA_DATA_WIDTH   = 128,

    parameter ROUTERS_COUNT_WIDTH  = (ROUTERS_COUNT == 1) ? 1 : $clog2(ROUTERS_COUNT)    ,
    parameter PMU_ADDR_WIDTH       = PMU_METRIC_COUNT == 1 ? 1 : $clog2(PMU_METRIC_COUNT)
) (
    input  logic                      clk                       ,
    input  logic                      rst_n                     ,

    input  logic [PMU_ADDR_WIDTH-1:0] pmu_addr_o                ,
    output logic [PMU_DATA_WIDTH-1:0] pmu_data_i [ROUTERS_COUNT],

    input  logic [ROUTERS_COUNT-1:0]  ld_idle_i                 ,

    output logic                      dma_valid_o               ,
    input  logic                      dma_ready_i               ,
    output logic [DMA_DATA_WIDTH-1:0] dma_data_o                
);

    logic [ROUTERS_COUNT-1:0] ld_idle_pending, ld_idle_pending_clear;
    logic [ROUTERS_COUNT_WIDTH-1:0] current_channel;

    // posedge detector
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ld_idle_pending <= '0;
        end        
        else begin
            ld_idle_pending <= (ld_idle_pending | (~ld_idle_pending & ld_idle_i)) & !ld_idle_pending_clear;
        end
    end

    // data collector
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pmu_addr_o <= '0;

            current_channel <= '0;
            ld_idle_pending_clear <= '0;

            dma_valid_o <= '0;
            dma_data_o  <= '0;
        end
        else begin
            if (dma_valid_o && dma_ready_i) begin
                pmu_addr_o <= ((pmu_addr_o + 1) < PMU_METRIC_COUNT) ? (pmu_addr_o + 1) : '0;
            end

            ld_idle_pending_clear <= '0;
            if (dma_valid_o && dma_ready_i && (pmu_addr_o == (PMU_METRIC_COUNT-1))) begin
                current_channel <= ((current_channel + 1) < ROUTERS_COUNT) ? (current_channel + 1) : '0;
                ld_idle_pending_clear[current_channel] <= '1;
            end

            if (ld_idle_pending[current_channel]) begin
                if (dma_valid_o && dma_ready_i && (pmu_addr_o == (PMU_METRIC_COUNT-1))) begin
                    dma_valid_o <= '0;
                end
                else begin
                    dma_valid_o <= '1;
                end
            end

            dma_data_o  <= pmu_data_i[current_channel];
        end
    end
    
endmodule