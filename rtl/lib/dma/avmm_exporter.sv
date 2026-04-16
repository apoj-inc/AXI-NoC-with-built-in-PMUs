module avmm_exporter #(
    parameter AVMM_DATA_WIDTH  = 128,
    parameter AVMM_ADDR_WIDTH  = 64,
    parameter AVMM_BURST_WIDTH = 6
) (
    input  logic                         clk                  ,
    input  logic                         rst_n                ,

    input  logic                         avmm_s_chipselect    ,
    input  logic [AVMM_DATA_WIDTH/8-1:0] avmm_s_byteenable    ,
    output logic [AVMM_DATA_WIDTH-1:0]   avmm_s_readdata      ,
    input  logic [AVMM_DATA_WIDTH-1:0]   avmm_s_writedata     ,
    input  logic                         avmm_s_read          ,
    input  logic                         avmm_s_write         ,
    input  logic [AVMM_BURST_WIDTH-1:0]  avmm_s_burstcount    ,
    output logic                         avmm_s_readdatavalid ,
    output logic                         avmm_s_waitrequest   ,
    input  logic [AVMM_ADDR_WIDTH-1:0]   avmm_s_address       ,

    output logic                         avmm_m_chipselect    ,
    output logic [AVMM_DATA_WIDTH/8-1:0] avmm_m_byteenable    ,
    input  logic [AVMM_DATA_WIDTH-1:0]   avmm_m_readdata      ,
    output logic [AVMM_DATA_WIDTH-1:0]   avmm_m_writedata     ,
    output logic                         avmm_m_read          ,
    output logic                         avmm_m_write         ,
    output logic [AVMM_BURST_WIDTH-1:0]  avmm_m_burstcount    ,
    input  logic                         avmm_m_readdatavalid ,
    input  logic                         avmm_m_waitrequest   ,
    output logic [AVMM_ADDR_WIDTH-1:0]   avmm_m_address       
);

    assign avmm_m_chipselect    = avmm_s_chipselect    ;
    assign avmm_m_byteenable    = avmm_s_byteenable    ;
    assign avmm_s_readdata      = avmm_m_readdata      ;
    assign avmm_m_writedata     = avmm_s_writedata     ;
    assign avmm_m_read          = avmm_s_read          ;
    assign avmm_m_write         = avmm_s_write         ;
    assign avmm_m_burstcount    = avmm_s_burstcount    ;
    assign avmm_s_readdatavalid = avmm_m_readdatavalid ;
    assign avmm_s_waitrequest   = avmm_m_waitrequest   ;
    assign avmm_m_address       = avmm_s_address       ;
    
endmodule