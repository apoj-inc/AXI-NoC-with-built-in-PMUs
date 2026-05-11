module avmm_testenv_csr #(
    parameter DMA_CHANNEL_COUNT  = 16 ,
    parameter MAX_ROUTERS_COUNT  = 16 ,
    parameter MAX_AXI_DATA_WIDTH = 32 ,

    parameter BAR_DATA_WIDTH     = 128,
    parameter BAR_ADDR_WIDTH     = 12 ,

    parameter BAR_DATA_BYTES      = BAR_DATA_WIDTH / 8                                    ,
    parameter ROUTERS_COUNT_WIDTH = MAX_ROUTERS_COUNT == 1 ? 1 : $clog2(MAX_ROUTERS_COUNT),
    // 32-bit aligners
    parameter ALIGN_ROUTERS_COUNT       = (MAX_ROUTERS_COUNT   / 32) + (MAX_ROUTERS_COUNT   % 32 != 0),
    parameter ALIGN_ROUTERS_COUNT_WIDTH = (ROUTERS_COUNT_WIDTH / 32) + (ROUTERS_COUNT_WIDTH % 32 != 0),
    parameter ALIGN_AXI_DATA_WIDTH      = (MAX_AXI_DATA_WIDTH  / 32) + (MAX_AXI_DATA_WIDTH  % 32 != 0)
) (
    input  logic                           clk                                     ,
    input  logic                           rst_n                                   ,

    input  logic                           avmm_s_chipselect                       ,
    input  logic [BAR_DATA_BYTES-1:0]      avmm_s_byteenable                       ,
    output logic [BAR_DATA_WIDTH-1:0]      avmm_s_readdata                         ,
    input  logic [BAR_DATA_WIDTH-1:0]      avmm_s_writedata                        ,
    input  logic                           avmm_s_read                             ,
    input  logic                           avmm_s_write                            ,
    output logic                           avmm_s_readdatavalid                    ,
    output logic                           avmm_s_waitrequest                      ,
    input  logic [BAR_ADDR_WIDTH-1:0]      avmm_s_address                          ,

    output logic [DMA_CHANNEL_COUNT-1:0]   ld_read_pmu_o                           ,

    output logic [ROUTERS_COUNT_WIDTH-1:0] ld_rdata_selector_o  [DMA_CHANNEL_COUNT],
    input  logic [MAX_AXI_DATA_WIDTH-1:0]  ld_rdata_i           [DMA_CHANNEL_COUNT],
    input  logic [MAX_ROUTERS_COUNT-1:0]   ld_idle_i            [DMA_CHANNEL_COUNT],
    output logic [MAX_ROUTERS_COUNT-1:0]   ld_masked_o          [DMA_CHANNEL_COUNT],

    input  logic                           testenv_rst_status_i                    ,
    output logic                           testenv_rst_assert_o                    
);

    typedef struct packed {
        logic [31:0]                             ld_read_pmu_reg ;
        logic [ALIGN_ROUTERS_COUNT_WIDTH*32-1:0] ld_rdata_sel_reg;
        logic [ALIGN_AXI_DATA_WIDTH*32-1:0]      ld_rdata_reg    ;
        logic [ALIGN_ROUTERS_COUNT*32-1:0]       ld_idle_reg     ;
        logic [ALIGN_ROUTERS_COUNT*32-1:0]       ld_masked_reg   ;
        logic [31:0]                             cap_next_ptr    ;
    } testenv_struct_t;

    localparam TESTENV_STRUCT_BITS       = $bits(testenv_struct_t)                                   ;
    localparam TESTENV_STRUCT_BYTES      = TESTENV_STRUCT_BITS / 8 + ((TESTENV_STRUCT_BITS % 8) != 0);
    localparam TESTENV_STRUCT_ADDR_WIDTH = $clog2(TESTENV_STRUCT_BYTES)                              ;
    localparam TESTENV_STRUCT_SEL_WIDTH  = 16 - TESTENV_STRUCT_ADDR_WIDTH                            ;

    // Global registers address decoding
    localparam TESTENV_CAP_FIRST  = 16'h0000;
    localparam TESTENV_RST_STATUS = 16'h0004;
    localparam TESTENV_RST_ASSERT = 16'h0008;

    // AVMM translation and control
    logic [BAR_DATA_BYTES/4-1:0] word_enable;
    logic [BAR_DATA_BYTES/4-1:0] word_enable_reg;
    logic [BAR_ADDR_WIDTH-1:0]   translated_addr;
    logic [31:0]                 translated_wdata;
    logic [31:0]                 translated_rdata;

    // Read collector
    logic [31:0] csr_rdata_glob;
    logic [31:0] csr_rdata_struct [DMA_CHANNEL_COUNT];
    
    always_comb begin
        translated_rdata = csr_rdata_glob;
        for (int i = 0; i < DMA_CHANNEL_COUNT; i++) begin
            translated_rdata |= csr_rdata_struct[i];
        end
    end

    assign word_enable = {avmm_s_byteenable[12], avmm_s_byteenable[8], avmm_s_byteenable[4], avmm_s_byteenable[0]};

    always_comb begin
        casez (word_enable)
            4'b???1: translated_addr = avmm_s_address;
            4'b??10: translated_addr = avmm_s_address + 4;
            4'b?100: translated_addr = avmm_s_address + 8;
            4'b1000: translated_addr = avmm_s_address + 12;
            default: translated_addr = avmm_s_address;
        endcase

        casez (word_enable)
            4'b???1: translated_wdata = avmm_s_writedata[31:0]  ;
            4'b??10: translated_wdata = avmm_s_writedata[63:32] ;
            4'b?100: translated_wdata = avmm_s_writedata[95:64] ;
            4'b1000: translated_wdata = avmm_s_writedata[127:96];
            default: translated_wdata = avmm_s_writedata[31:0]  ;
        endcase
        
        avmm_s_readdata = '0;
        casez (word_enable)
            4'b???1: avmm_s_readdata[31:0]   = translated_rdata;
            4'b??10: avmm_s_readdata[63:32]  = translated_rdata;
            4'b?100: avmm_s_readdata[95:64]  = translated_rdata;
            4'b1000: avmm_s_readdata[127:96] = translated_rdata;
            default: avmm_s_readdata[31:0]   = translated_rdata;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            avmm_s_waitrequest   <= '1;
            avmm_s_readdatavalid <= '0;
            word_enable_reg      <= '0;
        end
        else begin
            avmm_s_waitrequest   <= '0;
            avmm_s_readdatavalid <= '0;
            
            if (avmm_s_chipselect && avmm_s_read && !avmm_s_waitrequest) begin
                word_enable_reg <= word_enable;
                avmm_s_waitrequest   <= '1;
                avmm_s_readdatavalid <= '1;
            end
            
        end
    end


    // Global register logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            csr_rdata_glob <= '0;
        end
        else begin
            case (translated_addr)
                TESTENV_CAP_FIRST  : csr_rdata_glob <= 32'(1 << TESTENV_STRUCT_ADDR_WIDTH);
                TESTENV_RST_STATUS : csr_rdata_glob <= testenv_rst_status_i               ;
                TESTENV_RST_ASSERT : csr_rdata_glob <= testenv_rst_assert_o               ;
                default            : csr_rdata_glob <= '0                                 ;
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            testenv_rst_assert_o <= '1;
        end
        else begin
            // Write registers from hardware
            testenv_rst_assert_o <= '0;
            
            // Write registers from interface
            if (avmm_s_write) begin
                case (translated_addr[TESTENV_STRUCT_ADDR_WIDTH-1:0])
                    TESTENV_RST_ASSERT : testenv_rst_assert_o <= translated_wdata;
                endcase
            end
        end
    end


    // Structure logic
    generate
        genvar i;

        for (i = 0; i < DMA_CHANNEL_COUNT; i++) begin : gen_structures
            testenv_struct_t testenv_struct;

            logic struct_addr_enable;

            assign struct_addr_enable = ((translated_addr >> TESTENV_STRUCT_ADDR_WIDTH) == (i+1));

            assign ld_masked_o[i]   = testenv_struct.ld_masked_reg;
            assign ld_read_pmu_o[i] = testenv_struct.ld_read_pmu_reg;
            // Read data logic
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    csr_rdata_struct[i] <= '0;
                end
                else begin
                    if (struct_addr_enable) begin
                        csr_rdata_struct[i] <= testenv_struct[32'(translated_addr[TESTENV_STRUCT_ADDR_WIDTH-1:0])<<3 +: 32];
                    end
                    else begin
                        csr_rdata_struct[i] <= '0;
                    end
                end
            end

            // Write data and register reset value logic            
            
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    testenv_struct.ld_read_pmu_reg  <= '0;

                    testenv_struct.cap_next_ptr     <= '0;
                    testenv_struct.ld_idle_reg      <= '0;
                    testenv_struct.ld_masked_reg    <= '0;
                    testenv_struct.ld_rdata_sel_reg <= '0;
                    testenv_struct.ld_rdata_reg     <= '0;
                end
                else begin
                    // Write singlepulse registers from hardware
                    testenv_struct.ld_read_pmu_reg <= '0;

                    // Write registers from interface
                    if (struct_addr_enable && avmm_s_write) begin
                        testenv_struct[32'(translated_addr[TESTENV_STRUCT_ADDR_WIDTH-1:0])<<3 +: 32] <= translated_wdata;
                    end

                    // Write rdonly registers from hardware
                    testenv_struct.cap_next_ptr <= (i == (DMA_CHANNEL_COUNT-1)) ? '0 : ((i+2) << TESTENV_STRUCT_ADDR_WIDTH);
                    testenv_struct.ld_idle_reg  <= ld_idle_i[i]                                                            ;
                    testenv_struct.ld_rdata_reg <= ld_rdata_i[i]                                                           ;
                end
            end
        end
    endgenerate
    
endmodule