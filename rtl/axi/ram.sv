module ram #(
    parameter AXI_DATA_WIDTH = 32,
    parameter ADDR_WIDTH     = 16,
    parameter BYTE_WIDTH     = 8,

    parameter BATCH_SIZE     = AXI_DATA_WIDTH / BYTE_WIDTH
) (
    input clk_i,

    // Port a 
    input  logic [ADDR_WIDTH-1:0]     waddr, raddr,
    input  logic [AXI_DATA_WIDTH-1:0] wdata,
    input  logic [BATCH_SIZE-1:0]     be,
    input  logic                      we,
    output logic [AXI_DATA_WIDTH-1:0] rdata
);

    logic [BATCH_SIZE-1:0][BYTE_WIDTH-1:0] ram [2**ADDR_WIDTH];

    always_ff @( posedge clk_i ) begin : ram_a
        if(we) begin
            if (BATCH_SIZE>0) if (be[0]) ram[waddr][0] <= wdata[BYTE_WIDTH*0 +: BYTE_WIDTH];
            if (BATCH_SIZE>1) if (be[1]) ram[waddr][1] <= wdata[BYTE_WIDTH*1 +: BYTE_WIDTH];
            if (BATCH_SIZE>2) if (be[2]) ram[waddr][2] <= wdata[BYTE_WIDTH*2 +: BYTE_WIDTH];
            if (BATCH_SIZE>3) if (be[3]) ram[waddr][3] <= wdata[BYTE_WIDTH*3 +: BYTE_WIDTH];
            if (BATCH_SIZE>4) if (be[4]) ram[waddr][4] <= wdata[BYTE_WIDTH*4 +: BYTE_WIDTH];
            if (BATCH_SIZE>5) if (be[5]) ram[waddr][5] <= wdata[BYTE_WIDTH*5 +: BYTE_WIDTH];
            if (BATCH_SIZE>6) if (be[6]) ram[waddr][6] <= wdata[BYTE_WIDTH*6 +: BYTE_WIDTH];
            if (BATCH_SIZE>7) if (be[7]) ram[waddr][7] <= wdata[BYTE_WIDTH*7 +: BYTE_WIDTH];
        end
        rdata <= ram[raddr];
    end

endmodule: ram