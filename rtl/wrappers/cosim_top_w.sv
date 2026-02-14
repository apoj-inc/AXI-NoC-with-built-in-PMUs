`include "defines.svh"

module cosim_top_w (
    input  logic clk_i,
    input  logic arstn_i,
    input  logic rx_i,
    output logic tx_o
);

    cosim_top #(
        .AXI_ID_WIDTH(`AXI_ID_WIDTH),
        .BAUD_RATE(`BAUD_RATE),
        .CLK_FREQ(`CLK_FREQ),
        .AXI_DATA_WIDTH(`AXI_DATA_WIDTH),
        .ADDR_WIDTH(`ADDR_WIDTH),
        .ID_W_WIDTH(`ID_W_WIDTH),
        .ID_R_WIDTH(`ID_R_WIDTH),
        .MAX_ROUTERS_X(`MAX_ROUTERS_X),
        .MAX_ROUTERS_X_WIDTH(`MAX_ROUTERS_X_WIDTH),
        .MAX_ROUTERS_Y(`MAX_ROUTERS_Y),
        .MAX_ROUTERS_Y_WIDTH(`MAX_ROUTERS_Y_WIDTH),

        .AXI_MASTER_LOADER_FIFO_DEPTH(`AXI_MASTER_LOADER_FIFO_DEPTH),
        .AXI_DATA_BYTES(`AXI_DATA_BYTES)
        `ifdef TID_PRESENT
        ,
        .ID_WIDTH(`ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
        ,
        .DEST_WIDTH(`DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
        ,
        .USER_WIDTH(`USER_WIDTH)
        `endif

    ) dut (
        .clk_i(clk_i),
        .arstn_i(arstn_i),
        .rx_i(rx_i),
        .tx_o(tx_o)
    );
    
endmodule
