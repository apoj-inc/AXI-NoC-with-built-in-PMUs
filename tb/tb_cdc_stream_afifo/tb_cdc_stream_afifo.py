import cocotb
from cocotb.triggers import RisingEdge
from random import randint

@cocotb.test
async def test(dut):
    dut.random_seed.value = randint(0, 2**31-1)
    await RisingEdge(dut.clk_wr)
    while not dut.test_done.value:
        await RisingEdge(dut.clk_wr)

    if (dut.error.value):
        raise Exception()