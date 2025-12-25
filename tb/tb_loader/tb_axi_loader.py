import cocotb
from cocotb.triggers import RisingEdge, Combine
from cocotb.clock import Clock
from cocotbext.axi import AxiSlave, AxiBus, MemoryRegion

@cocotb.test
async def test(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, units='ns').start())

    axi_slave = AxiSlave(AxiBus.from_prefix(dut, ""), dut.clk_i, dut.arstn_i, reset_active_level=False, target=MemoryRegion(2**16))

    dut.arstn_i.value = 0

    dut.req_depth_i.value = 1
    dut.id_i.value = 0
    dut.write_i.value = 0
    dut.fifo_push_i.value = 0
    dut.start_i.value = 0

    await RisingEdge(dut.clk_i)
    dut.arstn_i.value = 1

    dut.fifo_push_i.value = 1
    for i in range(16):
        dut.id_i.value = i // 2
        dut.write_i.value = i % 2
        dut.axlen_i.value = i
        await RisingEdge(dut.clk_i)

    dut.fifo_push_i.value = 0
    dut.start_i.value = 1
    await RisingEdge(dut.clk_i)
    dut.start_i.value = 0

    for _ in range(100):
        await RisingEdge(dut.clk_i)

    dut.fifo_push_i.value = 1
    for i in range(16, 32):
        dut.id_i.value = i // 2
        dut.write_i.value = i % 2
        dut.axlen_i.value = i
        await RisingEdge(dut.clk_i)
    dut.fifo_push_i.value = 0

    for _ in range(500):
        await RisingEdge(dut.clk_i)