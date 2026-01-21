import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotbext.uart import UartSink

@cocotb.test
async def test_uart_trans(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start())

    dut.arstn_i.value = 0
    dut.data_valid_i.value = 0
    await RisingEdge(dut.clk_i)
    dut.arstn_i.value = 1
    await RisingEdge(dut.clk_i)

    sink = UartSink(dut.tx_o, baud=100_000_000, bits=8)

    for i in range(256):
        assert dut.data_ready_o.value == 1
        dut.data_valid_i.value = 1
        dut.data_i.value = i
        await RisingEdge(dut.clk_i)
        await RisingEdge(dut.clk_i)
        dut.data_valid_i.value = 0
        assert dut.data_ready_o.value == 0

        for _ in range(100):
            await RisingEdge(dut.clk_i)
            if(dut.data_ready_o.value):
                break
        
        assert sink.read_nowait() == int.to_bytes(i, 1, 'little')
