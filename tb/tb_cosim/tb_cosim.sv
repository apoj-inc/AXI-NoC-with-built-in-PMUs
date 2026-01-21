module tb_cosim (
    input  logic clk_i,
    input  logic arstn_i,
    input  logic rx_i,
    output logic tx_o
);

cosim_top #(.BAUD_RATE(115_200)) ct(
    .clk_i(clk_i),
    .arstn_i(arstn_i),
    .rx_i(rx_i),
    .tx_o(tx_o)
);

endmodule
