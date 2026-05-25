import cocotb
from cocotb.triggers import RisingEdge, Combine
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster, AxiBus

from random import randint, choice, choices
import ast
import json


AXI_DATA_WIDTH   = 8 
AXI_ADDR_WIDTH   = 12
MAX_ROUTERS_X    = 3
MAX_ROUTERS_Y    = 3
ROUTERS_COUNT    = MAX_ROUTERS_X*MAX_ROUTERS_Y
AXI_MAX_ID_WIDTH = (ROUTERS_COUNT+1).bit_length()    
AXI_DATA_BYTES   = AXI_DATA_WIDTH / 8         

datas = [b'0', b'1', b'2', b'3', b'4', b'5', b'6', b'7',
        b'8', b'9', b'12', b'13', b'14', b'15', b'16', b'17']
addrs = [randint(0, 2**AXI_ADDR_WIDTH) for i in range(ROUTERS_COUNT)]

widths = [2, 4, 6, 8]
node_count = [1, 2, 4, 8, 9]
depths = [1, 9, 17, 25, 32]


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


async def axi_read(axi_master, core_num, depth, tran_count, data_bytes):

    for i in range(tran_count // depth):
        processes = []
        for j in range(depth):
            processes.append(cocotb.start_soon(axi_master.read(addrs[core_num], data_bytes, randint(1, ROUTERS_COUNT))))

        await Combine( *processes )



async def axi_write(axi_master, core_num, depth, tran_count, data_bytes):

    for i in range(tran_count // depth):
        processes = []
        for j in range(depth):
            processes.append(cocotb.start_soon(axi_master.write(addrs[core_num], datas[core_num] * data_bytes, randint(1, ROUTERS_COUNT))))

        await Combine( *processes )


@cocotb.test
async def test_random(dut):

    dut.aresetn.value = 0
    await RisingEdge(dut.aclk)
    
    axi_master = [AxiMaster(AxiBus.from_prefix(AxiWrapper(dut, i), ""), dut.aclk, dut.aresetn, reset_active_level=False) for i in range(ROUTERS_COUNT)]
    
    filename = "pmu_dump_dual_parallel.csv"

    with open(filename, "w+") as f:
        f.write(f"active_core_count,write_count,axlen,queue_depth,router_index,read_idle,read_outstanding,read_ar_stall,read_ar_handshake,read_rvalid_stall,read_rready_stall,read_r_handshake,write_idle,write_outstanding,write_responding,write_aw_stall,write_aw_handshake,write_wvalid_stall,write_wready_stall,write_w_handshake,write_bvalid_stall,write_bready_stall,write_b_handshake,clock_counter\n")

    for active_nodes in node_count:
        for data_bytes in widths:

            for depth in depths:
                cocotb.log.info(f"depth {depth}")

                for i in range(4):
                        
                    cocotb.log.info(f"pass {i}")

                    cores = [core for core in range(ROUTERS_COUNT)]
                    active_cores = []
                    for _ in range(active_nodes):
                        random_element = choice(cores)
                        active_cores.append(random_element)
                        cores.remove(random_element)

                        dut.aresetn.value = 0
                        await RisingEdge(dut.aclk)
                        await RisingEdge(dut.aclk)
                        dut.aresetn.value = 1
                        await RisingEdge(dut.aclk)
                        superprocess = []

                        for j in active_cores:
                            superprocess.append(cocotb.start_soon(axi_write(axi_master[j % ROUTERS_COUNT], j, depth, 63, data_bytes)))

                        await Combine (
                            *superprocess
                        )
                        await RisingEdge(dut.aclk)

                        for node in active_cores:
                            pmu_snapshots_w = {
                                'idles'       : dut.map_wires[node].pmu.wc_u.idle.value.integer,
                                'kal'         : 0,
                                'kal2'        : 0,
                                'aw_stall'    : dut.map_wires[node].pmu.wc_u.aw_stall.value.integer,
                                'aw_handshake': dut.map_wires[node].pmu.wc_u.aw_handshake.value.integer,
                                'wvalid_stall': dut.map_wires[node].pmu.wc_u.wvalid_stall.value.integer,
                                'wready_stall': dut.map_wires[node].pmu.wc_u.wready_stall.value.integer,
                                'w_handshake' : dut.map_wires[node].pmu.wc_u.w_handshake.value.integer,
                                'bvalid_stall': dut.map_wires[node].pmu.wc_u.bvalid_stall.value.integer,
                                'bready_stall': dut.map_wires[node].pmu.wc_u.bready_stall.value.integer,
                                'b_handshake' : dut.map_wires[node].pmu.wc_u.b_handshake.value.integer,
                                'clkcnt'      : dut.map_wires[node].pmu.clock_counter.value.integer
                            }
                            
                            data = f"{active_nodes},63,{data_bytes-1},{depth},{node},0,0,0,0,0,0,0"

                            for datum in pmu_snapshots_w:
                                data += f",{pmu_snapshots_w[datum]}"

                            with open(filename, "a") as f:
                                f.write(f"{data}\n")

                        dut.aresetn.value = 0
                        await RisingEdge(dut.aclk)
                        await RisingEdge(dut.aclk)
                        dut.aresetn.value = 1
                        await RisingEdge(dut.aclk)
                        superprocess = []

                        for j in active_cores:
                            superprocess.append(cocotb.start_soon(axi_read(axi_master[j % ROUTERS_COUNT], j, depth, 63, data_bytes)))

                        await Combine (
                            *superprocess
                        )
                        await RisingEdge(dut.aclk)
                        for node in active_cores:
                            pmu_snapshots_r = {
                                'idles'       : dut.map_wires[node].pmu.rc_u.idle.value.integer,
                                'kal'         : 0,
                                'ar_stall'    : dut.map_wires[node].pmu.rc_u.ar_stall.value.integer,
                                'ar_handshake': dut.map_wires[node].pmu.rc_u.ar_handshake.value.integer,
                                'rvalid_stall': dut.map_wires[node].pmu.rc_u.rvalid_stall.value.integer,
                                'rready_stall': dut.map_wires[node].pmu.rc_u.rready_stall.value.integer,
                                'r_handshake' : dut.map_wires[node].pmu.rc_u.r_handshake.value.integer
                            }
                            
                            data = f"{active_nodes},1,{data_bytes-1},{depth},{node}"

                            for datum in pmu_snapshots_r:
                                data += f",{pmu_snapshots_r[datum]}"
                            data += ",0,0,0,0,0,0,0,0,0,0,0"
                            data += f",{dut.map_wires[node].pmu.clock_counter.value.integer}"

                            with open(filename, "a") as f:
                                f.write(f"{data}\n")