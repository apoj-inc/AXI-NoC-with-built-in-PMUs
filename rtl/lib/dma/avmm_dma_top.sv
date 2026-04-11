module avmm_dma_top #(
    parameter BAR_DATA_WIDTH = 128,
    parameter BAR_DATA_BYTES = BAR_DATA_WIDTH / 8,
    parameter BAR_ADDR_WIDTH = 1,
    
    parameter CRA_DATA_WIDTH = 32,
    parameter CRA_DATA_BYTES = CRA_DATA_WIDTH / 8,
    parameter CRA_ADDR_WIDTH = 14,

    parameter TX_DATA_WIDTH  = 128,
    parameter TX_DATA_BYTES  = TX_DATA_WIDTH / 8,
    parameter TX_ADDR_WIDTH  = 64,
    parameter TX_BURST_WIDTH = 6
) (
    input  logic                      clk,
    input  logic                      rst_n,

    input  logic                      bar_chipselect_i,
    input  logic [BAR_DATA_BYTES-1:0] bar_byteenable_i,
    output logic [BAR_DATA_WIDTH-1:0] bar_readdata_o,
    input  logic [BAR_DATA_WIDTH-1:0] bar_writedata_i,
    input  logic                      bar_read_i,
    input  logic                      bar_write_i,
    output logic                      bar_readdatavalid_o,
    output logic                      bar_waitrequest_o,
    input  logic [BAR_ADDR_WIDTH-1:0] bar_address_i,

    output logic                      cra_chipselect_o,
    output logic [CRA_DATA_BYTES-1:0] cra_byteenable_o,
    input  logic [CRA_DATA_WIDTH-1:0] cra_readdata_i,
    output logic [CRA_DATA_WIDTH-1:0] cra_writedata_o,
    output logic                      cra_read_o,
    output logic                      cra_write_o,
    input  logic                      cra_waitrequest_i,
    output logic [CRA_ADDR_WIDTH-1:0] cra_address_o,

    output logic                      tx_chipselect,
    output logic [TX_DATA_BYTES-1:0]  tx_byteenable,
    input  logic [TX_DATA_WIDTH-1:0]  tx_readdata,
    output logic [TX_DATA_WIDTH-1:0]  tx_writedata,
    output logic                      tx_read,
    output logic                      tx_write,
    output logic [TX_BURST_WIDTH-1:0] tx_burstcount,
    input  logic                      tx_readdatavalid,
    input  logic                      tx_waitrequest,
    output logic [TX_ADDR_WIDTH-1:0]  tx_address
);

    logic [31:0] csr_data;
    logic [1:0] csr_addr;
    logic csr_we;

    avmm_dma_decoder #(
        .BAR_DATA_WIDTH (BAR_DATA_WIDTH),
        .BAR_ADDR_WIDTH (BAR_ADDR_WIDTH),
        
        .CRA_DATA_WIDTH (CRA_DATA_WIDTH),
        .CRA_ADDR_WIDTH (CRA_ADDR_WIDTH),

        .TX_DATA_WIDTH  (TX_DATA_WIDTH ),
        .TX_BURST_WIDTH (TX_BURST_WIDTH)
    ) u_avmm_decoder (
        .clk                 (clk),
        .rst_n               (rst_n),

        .bar_chipselect_i    (bar_chipselect_i),
        .bar_byteenable_i    (bar_byteenable_i),
        .bar_readdata_o      (bar_readdata_o),
        .bar_writedata_i     (bar_writedata_i),
        .bar_read_i          (bar_read_i),
        .bar_write_i         (bar_write_i),
        .bar_readdatavalid_o (bar_readdatavalid_o),
        .bar_waitrequest_o   (bar_waitrequest_o),
        .bar_address_i       (bar_address_i),

        .cra_chipselect_o    (cra_chipselect_o),
        .cra_byteenable_o    (cra_byteenable_o),
        .cra_readdata_i      (cra_readdata_i),
        .cra_writedata_o     (cra_writedata_o),
        .cra_read_o          (cra_read_o),
        .cra_write_o         (cra_write_o),
        .cra_waitrequest_i   (cra_waitrequest_i),
        .cra_address_o       (cra_address_o),

        .dma_task_valid_o    (),
        .dma_task_ready_i    ('1),
        .dma_task_data_o     (),

        .csr_data_o          (csr_data),
        .csr_addr_o          (csr_addr),
        .csr_we_o            (csr_we)
    );

    avmm_dma_csr u_avmm_dma_csr (
        .clk                (clk),
        .rst_n              (rst_n),

        .csr_data_i         (csr_data),
        .csr_addr_i         (csr_addr),
        .csr_we_i           (csr_we),

        .csr_dma_msi_set_o  (),
        .csr_dma_msi_addr_o (),
        .csr_dma_msi_data_o ()
    );

endmodule