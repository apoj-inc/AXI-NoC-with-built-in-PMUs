import cocotb
from cocotb.triggers import RisingEdge, First
from cocotb.clock import Clock
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamFrame

async def send_multiple_frames(axis_source, data, n):
    for _ in range(n):
        frame = AxiStreamFrame(
            data,
            tx_complete=Event()
        )
        await axis_source.send(frame)
        await frame.tx_complete.wait()

@cocotb.test
async def test(dut):

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

    cocotb.start_soon(random_ready(dut))
    await RisingEdge(dut.clk)

    axis_sinks[0].pause()
    axis_sinks[1].pause()

    single_channel = send_multiple_frames(axis_sources[-1], 'dead', 2)

    multiple = []
    for i in range(2):
        multiple.append(
            AxiStreamFrame(
                'beef',
                tx_complete=Event()
                )
            )
        axis_sources[i].send(multiple[i])
    
    await single_channel
    assert axis_sources[0].idle, 'First source didn\'t complete the transaction'
    assert axis_sources[1].idle, 'First source didn\'t complete the transaction'
