import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotbext.uart import UartSink

@cocotb.test
async def test(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start())

    source = UartSink(dut.tx_o, baud=100_000_000, bits=8)

    dut.arstn_i.value = 0
    dut.data_valid_i.value = 0
    await RisingEdge(dut.clk_i)
    dut.arstn_i.value = 1

    for i in range(256):
        dut.data_valid_i.value = 1
        dut.data_i.value = i
        await RisingEdge(dut.clk_i)
        dut.data_valid_i.value = 0

        for j in range(100):
            await RisingEdge(dut.clk_i)