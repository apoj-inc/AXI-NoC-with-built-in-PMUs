module sync_rst #(
    parameter FF3 = 0
) (
    input  logic rst_n_i,

    input  logic clk_tgt,
    output logic rst_n_o
);

    sync_ff #(
        .FF3        (FF3), // if 0 - 2FF used, if 1 - 3FF used
        .DATA_WIDTH (1  )
    ) u_sync_ff (
        .data_i   ('1     ),

        .clk_rd   (clk_tgt),
        .rst_n_rd (rst_n_i),
        .data_o   (rst_n_o)
    );

endmodule