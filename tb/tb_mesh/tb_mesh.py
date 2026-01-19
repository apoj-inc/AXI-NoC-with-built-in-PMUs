import cocotb
from cocotb.triggers import RisingEdge, Combine, Timer, First
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster, AxiBus

from random import randint

class AxiWrapper:

    def __init__(self, dut, i):

        self._log = dut._log
        self._name = f"kal {i}"

        self.awready = dut.awready[i]
        self.awvalid = dut.awvalid[i]
        self.awid = dut.awid[i]
        self.awaddr = dut.awaddr[i]
        self.awlen = dut.awlen[i]
        self.awsize = dut.awsize[i]
        self.awburst = dut.awburst[i]
        self.wready = dut.wready[i]
        self.wvalid = dut.wvalid[i]
        self.wdata = dut.wdata[i]
        self.wstrb = dut.wstrb[i]
        self.wlast = dut.wlast[i]
        self.bvalid = dut.bvalid[i]
        self.bid = dut.bid[i]
        self.bready = dut.bready[i]
        self.arready = dut.arready[i]
        self.arvalid = dut.arvalid[i]
        self.arid = dut.arid[i]
        self.araddr = dut.araddr[i]
        self.arlen = dut.arlen[i]
        self.arsize = dut.arsize[i]
        self.arburst = dut.arburst[i]
        self.rvalid = dut.rvalid[i]
        self.rid = dut.rid[i]
        self.rdata = dut.rdata[i]
        self.rlast = dut.rlast[i]
        self.rready = dut.rready[i]


async def axi_read_write(dut, axi_master, addr, data, id, channel):
    
    await axi_master.write(addr, data, awid=id)
    await axi_master.read(addr, 16, arid=id)


@cocotb.test
async def feedback_loop(dut):
    
    dut.aresetn.value = 0
    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)
    dut.aresetn.value = 1
    axi_master = [AxiMaster(AxiBus.from_prefix(AxiWrapper(dut, i), ""), dut.aclk, dut.aresetn, reset_active_level=False) for i in range(16)]
    await RisingEdge(dut.aclk)

    processes = []
    datas = [b'0000000000000000', b'1111111111111111', b'2222222222222222', b'3333333333333333', b'4444444444444444',
             b'5555555555555555', b'6666666666666666', b'7777777777777777', b'8888888888888888', b'9999999999999999',
             b'1010101010101010', b'1111111111111111', b'1212121212121212', b'1313131313131313', b'1414141414141414',
             b'1515151515151515'] * 10
    addrs = [32 * i for i in range(100)]
    for i in range(50):
        processes.append(cocotb.start_soon(axi_read_write(dut, axi_master[0], addrs[i * 2], datas[i * 2], 2, 0)))
        processes.append(cocotb.start_soon(axi_read_write(dut, axi_master[1], addrs[i * 2 + 1], datas[i * 2 + 1], 1, 0)))

    timeout = Timer(50_000, units='ns')

    result = await First(
        timeout,
        Combine (*processes)
    )

    assert result is not timeout, "Design has hung!"

    for _ in range(10):
        await RisingEdge(dut.aclk)


@cocotb.test
async def test_all_in_one(dut):
    
    dut.aresetn.value = 0
    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)
    dut.aresetn.value = 1
    await RisingEdge(dut.aclk)

    axi_master = [AxiMaster(AxiBus.from_prefix(AxiWrapper(dut, i), ""), dut.aclk, dut.aresetn, reset_active_level=False) for i in range(16)]

    processes = []
    datas = [b'0000000000000000', b'1111111111111111', b'2222222222222222', b'3333333333333333', b'4444444444444444',
             b'5555555555555555', b'6666666666666666', b'7777777777777777', b'8888888888888888', b'9999999999999999',
             b'1010101010101010', b'1111111111111111', b'1212121212121212', b'1313131313131313', b'1414141414141414',
             b'1515151515151515'] * 10
    addrs = [32 * i for i in range(16)]
    for j in range(36):
        processes.append(cocotb.start_soon(axi_read_write(dut, axi_master[j % 16], addrs[j % 16], datas[j % 16], 5, 0)))

    timeout = Timer(50_000, units='ns')

    result = await First(
        timeout,
        Combine (*processes)
    )

    assert result is not timeout, "Design has hung!"

    for _ in range(10):
        await RisingEdge(dut.aclk)


@cocotb.test
async def test_random(dut):
    
    dut.aresetn.value = 0
    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)
    dut.aresetn.value = 1
    await RisingEdge(dut.aclk)

    axi_master = [AxiMaster(AxiBus.from_prefix(AxiWrapper(dut, i), ""), dut.aclk, dut.aresetn, reset_active_level=False) for i in range(9)]

    for i in range(1000):
        cocotb.log.info(f"pass {i}")
        processes = []
        datas = [b'0000000000000000', b'1111111111111111', b'2222222222222222', b'3333333333333333',
                 b'4444444444444444', b'5555555555555555', b'6666666666666666', b'7777777777777777', b'8888888888888888']
        addrs = [32 * i for i in range(9)]
        for j in range(36):
            id = randint(1, 9)
            processes.append(cocotb.start_soon(axi_read_write(dut, axi_master[j % 9], addrs[j % 9], datas[j % 9], id, 0)))

    timeout = Timer(50_000, units='ns')

    result = await First(
        timeout,
        Combine (*processes)
    )

    assert result is not timeout, "Design has hung!"

    for _ in range(10):
        await RisingEdge(dut.aclk)