import cocotb
from cocotb.triggers import RisingEdge, Combine
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster, AxiBus
from cocotb.handle import Force, Release

@cocotb.test
async def test(dut):
    cocotb.start_soon(Clock(dut.aclk, 1, units="ns").start())

    axi_master_0 = AxiMaster(AxiBus.from_prefix(dut, "a"), dut.aclk, reset=dut.aresetn, reset_active_level=False)
    axi_master_1 = AxiMaster(AxiBus.from_prefix(dut, "b"), dut.aclk, reset=dut.aresetn, reset_active_level=False)

    dut.aresetn.value = 0
    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)
    dut.aresetn.value = 1
    await RisingEdge(dut.aclk)

    await Combine(
        cocotb.start_soon(axi_master_0.write(0x00000000, b'testbeef', awid=0)),
        cocotb.start_soon(axi_master_0.write(0x00000000, b'testbeef', awid=2)),
        cocotb.start_soon(axi_master_1.write(0x00000008, b'deadyuyu', awid=1))
    )

    await Combine(
        cocotb.start_soon(axi_master_0.read(0x00000000, 8, arid=0)),
        cocotb.start_soon(axi_master_0.read(0x00000000, 8, arid=2)),
        cocotb.start_soon(axi_master_1.read(0x00000008, 8, arid=1))
    )


    for _ in range(10):
        await RisingEdge(dut.aclk)