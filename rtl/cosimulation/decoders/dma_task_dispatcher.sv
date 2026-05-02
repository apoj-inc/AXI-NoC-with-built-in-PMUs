module dma_task_dispatcher #(
    parameter DMA_DATA_WIDTH = 128,

    parameter AXI_DATA_WIDTH = 32 ,
    parameter AXI_ID_W_WIDTH = 5  ,
    parameter AXI_ID_R_WIDTH = 5  ,
    parameter AXI_ADDR_WIDTH = 16 ,

    parameter ROUTERS_COUNT  = 16 ,

    parameter ROUTERS_COUNT_WIDTH  = (ROUTERS_COUNT == 1) ? 1 : $clog2(ROUTERS_COUNT)                                                       ,
    parameter AXI_DATA_BYTES       = AXI_DATA_WIDTH / 8                                                                                     ,
    parameter AXI_MAX_ID_WIDTH     = (AXI_ID_W_WIDTH > AXI_ID_R_WIDTH) ? AXI_ID_W_WIDTH : AXI_ID_R_WIDTH                                    ,
    parameter AXI_CUMULATIVE_WIDTH = 1 + AXI_MAX_ID_WIDTH + 1 + AXI_ADDR_WIDTH + 8 + AXI_DATA_WIDTH + AXI_DATA_BYTES + ROUTERS_COUNT_WIDTH  ,
    parameter WIDTH_RATIO          = AXI_CUMULATIVE_WIDTH / DMA_DATA_WIDTH + (AXI_CUMULATIVE_WIDTH % DMA_DATA_WIDTH != 0)                   ,
    parameter WIDTH_REMAINDER      = (AXI_CUMULATIVE_WIDTH % DMA_DATA_WIDTH == 0) ? DMA_DATA_WIDTH : (AXI_CUMULATIVE_WIDTH % DMA_DATA_WIDTH),
    parameter WIDTH_RATIO_WIDTH    = (WIDTH_RATIO == 1) ? 1 : $clog2(WIDTH_RATIO)                                                           
) (
    input  logic                        clk         ,
    input  logic                        rst_n       ,

    input  logic                        dma_valid_i ,
    input  logic [DMA_DATA_WIDTH-1:0]   dma_data_i  ,

    output logic [ROUTERS_COUNT-1:0]    ld_valid_o  ,
    output logic                        resp_wait_o ,
    output logic [AXI_MAX_ID_WIDTH-1:0] id_o        ,
    output logic                        write_o     ,
    output logic [AXI_ADDR_WIDTH-1:0]   axaddr_o    ,
    output logic [7:0]                  axlen_o     ,
    output logic [AXI_DATA_WIDTH-1:0]   wdata_o     ,
    output logic [AXI_DATA_BYTES-1:0]   wstrb_o     
);

    logic [WIDTH_RATIO_WIDTH-1:0]    section_counter;
    logic [AXI_CUMULATIVE_WIDTH-1:0] data_packed    ;

    logic [7:0] 

    assign {resp_wait_o, id_o, write_o, axaddr_o, axlen_o, wdata_o, wstrb_o} = data_packed;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ld_valid_o <= '0;

            section_counter <= '0;
            data_packed     <= '0;
        end
        else begin
            ld_valid_o <= '0;
            if (dma_valid_i) begin
                if (section_counter + 1 < WIDTH_RATIO) begin
                    section_counter <= section_counter + 1;
                    data_packed[section_counter*DMA_DATA_WIDTH +: DMA_DATA_WIDTH] <= dma_data_i[ROUTERS_COUNT_WIDTH +: DMA_DATA_WIDTH];
                end
                else begin
                    section_counter <= 0;
                    data_packed[section_counter*DMA_DATA_WIDTH +: DMA_DATA_WIDTH] <= dma_data_i[ROUTERS_COUNT_WIDTH +: DMA_DATA_WIDTH];
                    ld_valid_o <= '1 << dma_data_i[DMA_DATA_WIDTH - ROUTERS_COUNT_WIDTH - 1 +: ROUTERS_COUNT_WIDTH];
                end
            end
        end
    end

endmodule