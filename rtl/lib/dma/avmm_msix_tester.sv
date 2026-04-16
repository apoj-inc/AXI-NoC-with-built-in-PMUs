module avmm_msix_tester #(
    parameter TX_DATA_WIDTH  = 128 ,
    parameter TX_ADDR_WIDTH  = 64  ,
    parameter TX_BURST_WIDTH = 6   ,

    parameter BAR_DATA_WIDTH = 128 ,
    parameter BAR_ADDR_WIDTH = 12  ,

    parameter MSI_COUNT      = 16  ,

    parameter PBA_COUNT      = MSI_COUNT / 64 + (MSI_COUNT % 64 != 0) ,
    parameter PBA_PAIRS      = PBA_COUNT / 2 + (PBA_COUNT % 2 != 0)   ,
    parameter BAR_DATA_BYTES = BAR_DATA_WIDTH / 8                     ,
    parameter TX_DATA_BYTES  = TX_DATA_WIDTH / 8                      
) (
    input  logic                       clk                             ,
    input  logic                       rst_n                           ,

    input  logic [31:0]                msix_mask_i          [MSI_COUNT],
    input  logic [31:0]                msix_data_i          [MSI_COUNT],
    input  logic [63:0]                msix_addrs_i         [MSI_COUNT],

    output logic [127:0]               pba_control_o        [PBA_COUNT],
    input  logic [127:0]               pba_status_i         [PBA_COUNT],

    input  logic                       bar_chipselect                  ,
    input  logic [BAR_DATA_BYTES-1:0]  bar_byteenable                  ,
    output logic [BAR_DATA_WIDTH-1:0]  bar_readdata                    ,
    input  logic [BAR_DATA_WIDTH-1:0]  bar_writedata                   ,
    input  logic                       bar_read                        ,
    input  logic                       bar_write                       ,
    output logic                       bar_readdatavalid               ,
    output logic                       bar_waitrequest                 ,
    input  logic [BAR_ADDR_WIDTH-1:0]  bar_address                     ,

    output logic                       tx_chipselect                   ,
    output logic [TX_DATA_BYTES-1:0]   tx_byteenable                   ,
    input  logic [TX_DATA_WIDTH-1:0]   tx_readdata                     ,
    output logic [TX_DATA_WIDTH-1:0]   tx_writedata                    ,
    output logic                       tx_read                         ,
    output logic                       tx_write                        ,
    output logic [TX_BURST_WIDTH-1:0]  tx_burstcount                   ,
    input  logic                       tx_readdatavalid                ,
    input  logic                       tx_waitrequest                  ,
    output logic [TX_ADDR_WIDTH-1:0]   tx_address                      
);

    logic [31:0]          int_index;
    logic [MSI_COUNT-1:0] send_pending;
    logic [MSI_COUNT-1:0] prev_pba;

    assign tx_read           = '0;
    assign tx_burstcount     = 1;
    assign tx_byteenable     = 'h000F;

    assign bar_readdatavalid = '0;
    assign bar_readdata      = '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bar_waitrequest  <= '1;
            pba_control_o[0] <= '0;
        end
        else begin
            bar_waitrequest  <= '0;
            pba_control_o[0] <= '0;

            if (bar_chipselect && bar_write && (bar_address == 0)) begin
                if (bar_writedata[31:0] < MSI_COUNT) begin
                    pba_control_o[0][bar_writedata[31:0]] <= 1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_pba          <= '0;
        end
        else begin
            prev_pba          <= pba_control_o[0];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_pending      <= '0;
            int_index         <= '0;

            tx_chipselect     <= '0;
            tx_writedata      <= '0;
            tx_write          <= '0;
            tx_address        <= '0;
        end
        else begin
            for (int i = 0; i < MSI_COUNT; i++) begin
                send_pending[i] <= send_pending[i] | (pba_control_o[0][i] == 1) & (prev_pba[i] == 0); // Edge detection
            end

            if (send_pending[int_index]) begin
                tx_chipselect <= '1;
                tx_write      <= '1;
                tx_address    <= msix_addrs_i[int_index];
                tx_writedata  <= msix_data_i[int_index];
            end
            else begin
                int_index     <= (int_index == (MSI_COUNT - 1)) ? '0 : int_index + 1;
            end

            if (tx_chipselect && tx_write && !tx_waitrequest) begin
                tx_chipselect           <= '0;
                tx_write                <= '0;
                send_pending[int_index] <= '0;
                int_index               <= (int_index == (MSI_COUNT - 1)) ? '0 : int_index + 1;
            end
        end
    end

endmodule