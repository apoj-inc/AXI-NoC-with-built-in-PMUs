import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster, AxiBus

@cocotb.test
async def test_ram(dut):
    clock = Clock(dut.aclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    axi_master = AxiMaster(AxiBus.from_prefix(dut, ""), dut.aclk, reset=dut.aresetn, reset_active_level=False)

    dut.kalstrb.value = 0b1111

    dut.aresetn.value = 0
    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)
    dut.aresetn.value = 1
    await RisingEdge(dut.aclk)

    await axi_master.write(0x00000000, bytes(24))

    dut.kalstrb.value = 0b0101

    await axi_master.write(0x00000000, b'testbeefdeadtestdeadbeef')

    await axi_master.read(0x00000000, 24)

    for _ in range(10):
        await RisingEdge(dut.aclk)
