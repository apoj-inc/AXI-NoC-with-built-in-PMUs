`include "defines.svh"

module axi_ram
import axi_type::*;
#(
    parameter BYTE_WIDTH = 8
) (
	input logic clk_i, rst_n_i,
    
    input  axi_mosi_t in_mosi_i,
    output axi_miso_t in_miso_o

);

    localparam WSRTB_W = AXI_DATA_WIDTH/BYTE_WIDTH;
    
    logic [ADDR_WIDTH-1:0]     waddr, waddr_ff;
    logic [ADDR_WIDTH-1:0]     raddr, raddr_ff;
    logic [AXI_DATA_WIDTH-1:0] wdata, wdata_ff;
    logic [AXI_DATA_WIDTH-1:0] rdata, rdata_ff;
    logic [WSRTB_W-1:0]        be,    be_ff;
    logic we_ff;

    axi2ram  axi (
        .clk_i(clk_i), .rst_n_i(rst_n_i),
        
        .waddr(waddr),
        .raddr(raddr),
        .wdata(wdata),
        .be(be),
        .rdata(rdata),

        .in_mosi_i(in_mosi_i),
        .in_miso_o(in_miso_o)

    );
    
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            waddr_ff <= '0;
            raddr_ff <= '0;
            wdata_ff <= '0;
            be_ff    <= '0;
            we_ff    <= '0;
        end else begin
            waddr_ff <= waddr;
            raddr_ff <= raddr;
            wdata_ff <= wdata;
            be_ff    <= be;
            we_ff    <= |be;
        end
    end

    ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .BYTE_WIDTH(BYTE_WIDTH)
    ) coupled_ram (
        .clk_i(clk_i),
        
        .waddr(waddr_ff),
        .raddr(raddr),
        .wdata(wdata_ff),
        .we(we_ff),
        .be(be_ff),
        .rdata(rdata)

    );
  
endmodule : axi_ram