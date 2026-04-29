import cocotb
from cocotb.triggers import RisingEdge, Timer, First
from cocotb.simulator import get_sim_time

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