import cocotb
from cocotb.triggers import RisingEdge, Timer, First

async def wait_to_finish(dut):
    for _ in range(10000):
        await RisingEdge(dut.ACLK)
        if dut.finished.value: return

@cocotb.test
async def test(dut):

    timeout = Timer(10_000_000, units='ns')

    result = await First(timeout, cocotb.start_soon(wait_to_finish(dut)))
    assert result is not timeout, "Design has hung!"
