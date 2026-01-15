`include "defines.svh"

module axi_ram 
#(
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter ADDR_WIDTH = 16,

    parameter AXI_DATA_WIDTH = 32
    `ifdef TID_PRESENT
    ,
    parameter ID_WIDTH = 4
    `endif
    `ifdef TDEST_PRESENT
    ,
    parameter DEST_WIDTH = 4
    `endif
    `ifdef TUSER_PRESENT
    ,
    parameter USER_WIDTH = 4
    `endif,

    parameter BYTE_WIDTH = 8
) (
	input logic clk_i, rst_n_i,
    
    input  axi_mosi_t in_mosi_i,
    output axi_miso_t in_miso_o

);

    `include "axi_type.svh"

    localparam WSRTB_W = AXI_DATA_WIDTH/BYTE_WIDTH;

    logic [ADDR_WIDTH-1:0] addr_a;
    logic [BYTE_WIDTH*WSRTB_W-1:0] data_a;
    logic [BYTE_WIDTH*WSRTB_W-1:0] write_a;
    logic [WSRTB_W-1:0] write_en_a;
    
    logic [ADDR_WIDTH-1:0] addr_b;
    logic [BYTE_WIDTH*WSRTB_W-1:0] data_b;
    logic [BYTE_WIDTH*WSRTB_W-1:0] write_b;
    logic [WSRTB_W-1:0] write_en_b;

    axi2ram #(
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),

        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
        `ifdef TID_PRESENT
         ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
         ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
         ,
        .USER_WIDTH(USER_WIDTH)
        `endif
    
        ) axi (
        .clk_i(clk_i), .rst_n_i(rst_n_i),

        .addr_a(addr_a),
        .data_a(data_a),
        .write_a(write_a),
        .write_en_a(write_en_a),

        .addr_b(addr_b),
        .data_b(data_b),
        .write_b(write_b),
        .write_en_b(write_en_b),

        .in_mosi_i(in_mosi_i),
        .in_miso_o(in_miso_o)

    );

    ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .BYTE_WIDTH(BYTE_WIDTH),
        .BATCH_WIDTH(WSRTB_W)
    ) coupled_ram (
        .clk_i(clk_i),

        .addr_a(addr_a),
        .data_a(data_a),
        .write_a(write_a),
        .byte_en_a(write_en_a),
        .write_en_a(|write_en_a),

        .addr_b(addr_b),
        .data_b(data_b),
        .write_b(write_b),
        .byte_en_b(write_en_b),
        .write_en_b(|write_en_b)

    );
  
endmodule : axi_ram