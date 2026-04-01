import cocotb
from cocotb.triggers import RisingEdge, Combine
from cocotb.clock import Clock
from cocotbext.axi import AxiSlave, AxiBus, MemoryRegion

import random

@cocotb.test
async def test(dut):
    cocotb.start_soon(Clock(dut.clk_i, 2, unit='ns').start())

    dut.inj_period_en_i.value = 0
    dut.start_i.value = 0

    dut.arstn_i.value = 0
    await RisingEdge(dut.clk_i)
    dut.arstn_i.value = 1
    await RisingEdge(dut.clk_i)

    axi_slave = AxiSlave(AxiBus.from_prefix(dut, ""), dut.clk_i, dut.arstn_i, reset_active_level=False, target=MemoryRegion(2**16))

    for i in range(10):
        dut.fifo_push_i.value = 1
        for j in range(128):
            index = j // 2
            dut.write_i.value     = j % 2
            dut.resp_wait_i.value = index == 32
            dut.id_i.value        = index % 2**5
            dut.axaddr_i.value    = index % 2**12
            dut.axlen_i.value     = index % 8
            dut.wdata_i.value     = random.randint(0, 2**32-1)
            dut.wstrb_i.value     = 0xF
            await RisingEdge(dut.clk_i)
        dut.fifo_push_i.value = 0
        dut.inj_period_en_i.value = 1
        dut.inj_period_val_i.value = i + 1
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0
        dut.inj_period_en_i.value = 0
        await RisingEdge(dut.clk_i)

        while (dut.idle_o.value == 0):
            await RisingEdge(dut.clk_i)