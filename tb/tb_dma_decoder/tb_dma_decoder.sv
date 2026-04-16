module tb_dma_decoder;

parameter BAR_DATA_WIDTH    = 128;
parameter BAR_ADDR_WIDTH    = 12 ;

parameter DMA_CHANNEL_COUNT = 16 ;
parameter DMA_OFFFSET_WIDTH = 22 ;
parameter DMA_BYTES_WIDTH   = 22 ;

parameter DMA_BURST_WIDTH         = DMA_BYTES_WIDTH - 4      ;
parameter DMA_CHANNEL_COUNT_WIDTH = $clog2(DMA_CHANNEL_COUNT);
parameter BAR_DATA_BYTES          = BAR_DATA_WIDTH / 8       ;


parameter int BYTEENABLES[16] = '{
    'h0000, 'h000F, 'h00F0, 'h00FF,
    'h0F00, 'h0F0F, 'h0FF0, 'h0FFF,
    'hF000, 'hF00F, 'hF0F0, 'hF0FF,
    'hFF00, 'hFF0F, 'hFFF0, 'hFFFF
};


logic                               test_done            ;

logic                               clk                  ;
logic                               rst_n                ;

logic                               avmm_s_chipselect    ;
logic [BAR_DATA_BYTES-1:0]          avmm_s_byteenable    ;
logic [BAR_DATA_WIDTH-1:0]          avmm_s_readdata      ;
logic [BAR_DATA_WIDTH-1:0]          avmm_s_writedata     ;
logic                               avmm_s_read          ;
logic                               avmm_s_write         ;
logic                               avmm_s_readdatavalid ;
logic                               avmm_s_waitrequest   ;
logic [BAR_ADDR_WIDTH-1:0]          avmm_s_address       ;

logic                               dma_task_valid_o     ;
logic                               dma_task_ready_i     ;
logic [DMA_CHANNEL_COUNT_WIDTH-1:0] dma_task_channel_o   ;
logic [DMA_BURST_WIDTH-1:0]         dma_task_burst_o     ;
logic [DMA_OFFFSET_WIDTH-1:0]       dma_task_offset_o    ;
logic                               dma_task_write_o     ;


avmm_dma_decoder #(
    .BAR_DATA_WIDTH    (BAR_DATA_WIDTH    ),
    .BAR_ADDR_WIDTH    (BAR_ADDR_WIDTH    ),

    .DMA_CHANNEL_COUNT (DMA_CHANNEL_COUNT ),
    .DMA_OFFFSET_WIDTH (DMA_OFFFSET_WIDTH ),
    .DMA_BYTES_WIDTH   (DMA_BYTES_WIDTH   )
) u_avmm_dma_decoder (
    .clk                  (clk                 ),
    .rst_n                (rst_n               ),
    
    .avmm_s_chipselect    (avmm_s_chipselect   ),
    .avmm_s_byteenable    (avmm_s_byteenable   ),
    .avmm_s_readdata      (avmm_s_readdata     ),
    .avmm_s_writedata     (avmm_s_writedata    ),
    .avmm_s_read          (avmm_s_read         ),
    .avmm_s_write         (avmm_s_write        ),
    .avmm_s_readdatavalid (avmm_s_readdatavalid),
    .avmm_s_waitrequest   (avmm_s_waitrequest  ),
    .avmm_s_address       (avmm_s_address      ),

    .dma_task_valid_o     (dma_task_valid_o    ),
    .dma_task_ready_i     (dma_task_ready_i    ),
    .dma_task_channel_o   (dma_task_channel_o  ),
    .dma_task_burst_o     (dma_task_burst_o    ),
    .dma_task_offset_o    (dma_task_offset_o   ),
    .dma_task_write_o     (dma_task_write_o    )
);


always #10 clk = ~clk;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dma_task_ready_i <= '0;
    end
    else begin
        dma_task_ready_i <= $urandom();
    end
end

initial begin
    test_done = '0;

    clk = '1;
    rst_n = '0;

    avmm_s_chipselect    = '0;
    avmm_s_byteenable    = '0;
    avmm_s_writedata     = '0;
    avmm_s_read          = '0;
    avmm_s_write         = '0;
    avmm_s_address       = '0;

    #15;
    rst_n = '1;

    @(posedge clk);
    // Reads
    for (int i = 0; i < 16; i++) begin
        avmm_s_chipselect    = '1            ;
        avmm_s_byteenable    = BYTEENABLES[i];
        avmm_s_read          = '1            ;
        avmm_s_write         = '0            ;
        avmm_s_writedata     = '0            ;
        std::randomize(avmm_s_address);
        @(posedge clk);

        while (!avmm_s_readdatavalid) begin
            @(posedge clk);
        end
    end

    // Bad writes
    for (int i = 0; i < 16; i++) begin
        if (BYTEENABLES[i] != 'hFF00 && BYTEENABLES[i] != 'h00FF) begin
            avmm_s_chipselect    = '1            ;
            avmm_s_byteenable    = BYTEENABLES[i];
            avmm_s_read          = '0            ;
            avmm_s_write         = '1            ;
            std::randomize(avmm_s_writedata);
            std::randomize(avmm_s_address  );
            @(posedge clk);

            while (avmm_s_waitrequest) begin
                $display(i);
                @(posedge clk);
            end
        end
    end

    // Writes to DMA writes
    for (int i = 0; i < 16; i++) begin
        avmm_s_chipselect    = '1                                       ;
        avmm_s_byteenable    = 'h00FF                                   ;
        avmm_s_read          = '0                                       ;
        avmm_s_write         = '1                                       ;
        avmm_s_writedata     = (22'($urandom()) << 32) | 22'($urandom());
        avmm_s_address       = i << 4                                   ;
        @(posedge clk);

        while (avmm_s_waitrequest) begin
            @(posedge clk);
        end
    end

    // Writes to DMA reads
    for (int i = 0; i < 16; i++) begin
        avmm_s_chipselect    = '1                                               ;
        avmm_s_byteenable    = 'hFF00                                           ;
        avmm_s_read          = '0                                               ;
        avmm_s_write         = '1                                               ;
        avmm_s_writedata     = ((22'($urandom()) << 32) | 22'($urandom())) << 64;
        avmm_s_address       = i << 4                                           ;
        @(posedge clk);

        while (avmm_s_waitrequest) begin
            @(posedge clk);
        end
    end

    
    test_done = '1;

end

endmodule