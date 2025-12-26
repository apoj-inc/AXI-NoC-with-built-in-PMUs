# test_my_design.py (simple)

import cocotb
from cocotb.triggers import Timer, RisingEdge

import random

async def generate_clock(dut):
    """Generate clock pulses."""

    for _ in range(10**32):
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")

async def send_uart(dut, data_to_send):
    for _ in range(10**32):
        await RisingEdge(dut.clk)
        if dut.tx_data_ready.value == 1:
            break
    assert dut.tx_data_ready.value == 1

    dut.tx_data_valid.value = 1
    dut.tx_data.value = data_to_send

    await RisingEdge(dut.clk)
    dut.tx_data_valid.value = 0
    dut.tx_data.value = 0

    for _ in range(10**31):
        await RisingEdge(dut.clk)
        if dut.rx_data_valid.value == 1:
            break
    assert dut.rx_data_valid.value == 1

    dut.rx_data_ready.value = 1
    await RisingEdge(dut.clk)
    dut.rx_data_ready.value = 0
    return dut.rx_data.value.to_unsigned()

@cocotb.test()
async def uart_test(dut):
    dut.rst_n.value = 0
    dut.tx_data_valid.value = 0
    dut.rx_data_ready.value = 0
    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    for _ in range(10):
        data_to_send = random.randint(0,255)
        data_recieved = await send_uart(dut, data_to_send)

        assert data_to_send == data_recieved

