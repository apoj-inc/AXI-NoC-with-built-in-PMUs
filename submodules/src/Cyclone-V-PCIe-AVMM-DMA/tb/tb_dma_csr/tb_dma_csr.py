import cocotb
from cocotb.triggers import RisingEdge, Timer, First

from random import randint

@cocotb.test
async def test(dut):
    dut.random_seed.value = randint(0, 2**31-1)
    await RisingEdge(dut.clk)

    task_awaiter = RisingEdge(dut.test_done)
    timeout = Timer(300_000, unit='ns')

    result = await First(
        timeout,
        task_awaiter
    )

    assert result is not timeout, "The design has hung!"

    if (dut.error.value):
        raise Exception()