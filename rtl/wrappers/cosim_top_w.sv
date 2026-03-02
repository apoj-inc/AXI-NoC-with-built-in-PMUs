`include "defines.svh"

module cosim_top_w (
    input  logic clk_i,
    input  logic arstn_i,
    input  logic rx_i,
    output logic tx_o
);

    cosim_top #(
    .BAUD_RATE(`BAUD_RATE),
    .CLK_FREQ(`CLK_FREQ),

    .AXI_DATA_WIDTH(`AXI_DATA_WIDTH),
    .AXI_ID_W_WIDTH(`AXI_ID_W_WIDTH),
    .AXI_ID_R_WIDTH(`AXI_ID_R_WIDTH),
    .AXI_ADDR_WIDTH(`AXI_ADDR_WIDTH),

    .AXIS_DATA_WIDTH(`AXIS_DATA_WIDTH),
    .AXIS_ID_WIDTH(`AXIS_ID_WIDTH),
    .AXIS_DEST_WIDTH(`AXIS_DEST_WIDTH),
    .AXIS_USER_WIDTH(`AXIS_USER_WIDTH),
    
    .AXI_MASTER_LOADER_FIFO_DEPTH(`AXI_MASTER_LOADER_FIFO_DEPTH),

    .MAX_ROUTERS_X(`MAX_ROUTERS_X),
    .MAX_ROUTERS_X_WIDTH(`MAX_ROUTERS_X_WIDTH),
    .MAX_ROUTERS_Y(`MAX_ROUTERS_Y),
    .MAX_ROUTERS_Y_WIDTH(`MAX_ROUTERS_Y_WIDTH),

    .BUFFER_DEPTH(`BUFFER_DEPTH),

    .ROUTERS_COUNT(`ROUTERS_COUNT),
    .CORE_COUNT(`CORE_COUNT),
    .AXI_MAX_ID_WIDTH(`AXI_MAX_ID_WIDTH),

    .AXI_DATA_BYTES(`AXI_DATA_BYTES)

    ) dut (
        .clk_i(clk_i),
        .arstn_i(arstn_i),
        .rx_i(rx_i),
        .tx_o(tx_o)
    );
    
endmodule
