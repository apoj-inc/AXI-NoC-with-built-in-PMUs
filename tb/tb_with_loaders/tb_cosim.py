import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotbext.uart import UartSource, UartSink

import random

@cocotb.test
async def test(dut):
    cocotb.start_soon(Clock(dut.clk_i, 20, 'ns').start())

    source = UartSource(dut.rx_i, baud=115_200, bits=8)
    sink = UartSink(dut.tx_o, baud=115_200, bits=8)

    dut.arstn_i.value = 0
    await RisingEdge(dut.clk_i)
    dut.arstn_i.value = 1

    await source.write(int.to_bytes(1, 1, 'little'))
    await source.wait()
    await source.write(int.to_bytes(32, 1, 'little'))
    await source.wait()

    for i in range(50000):
        await RisingEdge(dut.clk_i)

    await source.write(int.to_bytes(2, 1, 'little'))
    await source.wait()
    await source.write(int.to_bytes(32, 1, 'little'))
    await source.wait()

    for i in range(50000):
        await RisingEdge(dut.clk_i)

    for i in range(32):
        dest = random.randint(1, 16)

        await source.write(int.to_bytes(4, 1, 'little'))
        await source.wait()
        await source.write(int.to_bytes(2, 1, 'little'))
        await source.wait()
        await source.write(int.to_bytes(dest, 1, 'little'))
        await source.wait()
        await source.write(int.to_bytes(3, 1, 'little'))
        await source.wait()

        await source.write(int.to_bytes(3, 1, 'little'))
        await source.wait()
        await source.write(int.to_bytes(2, 1, 'little'))
        await source.wait()
        await source.write(int.to_bytes(dest, 1, 'little'))
        await source.wait()
        await source.write(int.to_bytes(1, 1, 'little'))
        await source.wait()

    await source.write(int.to_bytes(6, 1, 'little'))
    await source.wait()

    await source.write(int.to_bytes(5, 1, 'little'))
    await source.wait()

    for i in range(100000):
        await RisingEdge(dut.clk_i)

    await source.write(int.to_bytes(7, 1, 'little'))
    await source.wait()
    await source.write(int.to_bytes(3, 1, 'little'))
    await source.wait()
    await source.write(int.to_bytes(1, 1, 'little'))
    await source.wait()

    for i in range(500000):
        await RisingEdge(dut.clk_i)

    for i in range(19):
        await source.write(int.to_bytes(7, 1, 'little'))
        await source.wait()
        await source.write(int.to_bytes(2, 1, 'little'))
        await source.wait()
        await source.write(int.to_bytes(i, 1, 'little'))
        await source.wait()

        for i in range(500000):
            await RisingEdge(dut.clk_i)