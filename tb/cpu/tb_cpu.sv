`timescale 1ns/1ps

module tb_cpu (
    input  logic        rst_n
);

    logic clk;

    `include "axi_type.svh"

    axi_miso_t axi_miso;
    axi_mosi_t axi_mosi;

    sr_cpu_axi cpu (
        .clk   (clk),  
        .rst_n (rst_n),

        .in_miso_i(axi_miso),
        .in_mosi_o(axi_mosi)
    );

    axi_ram ram (
        .clk_i   (clk),
        .rst_n_i (rst_n),
        
        .in_mosi_i(axi_mosi),
        .in_miso_o(axi_miso)
    );

    always #1 clk = !clk;

    initial begin
        $readmemh("single_core.hex", cpu.instr.rom);
        $readmemh("single_image.hex", ram.coupled_ram.ram);

        clk = 1;
    end
    
endmodule