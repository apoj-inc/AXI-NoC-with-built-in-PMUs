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

datas = [b'01', b'02', b'03', b'04', b'05', b'06', b'07', b'08',
        b'09', b'10', b'12', b'13', b'14', b'15', b'16', b'17']
addrs = [randint(0, 2**AXI_ADDR_WIDTH) for i in range(ROUTERS_COUNT)]

widths = [1, 2, 4, 8]
node_count = [1, 2, 4, 9]
depths = [1, 2, 4, 8, 16, 32]


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
    
    filename = "pmu_dump_dual_parallel.json"

    with open(filename, "w+") as f:
        f.write(f"{{\n")

    for data_bytes in widths:
        with open(filename, "a") as f:
            f.write(f"    \"DATA_WIDTH = {data_bytes} bytes\": {{\n")

        for active_nodes in node_count:
            with open(filename, "a") as f:
                f.write(f"        \"ACTIVE_NODE_COUNT = {active_nodes}\": {{\n")

            for depth in depths:
                cocotb.log.info(f"depth {depth}")
                with open(filename, "a") as f:
                    f.write(f"            \"REQUEST_DEPTH = {depth}\": {{\n")

                for i in range(4):
                        
                    cocotb.log.info(f"pass {i}")

                    cores = [core for core in range(ROUTERS_COUNT)]
                    active_cores = []
                    for _ in range(active_nodes):
                        random_element = choice(cores)
                        active_cores.append(random_element)
                        cores.remove(random_element)

                    with open(filename, "a") as f:
            
                        dut.aresetn.value = 0
                        await RisingEdge(dut.aclk)
                        await RisingEdge(dut.aclk)
                        dut.aresetn.value = 1
                        await RisingEdge(dut.aclk)
                        superprocess = []

                        for j in active_cores:
                            superprocess.append(cocotb.start_soon(axi_write(axi_master[j % ROUTERS_COUNT], j, depth, 32, data_bytes)))

                        await Combine (
                            *superprocess
                        )
                        await RisingEdge(dut.aclk)

                        f.write(f"                \"PASS {i} WRITE\": {{\n")
                        for node in active_cores:
                            pmu_snapshots_w = {
                                'idles'       : dut.map_wires[node].pmu.wc_u.idle.value.integer,
                                'aw_stall'    : dut.map_wires[node].pmu.wc_u.aw_stall.value.integer,
                                'aw_handshake': dut.map_wires[node].pmu.wc_u.aw_handshake.value.integer,
                                'wvalid_stall': dut.map_wires[node].pmu.wc_u.wvalid_stall.value.integer,
                                'wready_stall': dut.map_wires[node].pmu.wc_u.wready_stall.value.integer,
                                'w_handshake' : dut.map_wires[node].pmu.wc_u.w_handshake.value.integer,
                                'bvalid_stall': dut.map_wires[node].pmu.wc_u.bvalid_stall.value.integer,
                                'bready_stall': dut.map_wires[node].pmu.wc_u.bready_stall.value.integer,
                                'b_handshake' : dut.map_wires[node].pmu.wc_u.b_handshake.value.integer
                            }
                            total_write_clocks = dut.map_wires[node].pmu.clock_counter.value.integer

                            write_snapshot = {
                                'W': pmu_snapshots_w,
                                'Wclk': total_write_clocks,
                            }

                            f.write(f"                    \"NODE {node}\": {json.dumps(write_snapshot)}{'' if node == active_cores[-1] else ','}\n")

                        dut.aresetn.value = 0
                        await RisingEdge(dut.aclk)
                        await RisingEdge(dut.aclk)
                        dut.aresetn.value = 1
                        await RisingEdge(dut.aclk)
                        superprocess = []

                        for j in active_cores:
                            superprocess.append(cocotb.start_soon(axi_read(axi_master[j % ROUTERS_COUNT], j, depth, 32, data_bytes)))

                        await Combine (
                            *superprocess
                        )
                        await RisingEdge(dut.aclk)

                        f.write(f"                }},\n")
                        f.write(f"                \"PASS {i} READ\": {{\n")
                        for node in active_cores:
                            pmu_snapshots_r = {
                                'idles'       : dut.map_wires[node].pmu.rc_u.idle.value.integer,
                                'ar_stall'    : dut.map_wires[node].pmu.rc_u.ar_stall.value.integer,
                                'ar_handshake': dut.map_wires[node].pmu.rc_u.ar_handshake.value.integer,
                                'rvalid_stall': dut.map_wires[node].pmu.rc_u.rvalid_stall.value.integer,
                                'rready_stall': dut.map_wires[node].pmu.rc_u.rready_stall.value.integer,
                                'r_handshake' : dut.map_wires[node].pmu.rc_u.r_handshake.value.integer
                            }
                            total_read_clocks = dut.map_wires[node].pmu.clock_counter.value.integer

                            read_snapshot = {
                                'R': pmu_snapshots_r,
                                'Rclk': total_read_clocks,
                            }

                            f.write(f"                    \"NODE {node}\": {json.dumps(read_snapshot)}{'' if node == active_cores[-1] else ','}\n")
                        f.write(f"                }}{'' if i == 3 else ','}\n")


                with open(filename, "a") as f:
                    f.write(f"            }}{'' if depth == depths[-1] else ','}\n")

            with open(filename, "a") as f:
                f.write(f"        }}{'' if active_nodes == node_count[-1] else ','}\n")
        
        with open(filename, "a") as f:
            f.write(f"    }}{'' if data_bytes == widths[-1] else ','}\n")
    
    with open(filename, "a") as f:
        f.write(f"}}\n")

    a = ""
    with open(filename, "r") as f:
        a = f.read()
    b = json.loads(a)