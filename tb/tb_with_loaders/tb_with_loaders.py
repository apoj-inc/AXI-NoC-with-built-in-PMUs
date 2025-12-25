import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

from random import randint, choice, choices

class AxiWrapper:

    def __init__(self, dut, i):

        self._log = dut._log
        self._name = f"kal {i}"

        self.awready = dut.axi.AWREADY[i]
        self.awvalid = dut.axi.AWVALID[i]
        self.awid    = dut.axi.AWID[i]
        self.awaddr  = dut.axi.AWADDR[i]
        self.awlen   = dut.axi.AWLEN[i]
        self.awsize  = dut.axi.AWSIZE[i]
        self.awburst = dut.axi.AWBURST[i]
        self.wready  = dut.axi.WREADY[i]
        self.wvalid  = dut.axi.WVALID[i]
        self.wdata   = dut.axi.WDATA[i]
        self.wstrb   = dut.axi.WSTRB[i]
        self.wlast   = dut.axi.WLAST[i]
        self.bvalid  = dut.axi.BVALID[i]
        self.bid     = dut.axi.BID[i]
        self.bready  = dut.axi.BREADY[i]
        self.arready = dut.axi.ARREADY[i]
        self.arvalid = dut.axi.ARVALID[i]
        self.arid    = dut.axi.ARID[i]
        self.araddr  = dut.axi.ARADDR[i]
        self.arlen   = dut.axi.ARLEN[i]
        self.arsize  = dut.axi.ARSIZE[i]
        self.arburst = dut.axi.ARBURST[i]
        self.rvalid  = dut.axi.RVALID[i]
        self.rid     = dut.axi.RID[i]
        self.rdata   = dut.axi.RDATA[i]
        self.rlast   = dut.axi.RLAST[i]
        self.rready  = dut.axi.RREADY[i]

@cocotb.test
async def test(dut):
    cocotb.start_soon(Clock(dut.aclk, 1, units="ns").start())

    dut.aresetn.value = 0
    dut.req_depth_i.value = 32
    for i in range(16):
        dut.pmu_addr_i[i].value = 0
        dut.id_i[i].value = 0
        dut.write_i[i].value = 0
        dut.axlen_i[i].value = 0
        dut.fifo_push_i[i].value = 0
    dut.start_i.value = 0

    await RisingEdge(dut.aclk)
    dut.aresetn.value = 1
    await RisingEdge(dut.aclk)

    for i in range(16):
        for j in range(32):
            dut.fifo_push_i[i].value = 1
            dut.id_i[i].value = randint(1, 16)
            dut.write_i[i].value = 1
            dut.axlen_i[i].value = randint(0, 7)
            await RisingEdge(dut.aclk)
        dut.fifo_push_i[i].value = 0

    dut.start_i.value = 1
    await RisingEdge(dut.aclk)
    dut.start_i.value = 0

    for _ in range(2000):
        await RisingEdge(dut.aclk)
