module de10standard_top(

    input              CLOCK_50,
    input    [ 3: 0]   KEY,
    input    [ 9: 0]   SW,
    output   [ 9: 0]   LEDR, 

    inout    [35: 0]   GPIO
);

    cosim_top #(
        .CORE_COUNT   (16),
        .AXI_ID_WIDTH (5),
        .BAUD_RATE    (800_000),
        .CLK_FREQ     (50_000_000),
        .ADDR_WIDTH   (12)
    ) top (
        .clk_i   (CLOCK_50),
        .arstn_i (GPIO[2]),
        .rx_i    (GPIO[0]),
        .tx_o    (GPIO[1])
    );

endmodule
