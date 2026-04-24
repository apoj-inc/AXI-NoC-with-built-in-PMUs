import cocotb
from cocotb.triggers import RisingEdge, Event, Timer, First
from cocotb.clock import Clock
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamFrame

@cocotb.test
async def test_default(dut):

    clock = Clock(dut.ACLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.ARESETn.value = 0
    await RisingEdge(dut.ACLK)
    await RisingEdge(dut.ACLK)
    dut.ARESETn.value = 1

    axis_sources = []
    axis_sinks = []

    for i in range(4):
        axis_sources.append(
                AxiStreamSource(
                AxiStreamBus.from_prefix(dut, f'm{i}'),
                dut.ACLK, reset=dut.ARESETn,
                reset_active_level=False
            )
        )

        axis_sinks.append(
            AxiStreamSink(
                AxiStreamBus.from_prefix(dut, f's{i}'),
                dut.ACLK, reset=dut.ARESETn,
                reset_active_level=False
            )
        )

    axis_sinks[0].pause = 1

    await RisingEdge(dut.ACLK)

    single_channel = AxiStreamFrame(
            b'dead',
            tx_complete=Event()
        )

    await axis_sources[-1].send(
        single_channel
    )

    multiple = []

    multiple.append(
        AxiStreamFrame(
            b'bee1',
            tx_complete=Event()
            )
        )
    await axis_sources[0].send(multiple[0])
    
    multiple.append(
        AxiStreamFrame(
            b'bee2',
            tx_complete=Event()
            )
        )
    await axis_sources[1].send(multiple[1])

    timeout = Timer(1_000, unit='ns')

    result = await First(
        timeout,
        single_channel.tx_complete.wait()
    )

    assert result is not timeout, "The design has hung!"

    assert axis_sources[0].idle, 'First source didn\'t complete the transaction'
    assert axis_sources[1].idle, 'Second source didn\'t complete the transaction'


    for _ in range(3):
        await RisingEdge(dut.ACLK)

    assert axis_sinks[0].count() == 0,                   'The elements do not add up for sink 1'
    assert axis_sinks[1].recv_nowait().tdata == b'bee1', 'The elements do not add up for sink 2'
    assert axis_sinks[2].recv_nowait().tdata == b'bee2', 'The elements do not add up for sink 3'
    assert axis_sinks[3].recv_nowait().tdata == b'dead', 'The elements do not add up for sink 4'


@cocotb.test
async def test_ADHD(dut):

    clock = Clock(dut.ACLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.ARESETn.value = 0
    await RisingEdge(dut.ACLK)
    await RisingEdge(dut.ACLK)
    dut.ARESETn.value = 1

    axis_sources = []
    axis_sinks = []

    for i in range(4):
        axis_sources.append(
                AxiStreamSource(
                AxiStreamBus.from_prefix(dut, f'm{i}'),
                dut.ACLK, reset=dut.ARESETn,
                reset_active_level=False
            )
        )

        axis_sinks.append(
            AxiStreamSink(
                AxiStreamBus.from_prefix(dut, f's{i}'),
                dut.ACLK, reset=dut.ARESETn,
                reset_active_level=False
            )
        )

    axis_sinks[0].pause = 1

    await RisingEdge(dut.ACLK)

    single_channel = AxiStreamFrame(
            b'dead',
            tx_complete=Event()
        )

    await axis_sources[-1].send(
        single_channel
    )

    multiple = []

    multiple.append(
        AxiStreamFrame(
            b'bee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee24',
            tx_complete=Event()
            )
        )
    await axis_sources[0].send(multiple[0])
    
    multiple.append(
        AxiStreamFrame(
            b'bee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee14',
            tx_complete=Event()
            )
        )
    await axis_sources[1].send(multiple[1])

    timeout = Timer(1_000, unit='ns')

    await RisingEdge(dut.ACLK)
    await RisingEdge(dut.ACLK)

    axis_sinks[0].pause = 0

    result = await First(
        timeout,
        multiple[0].tx_complete.wait()
    )

    assert result is not timeout, "The design has hung!"
    
    for _ in range(2):
        await RisingEdge(dut.ACLK)

    assert axis_sinks[0].count() == 0,                   'The elements do not add up for sink 1'
    assert axis_sinks[1].recv_nowait().tdata == b'bee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee24', 'The elements do not add up for sink 2'
    assert axis_sinks[2].recv_nowait().tdata == b'bee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee14', 'The elements do not add up for sink 3'
    assert axis_sinks[3].recv_nowait().tdata == b'dead', 'The elements do not add up for sink 4'
