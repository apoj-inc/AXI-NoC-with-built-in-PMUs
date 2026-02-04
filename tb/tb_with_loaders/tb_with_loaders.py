import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

import numpy as np

@cocotb.test
async def test(dut):
    cocotb.start_soon(Clock(dut.aclk, 1, units="ns").start())

    dut.aresetn.value = 0
    for i in range(16):
        dut.pmu_addr_i[i].value = 0
        dut.resp_wait_i[i].value = 0
        dut.id_i[i].value = 0
        dut.write_i[i].value = 0
        dut.axlen_i[i].value = 0
        dut.fifo_push_i[i].value = 0
    dut.start_i.value = 0

    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)
    dut.aresetn.value = 1
    await RisingEdge(dut.aclk)

    for i in range(0, 16):
        for _ in range(32):
            dut.fifo_push_i[i].value = 1
            dut.resp_wait_i[i].value = int(np.random.choice([0, 1], p=[0.8, 0.2]))
            dut.id_i[i].value = int(np.random.randint(1, 16))
            dut.write_i[i].value = 1
            dut.axlen_i[i].value = int(np.random.randint(0, 7))
            await RisingEdge(dut.aclk)

        for _ in range(32):
            dut.fifo_push_i[i].value = 1
            dut.resp_wait_i[i].value = int(np.random.choice([0, 1], p=[0.8, 0.2]))
            dut.id_i[i].value = int(np.random.randint(1, 16))
            dut.write_i[i].value = 0
            dut.axlen_i[i].value = int(np.random.randint(0, 7))
            await RisingEdge(dut.aclk)

        dut.fifo_push_i[i].value = 0

    dut.start_i.value = 1
    await RisingEdge(dut.aclk)
    dut.start_i.value = 0

    for _ in range(2000):
        await RisingEdge(dut.aclk)