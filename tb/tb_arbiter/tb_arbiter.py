import cocotb
from cocotb.triggers import RisingEdge, Timer, First

async def wait_to_finish(dut):
    while True:
        await RisingEdge(dut.ACLK)
        if dut.finished.value: return

@cocotb.test
async def test(dut):

    timeout = Timer(100_000, unit='ns')

    result = await First(timeout, cocotb.start_soon(wait_to_finish(dut)))
    assert result is not timeout, "Design has hung!"
