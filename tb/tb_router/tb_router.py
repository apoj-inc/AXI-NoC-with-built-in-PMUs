import cocotb
from cocotb.triggers import RisingEdge, Combine
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster, AxiBus
from cocotb.handle import Force

from random import randint

class AxiWrapper:

    def __init__(self, dut, i):

        self._log = dut._log
        self._name = dut._name

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


async def axi_read_write(dut, axi_master, data, id, channel):
    
    await axi_master.write(0x00000000, data, awid=id)
    await axi_master.read(0x00000000, 8, arid=id)


@cocotb.test
async def test(dut):
    cocotb.start_soon(Clock(dut.aclk, 1, units="ns").start())

    axi_master = [AxiMaster(AxiBus.from_prefix(AxiWrapper(dut, i), ""), dut.aclk, dut.aresetn, reset_active_level=False) for i in range(5)]
    
    dut.aresetn.value = 0
    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)
    dut.aresetn.value = 1
    await RisingEdge(dut.aclk)

    for i in range(10):
        processes = []
        datas = [b'12345678', b'87654321', b'18273645', b'81726354', b'12348765']
        ids = [5, 2, 6, 8, 4]
        for j in range(5):
            if randint(0, 1):
                processes.append(cocotb.start_soon(axi_read_write(dut, axi_master[j], datas[j], ids[j], 0)))
        if len(processes) == 0:
                processes.append(cocotb.start_soon(axi_read_write(dut, axi_master[0], datas[0], ids[0], 0)))
        await Combine (
            *processes
        )

    for i in range(10):
        await RisingEdge(dut.aclk)