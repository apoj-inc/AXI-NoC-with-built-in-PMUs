import cocotb
from cocotb.triggers import RisingEdge, Timer, First
from cocotb.clock import Clock
from cocotbext.uart import UartSource, UartSink

import random

@cocotb.test
async def test(dut):

    async def cnt_ret(source, sink):
        while True:
            await source.write(int.to_bytes(5, 1, 'little'))
            await source.wait()
            s = sum(await sink.read(1))
            s += sum(await sink.read(1))
            if s == 510:
                return
    
    cocotb.start_soon(Clock(dut.clk_i, 20, 'ns').start())

    dut.arstn_i.value = 0
    await RisingEdge(dut.clk_i)
    dut.arstn_i.value = 1

    source = UartSource(dut.rx_i, baud=115_200, bits=8)
    sink = UartSink(dut.tx_o, baud=115_200, bits=8)

    await source.write(int.to_bytes(1, 1, 'little'))
    await source.wait()
    await source.write(int.to_bytes(32, 1, 'little'))
    await source.wait()

    await sink.read()

    await source.write(int.to_bytes(2, 1, 'little'))
    await source.wait()
    await source.write(int.to_bytes(32, 1, 'little'))
    await source.wait()

    for _ in range(32):
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

    cocotb.log.info("First timer")
    timeout = Timer(100_000*20, unit='ns')

    result = await First(
        timeout,
        cocotb.start_soon(
           cnt_ret(source, sink) 
        )
    )

    assert result is not timeout, "Design has hung!"

    await source.write(int.to_bytes(7, 1, 'little'))
    await source.wait()
    await source.write(int.to_bytes(3, 1, 'little'))
    await source.wait()
    await source.write(int.to_bytes(1, 1, 'little'))
    await source.wait()

    for i in range(3):
        await source.write(int.to_bytes(7, 1, 'little'))
        await source.wait()
        await source.write(int.to_bytes(2, 1, 'little'))
        await source.wait()
        await source.write(int.to_bytes(i, 1, 'little'))
        await source.wait()

        cocotb.log.info(f"Second timer {i}")

        timeout = Timer(2_000_000*20, unit='ns')

        result = await First(
            timeout,
            cocotb.start_soon(
                cnt_ret(source, sink) 
            )
        )

        assert result is not timeout, "Design has hung!"
