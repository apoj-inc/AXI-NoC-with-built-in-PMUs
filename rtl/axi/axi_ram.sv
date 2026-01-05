module axi_ram 
#(
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter BYTE_WIDTH = 8
) (
	input logic clk, rst_n,

    input axi_data_aw_t axi_data_aw,
    
    input  logic aw_valid, w_valid, ar_valid,
    output logic aw_ready, w_ready, ar_ready,

    output axi_data_aw_t axi_data_br,

    output logic b_valid, r_valid,
    input  logic b_ready, r_ready

);

    `include "axi_type.svh"

    localparam WSRTB_W = DATA_WIDTH/BYTE_WIDTH;

    logic [ADDR_WIDTH-1:0] addr_a [DATA_WIDTH/BYTE_WIDTH];
    logic [BYTE_WIDTH-1:0] data_a [DATA_WIDTH/BYTE_WIDTH];
    logic [BYTE_WIDTH-1:0] write_a [DATA_WIDTH/BYTE_WIDTH];
    logic byte_en_a;
    logic [DATA_WIDTH/BYTE_WIDTH] write_en_a;
    
    logic [ADDR_WIDTH-1:0] addr_b [DATA_WIDTH/BYTE_WIDTH];
    logic [BYTE_WIDTH-1:0] data_b [DATA_WIDTH/BYTE_WIDTH];
    logic [BYTE_WIDTH-1:0] write_b [DATA_WIDTH/BYTE_WIDTH];
    logic byte_en_b;
    logic [DATA_WIDTH/BYTE_WIDTH] write_en_b;

    axi2ram #(
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
        ) axi (
        .clk(clk), .rst_n(rst_n),

        .addr_a(addr_a),
        .data_a(data_a),
        .write_a(write_a),
        .write_en_a(write_en_a),

        .addr_b(addr_b),
        .data_b(data_b),
        .write_b(write_b),
        .write_en_b(write_en_b),

        .axi_data_aw(axi_data_aw),
        
        .aw_valid(aw_valid), .w_valid(w_valid), .ar_valid(ar_valid),
        .aw_ready(aw_ready), .w_ready(w_ready), .ar_ready(ar_ready),

        .axi_data_br(axi_data_br),

        .b_valid(b_valid), .r_valid(r_valid),
        .b_ready(b_ready), .r_ready(r_ready)

    );

    ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .BYTE_WIDTH(BYTE_WIDTH),
        .BATCH_WIDTH(WSRTB_W)
    ) coupled_ram (
        .clk_a(clk), .clk_b(clk),

        .addr_a(addr_a),
        .data_a(data_a),
        .write_a(write_a),
        .byte_en_b(byte_en_b),
        .write_en_a(write_en_a),

        .addr_b(addr_b),
        .data_b(data_b),
        .write_b(write_b),
        .byte_en_b(byte_en_b),
        .write_en_b(write_en_b)

    );
  
endmodule : axi_ram