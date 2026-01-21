module tb_cpu_tb;

logic clk;
logic rst_n;

tb_cpu dut (clk, rst_n);

always #1 clk = !clk;

initial begin
    $readmemh("single_core.hex", dut.cpu.instr.rom);
    $readmemh("single_image.hex", dut.ram.generate_rams[0].coupled_ram.ram);
    
    dut.ram.generate_rams[0].coupled_ram.ram[40960:40963] = '{1, 0, 0, 0};
    dut.ram.generate_rams[0].coupled_ram.ram[40964:40967] = '{1, 0, 0, 0};
    dut.ram.generate_rams[0].coupled_ram.ram[40968:40971] = '{1, 0, 0, 0};
    dut.ram.generate_rams[0].coupled_ram.ram[40972:40975] = '{1, 0, 0, 0};
    dut.ram.generate_rams[0].coupled_ram.ram[40976:40979] = '{2, 0, 0, 0};
    dut.ram.generate_rams[0].coupled_ram.ram[40980:40983] = '{1, 0, 0, 0};
    dut.ram.generate_rams[0].coupled_ram.ram[40984:40987] = '{1, 0, 0, 0};
    dut.ram.generate_rams[0].coupled_ram.ram[40988:40991] = '{1, 0, 0, 0};
    dut.ram.generate_rams[0].coupled_ram.ram[40992:40995] = '{1, 0, 0, 0};

    clk = 1;
    rst_n = 0;
    #25;
    rst_n = 1;

    for (int i = 0; i < 100; i++) begin
        $display("Progress: %d/100", i);
        for (int j = 0; j < 10000; j++) begin
            @(posedge clk);
        end
    end

    $writememh("mem_dump_tb.hex", dut.ram.generate_rams[0].coupled_ram.ram);
    $finish;
end
    
endmodule