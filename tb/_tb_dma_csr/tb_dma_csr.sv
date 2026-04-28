module tb_dma_csr;

parameter     DMA_CHANNEL_COUNT                     = 16         ;

parameter     BAR_DATA_WIDTH                        = 128        ;
parameter     BAR_ADDR_WIDTH                        = 12         ;

parameter int DMA_WORD_BYTES    [DMA_CHANNEL_COUNT] = '{16{16  }};
parameter int DMA_WQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{1024}};
parameter int DMA_RQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{1024}};
parameter int DMA_TQ_DEPTH      [DMA_CHANNEL_COUNT] = '{16{16  }};

parameter int MAX_WQ_DEPTH                          = 1024       ;
parameter int MAX_RQ_DEPTH                          = 1024       ;
parameter int MAX_TQ_DEPTH                          = 16         ;

parameter     BAR_DATA_BYTES                        = BAR_DATA_WIDTH / 8  ;
parameter     DMA_WQ_ADDR_WIDTH                     = $clog2(MAX_WQ_DEPTH);
parameter     DMA_RQ_ADDR_WIDTH                     = $clog2(MAX_RQ_DEPTH);
parameter     DMA_TQ_ADDR_WIDTH                     = $clog2(MAX_TQ_DEPTH);


parameter int BYTEENABLES[16] = '{
    'h0000, 'h000F, 'h00F0, 'h00FF,
    'h0F00, 'h0F0F, 'h0FF0, 'h0FFF,
    'hF000, 'hF00F, 'hF0F0, 'hF0FF,
    'hFF00, 'hFF0F, 'hFFF0, 'hFFFF
};


logic test_done;

logic                       clk                                     ;
logic                       rst_n                                   ;
logic                       avmm_s_chipselect                       ;
logic [BAR_DATA_BYTES-1:0]  avmm_s_byteenable                       ;
logic [BAR_DATA_WIDTH-1:0]  avmm_s_readdata                         ;
logic [BAR_DATA_WIDTH-1:0]  avmm_s_writedata                        ;
logic                       avmm_s_read                             ;
logic                       avmm_s_write                            ;
logic                       avmm_s_readdatavalid                    ;
logic                       avmm_s_waitrequest                      ;
logic [BAR_ADDR_WIDTH-1:0]  avmm_s_address                          ;
logic [64:0]                dma_addr_o           [DMA_CHANNEL_COUNT];
logic [DMA_WQ_ADDR_WIDTH:0] wdata_fifo_count_i   [DMA_CHANNEL_COUNT];
logic [DMA_RQ_ADDR_WIDTH:0] rdata_fifo_free_i    [DMA_CHANNEL_COUNT];
logic [DMA_TQ_ADDR_WIDTH:0] task_fifo_count_i                       ;

logic [15:0] next_struct;
logic [15:0] curr_struct;

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

    .avmm_s_chipselect    (avmm_s_chipselect   ),
    .avmm_s_byteenable    (avmm_s_byteenable   ),
    .avmm_s_readdata      (avmm_s_readdata     ),
    .avmm_s_writedata     (avmm_s_writedata    ),
    .avmm_s_read          (avmm_s_read         ),
    .avmm_s_write         (avmm_s_write        ),
    .avmm_s_readdatavalid (avmm_s_readdatavalid),
    .avmm_s_waitrequest   (avmm_s_waitrequest  ),
    .avmm_s_address       (avmm_s_address      ),

    .dma_addr_o           (dma_addr_o          ),

    .wdata_fifo_count_i   (wdata_fifo_count_i  ),
    .rdata_fifo_free_i    (rdata_fifo_free_i   ),
    .task_fifo_count_i    (task_fifo_count_i   )
);


always #10 clk = ~clk;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wdata_fifo_count_i <= '{default:'0};
        rdata_fifo_free_i  <= '{default:'0};
        task_fifo_count_i  <= '0;
    end
    else begin
        for (int i = 0; i < DMA_CHANNEL_COUNT; i++) begin
            wdata_fifo_count_i[i] <= $urandom();
            rdata_fifo_free_i[i]  <= $urandom();
        end
        task_fifo_count_i <= $urandom();
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
    // Dummy writes
    avmm_s_chipselect    = '1;
    avmm_s_byteenable    = 'h000F;
    avmm_s_read          = '0;
    avmm_s_write         = '1;
    avmm_s_writedata     = '0;
    avmm_s_address       = '0;
    @(posedge clk);
    while (avmm_s_waitrequest) begin
        @(posedge clk);
    end
    
    avmm_s_chipselect    = '1;
    avmm_s_byteenable    = 'h00F0;
    avmm_s_read          = '0;
    avmm_s_write         = '1;
    avmm_s_writedata     = '0;
    avmm_s_address       = '0;
    @(posedge clk);
    while (avmm_s_waitrequest) begin
        @(posedge clk);
    end
    avmm_s_write         = '0;


    // Reads
    avmm_s_chipselect    = '1;
    avmm_s_byteenable    = 'h000F;
    avmm_s_read          = '1;
    avmm_s_write         = '0;
    avmm_s_writedata     = '0;
    avmm_s_address       = '0;
    @(posedge clk);
    avmm_s_read          = '0;
    while (!avmm_s_readdatavalid) begin
        @(posedge clk);
    end
    next_struct = avmm_s_readdata[31:16];
    $display("DMA channels: %d;", avmm_s_readdata[15:0]);
    $display("Address of struct 0: 0x%x;", avmm_s_readdata[31:16]);
    
    avmm_s_chipselect    = '1;
    avmm_s_byteenable    = 'h00F0;
    avmm_s_read          = '1;
    avmm_s_write         = '0;
    avmm_s_writedata     = '0;
    avmm_s_address       = '0;
    @(posedge clk);
    avmm_s_read          = '0;
    while (!avmm_s_readdatavalid) begin
        @(posedge clk);
    end
    $display("Task FIFO count: 0x%x;", avmm_s_readdata[63:32]);
    
    // Test pointers
    for (int i = 0; i < 16; i++) begin
        // Write
        avmm_s_chipselect    = '1;
        avmm_s_byteenable    = 'h000F;
        avmm_s_read          = '0;
        avmm_s_write         = '1;
        avmm_s_writedata     = $urandom();
        avmm_s_address       = next_struct;
        @(posedge clk);
        while (avmm_s_waitrequest) begin
            @(posedge clk);
        end
        $write("Wrote: 0x%x; ", avmm_s_writedata[31:0]);

        avmm_s_chipselect    = '1;
        avmm_s_byteenable    = 'h000F;
        avmm_s_read          = '1;
        avmm_s_write         = '0;
        avmm_s_writedata     = '0;
        avmm_s_address       = next_struct;
        @(posedge clk);
        avmm_s_read          = '0;
        while (!avmm_s_readdatavalid) begin
            @(posedge clk);
        end
        next_struct = avmm_s_readdata[31:0];
        $display("Next address: 0x%x;", next_struct);
    end
    
    // Write read
    // Reads
    avmm_s_chipselect    = '1;
    avmm_s_byteenable    = 'h000F;
    avmm_s_read          = '1;
    avmm_s_write         = '0;
    avmm_s_writedata     = '0;
    avmm_s_address       = '0;
    @(posedge clk);
    avmm_s_read          = '0;
    while (!avmm_s_readdatavalid) begin
        @(posedge clk);
    end
    curr_struct = avmm_s_readdata[31:16];
    $display("Address of struct 0: 0x%x;", curr_struct);
    
    for (int i = 0; i < 16; i++) begin
        // Read pointers
        avmm_s_chipselect    = '1;
        avmm_s_byteenable    = 'h000F;
        avmm_s_read          = '1;
        avmm_s_write         = '0;
        avmm_s_writedata     = '0;
        avmm_s_address       = curr_struct;
        @(posedge clk);
        avmm_s_read          = '0;
        while (!avmm_s_readdatavalid) begin
            @(posedge clk);
        end
        next_struct = avmm_s_readdata[31:0];
        $display("Current struct start address: 0x%x;", curr_struct);

        for (int j = 'h0000; j <= 'h0020; j += 'h4) begin
            // Write
            avmm_s_chipselect    = '1;
            avmm_s_byteenable    = 'hF << (j % 'h10);
            avmm_s_read          = '0;
            avmm_s_write         = '1;
            avmm_s_writedata     = $urandom() <<  (32 * (j/4 % 4));
            avmm_s_address       = (j & 'hFF0) | curr_struct;
            @(posedge clk);
            while (avmm_s_waitrequest) begin
                @(posedge clk);
            end
            $write("Address: 0x%x; Byen: 0x%x; Wrote: 0x%x; ", avmm_s_address, avmm_s_byteenable, 32'(avmm_s_writedata >> (32 * (j/4 % 4))));

            avmm_s_chipselect    = '1;
            avmm_s_byteenable    = 'hF << (j % 'h10);
            avmm_s_read          = '1;
            avmm_s_write         = '0;
            avmm_s_writedata     = '0;
            avmm_s_address       = (j & 'hFF0) | curr_struct;
            @(posedge clk);
            avmm_s_read          = '0;
            while (!avmm_s_readdatavalid) begin
                @(posedge clk);
            end
            $display("Read: 0x%x;", 32'(avmm_s_readdata >> (32 * (j/4 % 4))));
        end
        curr_struct = next_struct;
    end
    
    test_done = '1;

end

endmodule