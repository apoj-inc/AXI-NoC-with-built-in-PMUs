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

logic [DMA_CHANNEL_COUNT-1:0]       out_dma_task_valid_o                     ;
logic [DMA_CHANNEL_COUNT-1:0]       out_dma_task_ready_i                     ;
logic [DMA_BURST_WIDTH-1:0]         out_dma_task_burst_o  [DMA_CHANNEL_COUNT];
logic [DMA_OFFFSET_WIDTH-1:0]       out_dma_task_offset_o [DMA_CHANNEL_COUNT];
logic [DMA_CHANNEL_COUNT-1:0]       out_dma_task_write_o                     ;

logic [DMA_CHANNEL_COUNT-1:0]       task_ready_mask;

logic [21:0] dma_offset;
logic [21:0] dma_bytes ;


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

avmm_dma_task_demux #(
    .DMA_CHANNEL_COUNT (DMA_CHANNEL_COUNT),
    .DMA_OFFFSET_WIDTH (DMA_OFFFSET_WIDTH),
    .DMA_BYTES_WIDTH   (DMA_BYTES_WIDTH  )
) u_avmm_dma_task_demux (
    .clk                   (clk                  ),
    .rst_n                 (rst_n                ),

    .in_dma_task_valid_i   (dma_task_valid_o     ),
    .in_dma_task_ready_o   (dma_task_ready_i     ),
    .in_dma_task_channel_i (dma_task_channel_o   ),
    .in_dma_task_burst_i   (dma_task_burst_o     ),
    .in_dma_task_offset_i  (dma_task_offset_o    ),
    .in_dma_task_write_i   (dma_task_write_o     ),

    .out_dma_task_valid_o  (out_dma_task_valid_o ),
    .out_dma_task_ready_i  (out_dma_task_ready_i ),
    .out_dma_task_burst_o  (out_dma_task_burst_o ),
    .out_dma_task_offset_o (out_dma_task_offset_o),
    .out_dma_task_write_o  (out_dma_task_write_o )
);


always #10 clk = ~clk;

initial begin
    test_done = '0;
    out_dma_task_ready_i = '0;

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
    for (int i = 0; i < DMA_CHANNEL_COUNT; i++) begin
        avmm_s_chipselect    = '1            ;
        avmm_s_byteenable    = BYTEENABLES[i];
        avmm_s_read          = '1            ;
        avmm_s_write         = '0            ;
        avmm_s_writedata     = '0            ;
        std::randomize(avmm_s_address);
        @(posedge clk);
        assert (out_dma_task_valid_o == 0) 
        else   begin
            $error("dma_task_valid_o asserted on avmm read for no reason");
            $finish();
        end

        while (!avmm_s_readdatavalid) begin
            @(posedge clk);
            assert (out_dma_task_valid_o == 0) 
            else   begin
                $error("dma_task_valid_o asserted on avmm read for no reason");
                $finish();
            end
        end
    end

    // Bad writes
    for (int i = 0; i < DMA_CHANNEL_COUNT; i++) begin
        if (BYTEENABLES[i] != 'hFF00 && BYTEENABLES[i] != 'h00FF) begin
            avmm_s_chipselect    = '1            ;
            avmm_s_byteenable    = BYTEENABLES[i];
            avmm_s_read          = '0            ;
            avmm_s_write         = '1            ;
            std::randomize(avmm_s_writedata);
            std::randomize(avmm_s_address  );
            @(posedge clk);
            assert (out_dma_task_valid_o == 0) 
            else   begin
                $error("dma_task_valid_o asserted on avmm write for no reason");
                $finish();
            end

            while (avmm_s_waitrequest) begin
                @(posedge clk);
                assert (out_dma_task_valid_o == 0) 
                else   begin
                    $error("dma_task_valid_o asserted on avmm write for no reason");
                    $finish();
                end
            end
        end
    end

    // Writes to DMA writes
    for (int i = 0; i < DMA_CHANNEL_COUNT; i++) begin
        dma_offset = $urandom();
        dma_bytes  = $urandom();

        avmm_s_chipselect    = '1                                       ;
        avmm_s_byteenable    = 'h00FF                                   ;
        avmm_s_read          = '0                                       ;
        avmm_s_write         = '1                                       ;
        avmm_s_writedata     = (22'(dma_bytes) << 32) | 22'(dma_offset) ;
        avmm_s_address       = i << 4                                   ;
        @(posedge clk);

        while (avmm_s_waitrequest) begin
            @(posedge clk);
        end
        avmm_s_chipselect    = '0;
        avmm_s_write         = '0;
        while (!(out_dma_task_valid_o == (DMA_CHANNEL_COUNT'('1) >> (DMA_CHANNEL_COUNT-(i+1))))) begin
            @(posedge clk);
        end
        assert (out_dma_task_burst_o[i] == (22'(dma_bytes) >> 4)) 
        else   begin
            $error("Wrong write burst at channel %d: expected %h, got %h", i, 22'(dma_bytes) >> 4, out_dma_task_burst_o[i]);
            $finish();
        end
        assert (out_dma_task_offset_o[i] == 22'(dma_offset)) 
        else   begin
            $error("Wrong write offset at channel %d: expected %h, got %h", i, 22'(dma_offset) >> 4, out_dma_task_offset_o[i]);
            $finish();
        end
        assert (out_dma_task_write_o[i] == 1) 
        else   begin
            $error("Wrong write write at channel %d: expected %d, got %d", i, 1, out_dma_task_write_o[i]);
            $finish();
        end
    end

    for (int i = 0; i < 16; i++) begin
        @(posedge clk);
        out_dma_task_ready_i[i] = '1;
        @(posedge clk);
        out_dma_task_ready_i[i] = '0;
        @(posedge clk);
        assert (out_dma_task_valid_o == (DMA_CHANNEL_COUNT'('1) << (i+1))) 
        else   begin
            $error("Failed to deassert write valid at channel %d", i);
            $finish();
        end
    end

    // Writes to DMA reads
    for (int i = 0; i < DMA_CHANNEL_COUNT; i++) begin
        dma_offset = $urandom();
        dma_bytes  = $urandom();

        avmm_s_chipselect    = '1                                               ;
        avmm_s_byteenable    = 'hFF00                                           ;
        avmm_s_read          = '0                                               ;
        avmm_s_write         = '1                                               ;
        avmm_s_writedata     = ((22'(dma_bytes) << 32) | 22'(dma_offset)) << 64 ;
        avmm_s_address       = i << 4                                           ;
        @(posedge clk);

        while (avmm_s_waitrequest) begin
            @(posedge clk);
        end
        avmm_s_chipselect    = '0;
        avmm_s_write         = '0;
        while (!(out_dma_task_valid_o == (DMA_CHANNEL_COUNT'('1) >> (DMA_CHANNEL_COUNT-(i+1))))) begin
            @(posedge clk);
        end
        assert (out_dma_task_burst_o[i] == (22'(dma_bytes) >> 4)) 
        else   begin
            $error("Wrong read burst at channel %d: expected %h, got %h", i, 22'(dma_bytes) >> 4, out_dma_task_burst_o[i]);
            $finish();
        end
        assert (out_dma_task_offset_o[i] == 22'(dma_offset)) 
        else   begin
            $error("Wrong task offset at channel %d: expected %h, got %h", i, 22'(dma_offset) >> 4, out_dma_task_offset_o[i]);
            $finish();
        end
        assert (out_dma_task_write_o[i] == 0) 
        else   begin
            $error("Wrong read write at channel %d: expected %d, got %d", i, 0, out_dma_task_write_o[i]);
            $finish();
        end
    end

    for (int i = 0; i < 16; i++) begin
        @(posedge clk);
        out_dma_task_ready_i[i] = '1;
        @(posedge clk);
        out_dma_task_ready_i[i] = '0;
        @(posedge clk);
        assert (out_dma_task_valid_o == (DMA_CHANNEL_COUNT'('1) << (i+1))) 
        else   begin
            $error("Failed to deassert read valid at channel %d", i);
            $finish();
        end
    end
    
    test_done = '1;
    
    `ifdef QUESTA
        $finish();
    `endif

end

endmodule