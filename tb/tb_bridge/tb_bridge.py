import cocotb
from cocotb.triggers import RisingEdge, Combine
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster, AxiBus
from cocotb.handle import Force

async def axi_read_write(dut, axi_master, data, id, channel):
    
    if channel == 0:
        dut.a_kalstrb.value = Force(0xF)
    else:
        dut.b_kalstrb.value = Force(0xF)
        
    await axi_master.write(0x00000000, data, awid=id)

    await axi_master.read(0x00000000, 8, arid=id)

@cocotb.test
async def test(dut):
    cocotb.start_soon(Clock(dut.aclk, 1, units="ns").start())

    axi_master_1 = AxiMaster(AxiBus.from_prefix(dut, "a"), dut.aclk, reset=dut.aresetn, reset_active_level=False)
    axi_master_2 = AxiMaster(AxiBus.from_prefix(dut, "b"), dut.aclk, reset=dut.aresetn, reset_active_level=False)

    dut.aresetn.value = 0
    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)
    dut.aresetn.value = 1
    await RisingEdge(dut.aclk)

    await Combine (
        cocotb.start_soon(axi_read_write(dut, axi_master_1, b'12345678', 1, 0)),
        cocotb.start_soon(axi_read_write(dut, axi_master_2, b'87654321', 2, 1))
    )