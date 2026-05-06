module avmm_dma_msix_table #(
    parameter BAR_DATA_WIDTH  = 128  ,
    parameter BAR_ADDR_WIDTH  = 1    ,
    parameter DMA_MSIX_COUNT  = 16   ,
    parameter USER_MSIX_COUNT = 16   ,

    parameter TOTAL_MSIX_COUNT = DMA_MSIX_COUNT + USER_MSIX_COUNT                    ,
    parameter PBA_OFFSET       = 'h300                                               , // don't change it pls
    parameter BAR_DATA_BYTES   = BAR_DATA_WIDTH / 8                                  ,
    parameter PBA_COUNT        = TOTAL_MSIX_COUNT / 64 + (TOTAL_MSIX_COUNT % 64 != 0),
    parameter PBA_PAIRS        = PBA_COUNT / 2 + (PBA_COUNT % 2 != 0)                
) (
    input  logic                       clk                                   ,
    input  logic                       rst_n                                 ,

    input  logic                       avmm_s_chipselect                     ,
    input  logic [BAR_DATA_BYTES-1:0]  avmm_s_byteenable                     ,
    output logic [BAR_DATA_WIDTH-1:0]  avmm_s_readdata                       ,
    input  logic [BAR_DATA_WIDTH-1:0]  avmm_s_writedata                      ,
    input  logic                       avmm_s_read                           ,
    input  logic                       avmm_s_write                          ,
    output logic                       avmm_s_readdatavalid                  ,
    output logic                       avmm_s_waitrequest                    ,
    input  logic [BAR_ADDR_WIDTH-1:0]  avmm_s_address                        ,

    output logic [31:0]                dma_msix_mask_o      [DMA_MSIX_COUNT] ,
    output logic [31:0]                dma_msix_data_o      [DMA_MSIX_COUNT] ,
    output logic [63:0]                dma_msix_addrs_o     [DMA_MSIX_COUNT] ,

    output logic [31:0]                user_msix_mask_o     [USER_MSIX_COUNT],
    output logic [31:0]                user_msix_data_o     [USER_MSIX_COUNT],
    output logic [63:0]                user_msix_addrs_o    [USER_MSIX_COUNT],
    
    input  logic [127:0]               pba_control_i        [PBA_COUNT]      ,
    output logic [127:0]               pba_status_o         [PBA_COUNT]      
);

    typedef struct packed {
        logic [31:0] control   ;
        logic [31:0] data      ;
        logic [31:0] address_hi;
        logic [31:0] address_lo;
    } msix_entry_t;

    logic [BAR_DATA_BYTES/4 - 1:0]         wordenable                       ;
    logic [BAR_DATA_WIDTH-1:0]             dma_msix_reads  [DMA_MSIX_COUNT] ;
    logic [BAR_DATA_WIDTH-1:0]             user_msix_reads [USER_MSIX_COUNT];
    logic [BAR_DATA_WIDTH-1:0]             pba_reads       [PBA_PAIRS]      ;
    logic [TOTAL_MSIX_COUNT+PBA_PAIRS-1:0] rw_enable                        ;

    // Avalon-MM signals
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            avmm_s_readdatavalid <= '0;
            avmm_s_waitrequest <= '1;
        end
        else begin
            avmm_s_readdatavalid <= avmm_s_chipselect & avmm_s_read;
            avmm_s_waitrequest <= '0;
        end
    end

    // Read collector
    always_comb begin
        avmm_s_readdata = '0;
        for (int i = 0; i < DMA_MSIX_COUNT; i++) begin
            avmm_s_readdata |= dma_msix_reads[i];
        end
        for (int i = 0; i < USER_MSIX_COUNT; i++) begin
            avmm_s_readdata |= user_msix_reads[i];
        end
        for (int i = 0; i < PBA_PAIRS; i++) begin
            avmm_s_readdata |= pba_reads[i];
        end
    end

    generate
        genvar i;

        for (i = 0; i < BAR_DATA_BYTES/4; i++) begin : byteen_to_worden
            assign wordenable[i] = avmm_s_byteenable[i*4];
        end

        for (i = 0; i < DMA_MSIX_COUNT; i++) begin : msix_entries
            msix_entry_t msix_entry;

            assign {dma_msix_mask_o[i], dma_msix_data_o[i], dma_msix_addrs_o[i]} = msix_entry;
            assign rw_enable[i] = ((avmm_s_address >> 4) == i);

            // Write
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    msix_entry.address_lo <= '0;
                    msix_entry.address_hi <= '0;
                    msix_entry.data       <= '0;
                    msix_entry.control    <= '1;
                end
                else begin
                    for (int j = 0; j < BAR_DATA_BYTES/4; j++) begin
                        if (rw_enable[i] && wordenable[j] && avmm_s_chipselect && avmm_s_write) begin
                            msix_entry[j*32 +: 32] <= avmm_s_writedata[j*32 +: 32];
                        end
                    end
                end
            end

            // Read
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    dma_msix_reads[i] <= '0;
                end
                else begin
                    if (rw_enable[i] && avmm_s_chipselect && avmm_s_read) begin
                        dma_msix_reads[i] <= msix_entry;
                    end
                    else begin
                        dma_msix_reads[i] <= '0;
                    end
                end
            end
        end

        for (i = 0; i < USER_MSIX_COUNT; i++) begin : msi_entries
            msix_entry_t msix_entry;

            assign {user_msix_mask_o[i], user_msix_data_o[i], user_msix_addrs_o[i]} = msix_entry;
            assign rw_enable[i+DMA_MSIX_COUNT] = ((avmm_s_address >> 4) == (DMA_MSIX_COUNT + i));

            // Write
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    msix_entry.address_lo <= '0;
                    msix_entry.address_hi <= '0;
                    msix_entry.data       <= '0;
                    msix_entry.control    <= '1;
                end
                else begin
                    for (int j = 0; j < BAR_DATA_BYTES/4; j++) begin
                        if (rw_enable[i+DMA_MSIX_COUNT] && wordenable[j] && avmm_s_chipselect && avmm_s_write) begin
                            msix_entry[j*32 +: 32] <= avmm_s_writedata[j*32 +: 32];
                        end
                    end
                end
            end

            // Read
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    user_msix_reads[i] <= '0;
                end
                else begin
                    if (rw_enable[i+DMA_MSIX_COUNT] && avmm_s_chipselect && avmm_s_read) begin
                        user_msix_reads[i] <= msix_entry;
                    end
                    else begin
                        user_msix_reads[i] <= '0;
                    end
                end
            end
        end

        for (i = 0; i < PBA_PAIRS; i++) begin : pba_registers
            logic [127:0] pba_pair;

            assign pba_status_o[i] = pba_pair;
            assign rw_enable[i+TOTAL_MSIX_COUNT] = ((avmm_s_address >> 4) == (i + PBA_OFFSET));

            // Write
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pba_pair <= '0;
                end
                else begin
                    // SW write
                    for (int j = 0; j < BAR_DATA_BYTES/4; j++) begin
                        if (rw_enable[i+TOTAL_MSIX_COUNT] && wordenable[j] && avmm_s_chipselect && avmm_s_write) begin
                            pba_pair[j*32 +: 32] <= avmm_s_writedata[j*32 +: 32];
                        end
                    end

                    // HW write
                    pba_pair <= pba_pair | pba_control_i[i];
                end
            end

            // Read
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pba_reads[i] <= '0;
                end
                else begin
                    if (rw_enable[i+TOTAL_MSIX_COUNT] && avmm_s_chipselect && avmm_s_read) begin
                        pba_reads[i] <= pba_pair;
                    end
                    else begin
                        pba_reads[i] <= '0;
                    end
                end
            end
        end
    endgenerate


    
endmodule