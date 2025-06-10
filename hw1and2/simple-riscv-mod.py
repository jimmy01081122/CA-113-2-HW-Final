
import m5
from m5.objects import *
# from common import SimpleOpts
import argparse

parser = argparse.ArgumentParser()

# SimpleOpts.add_option("binary", required=True, help="Binary to run")
parser.add_argument("binary", help="Binary to run")
parser.add_argument("--debug", action="store_true", help="Enable debug flags")

# args = SimpleOpts.parse_args()
args = parser.parse_args()

system = System()

system.clk_domain = SrcClockDomain()
system.clk_domain.clock = "1GHz"
system.clk_domain.voltage_domain = VoltageDomain()

system.mem_mode = "timing"
system.mem_ranges = [AddrRange("512MiB")]
system.cpu = RiscvTimingSimpleCPU()
system.cpu.isa = RiscvISA(riscv_type="RV32")

system.membus = SystemXBar()

system.cpu.icache_port = system.membus.cpu_side_ports
system.cpu.dcache_port = system.membus.cpu_side_ports

system.cpu.createInterruptController()

system.mem_ctrl = MemCtrl()
system.mem_ctrl.dram = DDR3_1600_8x8()
system.mem_ctrl.dram.range = system.mem_ranges[0]
system.mem_ctrl.port = system.membus.mem_side_ports

system.system_port = system.membus.cpu_side_ports


system.workload = SEWorkload.init_compatible(args.binary)

process = Process()
process.cmd = [args.binary]
system.cpu.workload = process
system.cpu.createThreads()

root = Root(full_system=False, system=system)
m5.instantiate()

print(f"Beginning simulation!")
exit_event = m5.simulate()
print(f"Exiting @ tick {m5.curTick()} because {exit_event.getCause()}")
