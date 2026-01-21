module tb_uart_transciever #(
    parameter CLK_FREQ     = 1_000_000_000,
    parameter BAUD_RATE    = 100_000_000,

    parameter CLK_PER_BAUD = CLK_FREQ / BAUD_RATE
) ();

    logic                    clk_i;
    logic                    arstn_i;
    logic                    tx_o;

    logic [7:0] data_i;
    logic       data_ready_o;
    logic       data_valid_i;

transmitter uc (
    .clk_i(clk_i),
    .arstn_i(arstn_i),
    .tx_o(tx_o),
    
    .data_i(data_i),
    .data_ready_o(data_ready_o),
    .data_valid_i(data_valid_i)
);

endmodule
