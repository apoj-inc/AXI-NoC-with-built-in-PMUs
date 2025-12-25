import cocotb
from cocotb.triggers import RisingEdge, Combine
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster, AxiBus
from cocotb.handle import Force, Release

@cocotb.test
async def test_mux(dut):
    clock = Clock(dut.ACLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    axi_master_0 = AxiMaster(AxiBus.from_prefix(dut, "a"), dut.ACLK, reset=dut.ARESETn, reset_active_level=False)
    axi_master_1 = AxiMaster(AxiBus.from_prefix(dut, "b"), dut.ACLK, reset=dut.ARESETn, reset_active_level=False)
    axi_master_2 = AxiMaster(AxiBus.from_prefix(dut, "c"), dut.ACLK, reset=dut.ARESETn, reset_active_level=False)

    dut.a_WSTRB.value = 0xF
    dut.b_WSTRB.value = 0xF
    dut.c_WSTRB.value = 0xF

    dut.ARESETn.value = 0
    await RisingEdge(dut.ACLK)
    await RisingEdge(dut.ACLK)
    dut.ARESETn.value = 1
    await RisingEdge(dut.ACLK)

    await Combine(
        cocotb.start_soon(axi_master_0.write(0x00000000, b'testtest', awid=0)),
        cocotb.start_soon(axi_master_1.write(0x00000008, b'deaddead', awid=1)),
        cocotb.start_soon(axi_master_2.write(0x00000010, b'beefbeef', awid=2))
    )

    await Combine(
        cocotb.start_soon(axi_master_0.read(0x00000000, 8, arid=0)),
        cocotb.start_soon(axi_master_1.read(0x00000008, 8, arid=1)),
        cocotb.start_soon(axi_master_2.read(0x00000010, 8, arid=2))
    )
