import cocotb
from cocotb.triggers import RisingEdge, Combine
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster, AxiBus
from cocotb.handle import Force, Release

@cocotb.test
async def test_demux(dut):
    clock = Clock(dut.ACLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.WSTRB.value = 0xF

    dut.ARESETn.value = 0
    await RisingEdge(dut.ACLK)
    await RisingEdge(dut.ACLK)
    dut.ARESETn.value = 1
    await RisingEdge(dut.ACLK)

    axi_master = AxiMaster(
        AxiBus.from_prefix(dut, ""),
        dut.ACLK, reset=dut.ARESETn,
        reset_active_level=False
          )

    await Combine(
        cocotb.start_soon(axi_master.write(0x00000000, b'test', awid=0)),
        cocotb.start_soon(axi_master.write(0x00000004, b'dead', awid=1)),
        cocotb.start_soon(axi_master.write(0x00000008, b'beef', awid=2))
    )

    await Combine(
        cocotb.start_soon(axi_master.read(0x00000000, 4, arid=0)),
        cocotb.start_soon(axi_master.read(0x00000004, 4, arid=1)),
        cocotb.start_soon(axi_master.read(0x00000008, 4, arid=2))
    )
