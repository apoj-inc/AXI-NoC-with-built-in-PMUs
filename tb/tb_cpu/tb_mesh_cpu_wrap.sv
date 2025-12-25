`timescale 1ns/1ps

module tb_mesh_cpu_wrap (
    input logic rst_n
);

logic clk;
logic ram_loaded;
logic simulation_finished;

XY_mesh_dual_cpu mpcpu (clk, rst_n);

always #1 clk = !clk;

initial begin

    $readmemh("instr_node_0.hex",   mpcpu.cpu[0].instr.rom);
    $readmemh("instr_node_1.hex",   mpcpu.cpu[1].instr.rom);
    $readmemh("instr_node_2.hex",   mpcpu.cpu[2].instr.rom);
    $readmemh("instr_node_3.hex",   mpcpu.cpu[3].instr.rom);
    $readmemh("instr_node_4.hex",   mpcpu.cpu[4].instr.rom);
    $readmemh("instr_node_5.hex",   mpcpu.cpu[5].instr.rom);
    $readmemh("instr_node_6.hex",   mpcpu.cpu[6].instr.rom);
    $readmemh("instr_node_7.hex",   mpcpu.cpu[7].instr.rom);
    $readmemh("instr_node_8.hex",   mpcpu.cpu[8].instr.rom);
    $readmemh("instr_node_9.hex",   mpcpu.cpu[9].instr.rom);
    $readmemh("instr_node_10.hex", mpcpu.cpu[10].instr.rom);
    $readmemh("instr_node_11.hex", mpcpu.cpu[11].instr.rom);
    $readmemh("instr_node_12.hex", mpcpu.cpu[12].instr.rom);
    $readmemh("instr_node_13.hex", mpcpu.cpu[13].instr.rom);
    $readmemh("instr_node_14.hex", mpcpu.cpu[14].instr.rom);
    $readmemh("instr_node_15.hex", mpcpu.cpu[15].instr.rom);

    $readmemh("ram_image_0.hex", mpcpu.ram[0].generate_rams[0].coupled_ram.ram);
    $readmemh("ram_image_1.hex", mpcpu.ram[1].generate_rams[0].coupled_ram.ram);
    $readmemh("ram_image_2.hex", mpcpu.ram[2].generate_rams[0].coupled_ram.ram);
    $readmemh("ram_image_3.hex", mpcpu.ram[3].generate_rams[0].coupled_ram.ram);
    $readmemh("ram_image_4.hex", mpcpu.ram[4].generate_rams[0].coupled_ram.ram);

    mpcpu.ram[10].generate_rams[0].coupled_ram.ram  [0:3] = '{1, 0, 0, 0};
    mpcpu.ram[10].generate_rams[0].coupled_ram.ram  [4:7] = '{1, 0, 0, 0};
    mpcpu.ram[10].generate_rams[0].coupled_ram.ram [8:11] = '{1, 0, 0, 0};
    mpcpu.ram[10].generate_rams[0].coupled_ram.ram[12:15] = '{1, 0, 0, 0};
    mpcpu.ram[10].generate_rams[0].coupled_ram.ram[16:19] = '{2, 0, 0, 0};
    mpcpu.ram[10].generate_rams[0].coupled_ram.ram[20:23] = '{1, 0, 0, 0};
    mpcpu.ram[10].generate_rams[0].coupled_ram.ram[24:27] = '{1, 0, 0, 0};
    mpcpu.ram[10].generate_rams[0].coupled_ram.ram[28:31] = '{1, 0, 0, 0};
    mpcpu.ram[10].generate_rams[0].coupled_ram.ram[32:35] = '{1, 0, 0, 0};

    clk = 1;
    ram_loaded = 0;
    simulation_finished = 0;

    while (!simulation_finished) begin
        @(posedge clk);
    end

    $writememh("mem_dump_0.hex",   mpcpu.ram[0].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_1.hex",   mpcpu.ram[1].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_2.hex",   mpcpu.ram[2].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_3.hex",   mpcpu.ram[3].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_4.hex",   mpcpu.ram[4].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_5.hex",   mpcpu.ram[5].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_6.hex",   mpcpu.ram[6].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_7.hex",   mpcpu.ram[7].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_8.hex",   mpcpu.ram[8].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_9.hex",   mpcpu.ram[9].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_10.hex", mpcpu.ram[10].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_11.hex", mpcpu.ram[11].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_12.hex", mpcpu.ram[12].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_13.hex", mpcpu.ram[13].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_14.hex", mpcpu.ram[14].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_15.hex", mpcpu.ram[15].generate_rams[0].coupled_ram.ram);

    ram_loaded = 1;
end
    
endmodule