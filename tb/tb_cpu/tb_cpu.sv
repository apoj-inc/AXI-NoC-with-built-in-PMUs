`timescale 1ns/1ps

module tb_cpu (
    input  logic        rst_n
);

    logic clk;

    axi_if #(
        .DATA_WIDTH(8),
        .ID_R_WIDTH(5),
        .ID_W_WIDTH(5)
    ) m_axi();

    sr_cpu_axi cpu
    (
        .clk   (clk),  
        .rst_n (rst_n),

        .m_axi (m_axi)
    );

    axi_ram #(
        .DATA_WIDTH(8)
    ) ram (
        .clk   (clk),
        .rst_n (rst_n),
        .axi_s (m_axi)
    );

    always #1 clk = !clk;

    initial begin
        $readmemh("single_core.hex", cpu.instr.rom);
        $readmemh("single_image.hex", ram.generate_rams[0].coupled_ram.ram);
        
        ram.generate_rams[0].coupled_ram.ram[40960:40963] = '{1, 0, 0, 0};
        ram.generate_rams[0].coupled_ram.ram[40964:40967] = '{1, 0, 0, 0};
        ram.generate_rams[0].coupled_ram.ram[40968:40971] = '{1, 0, 0, 0};
        ram.generate_rams[0].coupled_ram.ram[40972:40975] = '{1, 0, 0, 0};
        ram.generate_rams[0].coupled_ram.ram[40976:40979] = '{2, 0, 0, 0};
        ram.generate_rams[0].coupled_ram.ram[40980:40983] = '{1, 0, 0, 0};
        ram.generate_rams[0].coupled_ram.ram[40984:40987] = '{1, 0, 0, 0};
        ram.generate_rams[0].coupled_ram.ram[40988:40991] = '{1, 0, 0, 0};
        ram.generate_rams[0].coupled_ram.ram[40992:40995] = '{1, 0, 0, 0};

        clk = 1;
    end
    
endmodule