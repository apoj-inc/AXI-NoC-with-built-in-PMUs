import cocotb
from cocotb.triggers import RisingEdge

@cocotb.test
async def test(dut):
    await RisingEdge(dut.clk)
    while not dut.test_done.value:
        await RisingEdge(dut.clk)