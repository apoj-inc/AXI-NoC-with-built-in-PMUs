import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotbext.axi import AxiSlave, AxiBus, MemoryRegion

@cocotb.test
async def test(dut):

    # axi_slave = AxiSlave(AxiBus.from_prefix(dut, ""), dut.clk, dut.rst_n, reset_active_level=False, target=MemoryRegion(2**16))
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    for i in range(100):
        dut._log.info(f"Progress: {i}/100")
        for _ in range(10000):
            await RisingEdge(dut.clk)

    with open("mem_dump", "w+") as f:
        for i in range(2**16):
            f.write(f"{dut.ram.generate_rams[0].coupled_ram.ram[i].value.binstr}\n")