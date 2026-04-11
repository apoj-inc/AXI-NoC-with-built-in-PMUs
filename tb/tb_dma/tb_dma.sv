module tb_dma;

parameter BAR_DATA_WIDTH = 128;
parameter BAR_DATA_BYTES = BAR_DATA_WIDTH / 8;
parameter BAR_ADDR_WIDTH = 1;

parameter CRA_DATA_WIDTH = 32;
parameter CRA_DATA_BYTES = CRA_DATA_WIDTH / 8;
parameter CRA_ADDR_WIDTH = 14;

parameter TX_DATA_WIDTH  = 128;
parameter TX_DATA_BYTES  = TX_DATA_WIDTH / 8;
parameter TX_ADDR_WIDTH  = 64;
parameter TX_BURST_WIDTH = 6;

logic clk, rst_n;

logic                      bar_chipselect_i;
logic [BAR_DATA_BYTES-1:0] bar_byteenable_i;
logic [BAR_DATA_WIDTH-1:0] bar_readdata_o;
logic [BAR_DATA_WIDTH-1:0] bar_writedata_i;
logic                      bar_read_i;
logic                      bar_write_i;
logic                      bar_readdatavalid_o;
logic                      bar_waitrequest_o;
logic [BAR_ADDR_WIDTH-1:0] bar_address_i;

logic                      cra_chipselect_o;
logic [CRA_DATA_BYTES-1:0] cra_byteenable_o;
logic [CRA_DATA_WIDTH-1:0] cra_readdata_i;
logic [CRA_DATA_WIDTH-1:0] cra_writedata_o;
logic                      cra_read_o;
logic                      cra_write_o;
logic                      cra_waitrequest_i;
logic [CRA_ADDR_WIDTH-1:0] cra_address_o;

logic test_done;

assign bar_chipselect_i = '1;
assign bar_byteenable_i = '1;


avmm_dma_top #(
    .BAR_DATA_WIDTH (BAR_DATA_WIDTH),
    .BAR_ADDR_WIDTH (BAR_ADDR_WIDTH),

    .CRA_DATA_WIDTH (CRA_DATA_WIDTH),
    .CRA_ADDR_WIDTH (CRA_ADDR_WIDTH),

    .TX_DATA_WIDTH  (TX_DATA_WIDTH ),
    .TX_ADDR_WIDTH  (TX_ADDR_WIDTH ),
    .TX_BURST_WIDTH (TX_BURST_WIDTH)
) dut (
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

    .tx_chipselect       (),
    .tx_byteenable       (),
    .tx_readdata         (),
    .tx_writedata        (),
    .tx_read             (),
    .tx_write            (),
    .tx_burstcount       (),
    .tx_readdatavalid    (),
    .tx_waitrequest      (),
    .tx_address          ()
);

always #10 clk = ~clk;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cra_waitrequest_i <= '1;
        cra_readdata_i <= '0;
    end
    else begin
        cra_waitrequest_i <= $urandom();
        cra_readdata_i <= $urandom();
    end
end

initial begin

    test_done = '0;
    bar_writedata_i = '0;
    bar_read_i = '0;
    bar_write_i = '0;
    bar_address_i = '0;

    rst_n = '0;
    clk = '1;
    #25;
    rst_n = '1;

    @(posedge clk);
    bar_read_i = '1;
    bar_address_i = '0;
    @(posedge clk);
    while (bar_waitrequest_o) begin
        @(posedge clk);
    end
    bar_read_i = '0;
    while (bar_readdatavalid_o) begin
        @(posedge clk);
    end
    
    @(posedge clk);
    bar_read_i = '1;
    bar_address_i = '1;
    @(posedge clk);
    while (bar_waitrequest_o) begin
        @(posedge clk);
    end
    bar_read_i = '0;
    while (bar_readdatavalid_o) begin
        @(posedge clk);
    end
    
    @(posedge clk);
    bar_write_i = '1;
    bar_address_i = '0;
    @(posedge clk);
    while (bar_waitrequest_o) begin
        @(posedge clk);
    end
    bar_write_i = '0;
    
    @(posedge clk);
    bar_write_i = '1;
    bar_address_i = '1;
    bar_writedata_i = $urandom() + ($urandom() << 32) + (10'($urandom()) << 64) + (1'b1 << 76);
    @(posedge clk);
    while (bar_waitrequest_o) begin
        @(posedge clk);
    end
    bar_write_i = '0;
    
    @(posedge clk);
    bar_write_i = '1;
    bar_address_i = '1;
    bar_writedata_i = $urandom() + ($urandom() << 32) + (10'($urandom()) << 64) + (1'b0 << 76);
    @(posedge clk);
    while (bar_waitrequest_o) begin
        @(posedge clk);
    end
    bar_write_i = '0;
    
    test_done = '1;

end


endmodule