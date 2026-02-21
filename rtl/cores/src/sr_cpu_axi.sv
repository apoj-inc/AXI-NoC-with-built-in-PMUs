`include "defines.svh"

module sr_cpu_axi
import axi_type::*;
(
    input   logic         clk,  
    input   logic         rst_n,

    input  axi_miso_t in_miso_i,
    output axi_mosi_t in_mosi_o
);

    logic         mem_wr;
    logic [15:0]  mem_addr;
    logic         mem_req_valid;
    logic         mem_req_ready;
    logic         mem_resp_ready;
    logic         mem_resp_valid;
    logic [31:0]  mem_wdata;
    logic [31:0]  mem_rdata;

    logic [31:0]  imAddr;
    logic [31:0]  imData;

    sm_rom instr
    (
        .a  (imAddr),
        .rd (imData)
    );

    sr_cpu core(
        .clk                (clk),
        .rst_n              (rst_n),
        .regAddr            ('0),
        .regData            (), //nc
        .imAddr             (imAddr),
        .imData             (imData),

        .mem_wr_o           (mem_wr),
        .mem_addr_o         (mem_addr),
        .mem_req_valid_o    (mem_req_valid),
        .mem_req_ready_i    (mem_req_ready),
        .mem_resp_ready_o   (mem_resp_ready),
        .mem_resp_valid_i   (mem_resp_valid),
        .mem_wdata_o        (mem_wdata),
        .mem_rdata_i        (mem_rdata)
    );

    sr_axi_adapter axi_adapt (
        .clk              (clk),
        .rst_n            (rst_n),

        .mem_wr_i         (mem_wr),
        .mem_addr_i       (mem_addr),
        .mem_req_valid_i  (mem_req_valid),
        .mem_req_ready_o  (mem_req_ready),
        .mem_resp_ready_i (mem_resp_ready),
        .mem_resp_valid_o (mem_resp_valid),
        .mem_wdata_i      (mem_wdata),
        .mem_rdata_o      (mem_rdata),

        .in_miso_i(in_miso_i),
        .in_mosi_o(in_mosi_o)
    );

endmodule