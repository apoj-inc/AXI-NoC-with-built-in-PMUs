// Task from DMA to AXI master loader order:
/*  
    AXI_CUMULATIVE_WIDTH ...................................................................... 0
    | channel_num | resp_wait | axi_id | axi_write | axi_addr | axi_len | axi_wdata | axi_wstrb |

    all of the fields are byte-aligned
*/

module dma_task_dispatcher #(
    parameter EXT_FIFO_DATA_WIDTH = 128,

    parameter ROUTERS_COUNT       = 16 ,

    parameter AXI_DATA_WIDTH      = 32 ,
    parameter AXI_ID_W_WIDTH      = 5  ,
    parameter AXI_ID_R_WIDTH      = 5  ,
    parameter AXI_ADDR_WIDTH      = 16 ,

    parameter ROUTERS_COUNT_WIDTH  = (ROUTERS_COUNT == 1) ? 1 : $clog2(ROUTERS_COUNT)                                                                      ,
    parameter AXI_MAX_ID_WIDTH     = (AXI_ID_W_WIDTH > AXI_ID_R_WIDTH) ? AXI_ID_W_WIDTH : AXI_ID_R_WIDTH                                                   ,

    parameter ROUTERS_COUNT_BYTES  = ROUTERS_COUNT_WIDTH / 8 + (ROUTERS_COUNT_WIDTH % 8 != 0)                                                              ,
    parameter AXI_DATA_BYTES       = AXI_DATA_WIDTH      / 8 + (AXI_DATA_WIDTH      % 8 != 0)                                                              ,
    parameter AXI_MAX_ID_BYTES     = AXI_MAX_ID_WIDTH    / 8 + (AXI_MAX_ID_WIDTH    % 8 != 0)                                                              ,
    parameter AXI_ADDR_BYTES       = AXI_ADDR_WIDTH      / 8 + (AXI_ADDR_WIDTH      % 8 != 0)                                                              ,
    parameter AXI_WSTRB_BYTES      = AXI_DATA_BYTES      / 8 + (AXI_DATA_BYTES      % 8 != 0)                                                              ,

    parameter WSTRB_WIDTH_OFFSET   = 0                                                                                                                     ,
    parameter WDATA_WIDTH_OFFSET   = WSTRB_WIDTH_OFFSET + AXI_WSTRB_BYTES*8                                                                                ,
    parameter LEN_WIDTH_OFFSET     = WDATA_WIDTH_OFFSET + AXI_DATA_BYTES*8                                                                                 ,
    parameter ADDR_WIDTH_OFFSET    = LEN_WIDTH_OFFSET   + 8                                                                                                ,
    parameter WRITE_WIDTH_OFFSET   = ADDR_WIDTH_OFFSET  + AXI_ADDR_BYTES*8                                                                                 ,
    parameter ID_WIDTH_OFFSET      = WRITE_WIDTH_OFFSET + 8                                                                                                ,
    parameter RESP_WIDTH_OFFSET    = ID_WIDTH_OFFSET    + AXI_MAX_ID_BYTES*8                                                                               ,
    parameter CHANNEL_WIDTH_OFFSET = RESP_WIDTH_OFFSET  + 8                                                                                                ,

    parameter AXI_CUMULATIVE_WIDTH = (ROUTERS_COUNT_BYTES + 1 + AXI_MAX_ID_BYTES + 1 + AXI_ADDR_BYTES + 1 + AXI_DATA_BYTES + AXI_WSTRB_BYTES) * 8          ,

    parameter WIDTH_RATIO          = AXI_CUMULATIVE_WIDTH / EXT_FIFO_DATA_WIDTH + (AXI_CUMULATIVE_WIDTH % EXT_FIFO_DATA_WIDTH != 0)                        ,
    parameter WIDTH_REMAINDER      = (AXI_CUMULATIVE_WIDTH % EXT_FIFO_DATA_WIDTH == 0) ? EXT_FIFO_DATA_WIDTH : (AXI_CUMULATIVE_WIDTH % EXT_FIFO_DATA_WIDTH),
    parameter WIDTH_RATIO_WIDTH    = (WIDTH_RATIO == 1) ? 1 : $clog2(WIDTH_RATIO)                                                                          
) (
    input  logic                           clk         ,
    input  logic                           rst_n       ,

    input  logic                           dma_valid_i ,
    input  logic [EXT_FIFO_DATA_WIDTH-1:0] dma_data_i  ,

    output logic [ROUTERS_COUNT-1:0]       ld_valid_o  ,
    output logic                           resp_wait_o ,
    output logic [AXI_MAX_ID_WIDTH-1:0]    id_o        ,
    output logic                           write_o     ,
    output logic [AXI_ADDR_WIDTH-1:0]      axaddr_o    ,
    output logic [7:0]                     axlen_o     ,
    output logic [AXI_DATA_WIDTH-1:0]      wdata_o     ,
    output logic [AXI_DATA_BYTES-1:0]      wstrb_o     ,

    output logic                           start_o     
);

    logic [WIDTH_RATIO_WIDTH-1:0]    section_counter;
    logic [AXI_CUMULATIVE_WIDTH-1:0] data_packed    ;

    logic                            ld_valid_bit;

    initial begin
        $display("%d", WRITE_WIDTH_OFFSET);
    end

    always_comb begin
        ld_valid_o  = ld_valid_bit << data_packed[CHANNEL_WIDTH_OFFSET +: ROUTERS_COUNT_WIDTH];
        
        resp_wait_o = data_packed[RESP_WIDTH_OFFSET  +: 1               ];
        id_o        = data_packed[ID_WIDTH_OFFSET    +: AXI_MAX_ID_WIDTH];
        write_o     = data_packed[WRITE_WIDTH_OFFSET +: 1               ];
        axaddr_o    = data_packed[ADDR_WIDTH_OFFSET  +: AXI_ADDR_WIDTH  ];
        axlen_o     = data_packed[LEN_WIDTH_OFFSET   +: 8               ];
        wdata_o     = data_packed[WDATA_WIDTH_OFFSET +: AXI_DATA_WIDTH  ];
        wstrb_o     = data_packed[WSTRB_WIDTH_OFFSET +: AXI_DATA_BYTES  ];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ld_valid_bit <= '0;

            section_counter <= '0;
            data_packed     <= '0;
        end
        else begin
            ld_valid_bit <= '0;
            if (dma_valid_i) begin
                if (section_counter + 1 < WIDTH_RATIO) begin
                    section_counter <= section_counter + 1;
                    data_packed[section_counter*EXT_FIFO_DATA_WIDTH +: EXT_FIFO_DATA_WIDTH] <= dma_data_i;
                end
                else begin
                    section_counter <= 0;
                    data_packed[section_counter*EXT_FIFO_DATA_WIDTH +: WIDTH_REMAINDER] <= dma_data_i[0 +: WIDTH_REMAINDER];
                    ld_valid_bit <= '1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_o <= '0;
        end
        else begin
            start_o <= (&dma_data_i) & dma_valid_i;
        end
    end

endmodule