module avmm_dma_msix_table #(
    parameter BAR_DATA_WIDTH = 128 ,
    parameter BAR_ADDR_WIDTH = 1   ,
    parameter MSI_COUNT      = 16  ,

    parameter BAR_DATA_BYTES = BAR_DATA_WIDTH / 8                     ,
    parameter PBA_COUNT      = MSI_COUNT / 64 + (MSI_COUNT % 64 != 0) ,
    parameter PBA_PAIRS      = PBA_COUNT / 2 + (PBA_COUNT % 2 != 0)   
) (
    input  logic                       clk                             ,
    input  logic                       rst_n                           ,

    input  logic                       avmm_s_chipselect               ,
    input  logic [BAR_DATA_BYTES-1:0]  avmm_s_byteenable               ,
    output logic [BAR_DATA_WIDTH-1:0]  avmm_s_readdata                 ,
    input  logic [BAR_DATA_WIDTH-1:0]  avmm_s_writedata                ,
    input  logic                       avmm_s_read                     ,
    input  logic                       avmm_s_write                    ,
    output logic                       avmm_s_readdatavalid            ,
    output logic                       avmm_s_waitrequest              ,
    input  logic [BAR_ADDR_WIDTH-1:0]  avmm_s_address                  ,

    output logic [31:0]                msix_mask_o          [MSI_COUNT],
    output logic [31:0]                msix_data_o          [MSI_COUNT],
    output logic [63:0]                msix_addrs_o         [MSI_COUNT],
    
    input  logic [127:0]               pba_control_i        [PBA_COUNT],
    output logic [127:0]               pba_status_o         [PBA_COUNT]
);

    typedef struct packed {
        logic [31:0] control   ;
        logic [31:0] data      ;
        logic [31:0] address_hi;
        logic [31:0] address_lo;
    } msi_entry_t;

    logic [BAR_DATA_BYTES/4 - 1:0]  wordenable           ;
    logic [BAR_DATA_WIDTH-1:0]      msi_reads [MSI_COUNT];
    logic [BAR_DATA_WIDTH-1:0]      pba_reads [PBA_PAIRS];
    logic [MSI_COUNT+PBA_PAIRS-1:0] rw_enable            ;

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
        for (int i = 0; i < MSI_COUNT; i++) begin
            avmm_s_readdata |= msi_reads[i];
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

        for (i = 0; i < MSI_COUNT; i++) begin : msi_entries
            msi_entry_t msi_entry;

            assign {msix_mask_o[i], msix_data_o[i], msix_addrs_o[i]} = msi_entry;
            assign rw_enable[i] = ((avmm_s_address >> 4) == i);

            // Write
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    msi_entry.address_lo <= '0;
                    msi_entry.address_hi <= '0;
                    msi_entry.data       <= '0;
                    msi_entry.control    <= '1;
                end
                else begin
                    for (int j = 0; j < BAR_DATA_BYTES/4; j++) begin
                        if (rw_enable[i] && wordenable[j] && avmm_s_chipselect && avmm_s_write) begin
                            msi_entry[j*32 +: 32] <= avmm_s_writedata[j*32 +: 32];
                        end
                    end
                end
            end

            // Read
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    msi_reads[i] <= '0;
                end
                else begin
                    if (rw_enable[i] && avmm_s_chipselect && avmm_s_read) begin
                        msi_reads[i] <= msi_entry;
                    end
                    else begin
                        msi_reads[i] <= '0;
                    end
                end
            end
        end

        for (i = 0; i < PBA_PAIRS; i++) begin : pba_registers
            logic [127:0] pba_pair;

            assign pba_status_o[i] = pba_pair;
            assign rw_enable[i+MSI_COUNT] = ((avmm_s_address >> 4) == (i + MSI_COUNT));

            // Write
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pba_pair <= '0;
                end
                else begin
                    // SW write
                    for (int j = 0; j < BAR_DATA_BYTES/4; j++) begin
                        if (rw_enable[i+MSI_COUNT] && wordenable[j] && avmm_s_chipselect && avmm_s_write) begin
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
                    if (rw_enable[i+MSI_COUNT] && avmm_s_chipselect && avmm_s_read) begin
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