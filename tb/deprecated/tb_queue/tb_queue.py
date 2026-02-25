import cocotb
from cocotb.triggers import RisingEdge, Event
from cocotb.clock import Clock
from cocotbext.axi import AxiStreamSource, AxiStreamSink, AxiStreamBus, AxiStreamFrame
from cocotb.handle import Force, Release
from random import randint

async def random_ready(dut):

    dut.s_tready.value = 0
    tvalids = 0
    while tvalids != 16:
        if dut.m_tvalid.value == 1:
            tvalids += 1
        await RisingEdge(dut.clk)

    for _ in range(10):
        await RisingEdge(dut.clk)

    for _ in range(50):
        dut.s_tready.value = randint(0, 1)
        await RisingEdge(dut.clk)
    
    dut.s_tready.value = 1

@cocotb.test
async def test_queue(dut):

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    axis_source = AxiStreamSource(
        AxiStreamBus.from_prefix(dut, "m"),
        dut.clk, reset=dut.rst_n,
        reset_active_level=False
    )

    cocotb.start_soon(random_ready(dut))
    await RisingEdge(dut.clk)

    datas = [b'dead', b'beef', b'test', b'kal']

    for _ in range(40):
        for i in range(4):

            frame = AxiStreamFrame(
                datas[i],
                tx_complete=Event()
            )
            await axis_source.send(frame)
            await frame.tx_complete.wait()

            for i in range(randint(0, 10)):
                await RisingEdge(dut.clk)

    for i in range(10):
        await RisingEdge(dut.clk)

