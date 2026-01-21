module tb_uart_reciever #(
    parameter CLK_FREQ          = 1_000_000_000,
    parameter BAUD_RATE         = 100_000_000,

    parameter CLK_PER_BAUD      = CLK_FREQ / BAUD_RATE,
    parameter CLK_UART_MIDPOINT = CLK_PER_BAUD / 2
) ();

    logic                    clk_i;
    logic                    arstn_i;
    logic                    rx_i;

    logic [7:0] data_o;
    logic       data_ready_i;
    logic       data_valid_o;



receiver rc (
    .clk_i(clk_i),
    .arstn_i(arstn_i),
    .rx_i(rx_i),

    .data_o(data_o),
    .data_ready_i(data_ready_i),
    .data_valid_o(data_valid_o)
);

endmodule
