import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

BLOCK_SIZE = 16
CLK_PERIOD_NS = 10
DEFAULT_MEM_DELAY = 6 # worst case 6 cycle delay
MAX_WAIT_CYCLES = 50

class MemoryModel:
    # Fake memory for sake of testbench
    
    def __init__(self, dut, latency = DEFAULT_MEM_DELAY):
        self.dut = dut
        self.latency = latency
        self.requests = [] #Block addresses that have been requested

    # Mem data is address of memory block
    def make_block(self, addr):
        base = addr & ~(BLOCK_SIZE - 1)
        block = 0

        # Repeat for number of words in block
        for i in range(BLOCK_SIZE // 4):
            # Ensures block is 128 bits, creates in 32 bit sections
            block |= ((base + 4 * i) & 0xFFFFFFFF) << (i * 32)
        return block

    async def run(self):
        dut = self.dut
        while True:
            await RisingEdge(dut.clk)
            if dut.mem_req.value == 1:
                # Store requested address
                addr = int(dut.mem_addr.value)
                self.requests.append(addr)
                dut._log.info(f"mem request for {addr:#010x}")

                # Simulated memory delay
                for _ in range(self.latency):
                    await RisingEdge(dut.clk)

                # Make data for memory address and output for one cycle
                dut.mem_data.value = self.make_block(addr)
                dut.mem_ready.value = 1
                await RisingEdge(dut.clk)
                dut.mem_ready.value = 0

# Helper function to setup entire testbench, returns memory model for handling requests 
async def setup(dut, first_addr, latency=DEFAULT_MEM_DELAY):
    # Start clk, reset cache, start memory model
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, units="ns").start())

    dut.rst_n.value = 0
    dut.cpu_addr.value = first_addr
    dut.mem_ready.value = 0
    dut.mem_data.value = 0

    for _ in range(3):
        await RisingEdge(dut.clk)

    mem = MemoryModel(dut, latency)
    cocotb.start_soon(mem.run())
    dut.rst_n.value = 1
    return mem

# Helper function to read instruction from cache, returns instruction and how many cycles it waited, built in timeout
async def read_instr(dut, addr, max_cycles=MAX_WAIT_CYCLES):
    dut.cpu_addr.value = addr
    for cycle in range(max_cycles):
        await RisingEdge(dut.clk)
        if dut.cache_hit.value == 1:
            return int(dut.cpu_instr.value), cycle
        assert int(dut.cpu_instr.value) == 0
    raise AssertionError(f"Timeout waiting for cache hit for addr {addr:#010x}")

@cocotb.test()
async def test_miss_then_hit(dut):
    # await forces program to wait until a value is returned
    mem = await setup(dut, first_addr=0xC)

    instr, cycles = await read_instr(dut, 0xC)
    
    assert instr == 0xC, f"Expected instruction 0xC, got {instr:#010x}"
    assert cycles >= mem.latency, f"Expected at least {DEFAULT_MEM_DELAY} cycles for miss"
    assert mem.requests == [0x0], f"Expected memory request for 0x0, got {mem.requests}"

    # first four addresses should be loaded
    for addr in (0x0, 0x4, 0x8, 0xC):
        instr, cycles = await read_instr(dut, addr)
        assert instr == addr, f"Expected instruction {addr:#010x}, got {instr:#010x}"
        assert cycles == 0, f"Expected 0 cycles for hit, got {cycles}"
    assert mem.requests == [0x0], f"Expected no additional memory requests, got {mem.requests}"

@cocotb.test()
async def test_index_replace(dut):
    mem = await setup(dut, first_addr=0xC)

    # Same as first test, need to fill cache index with initial data
    instr, cycles = await read_instr(dut, 0xC)

    # Initial cache fill
    assert instr == 0xC, f"Expected instruction 0xC, got {instr:#010x}"
    assert cycles >= mem.latency, f"Expected at least {DEFAULT_MEM_DELAY} cycles for miss"
    assert mem.requests == [0x0], f"Expected memory request for 0x0, got {mem.requests}"

    # Stored in same index, different tag, should be miss
    instr, cycles = await read_instr(dut, 0xA000000C)

    assert instr == 0xA000000C, f"Expected instruction 0xA000000C, got {instr:#010x}"
    assert cycles >= mem.latency, f"Expected at least {DEFAULT_MEM_DELAY} cycles for miss"
    assert mem.requests == [0x0, 0xA0000000], f"Expected memory request for 0xA0000000, got {mem.requests}"

    for addr in (0xA0000000, 0xA0000004, 0xA0000008, 0xA000000C):
            instr, cycles = await read_instr(dut, addr)
            assert instr == addr, f"Expected instruction {addr:#010x}, got {instr:#010x}"
            assert cycles == 0, f"Expected 0 cycles for hit, got {cycles}"
    assert mem.requests == [0x0, 0xA0000000], f"Expected no additional memory requests, got {mem.requests}"

@cocotb.test()
async def fake_program(dut):
    mem = await setup(dut, first_addr=0x0)

    instr, cycles = await read_instr(dut, 0x0)

    # Initial cache fill
    assert instr == 0x0, f"Expected instruction 0xC, got {instr:#010x}"
    assert cycles >= mem.latency, f"Expected at least {DEFAULT_MEM_DELAY} cycles for miss"
    assert mem.requests == [0x0], f"Expected memory request for 0x0, got {mem.requests}"

    for addr in (0x0, 0x4, 0x8, 0xC, 0x10, 0x14, 0x20):
        instr, cycles = await read_instr(dut, addr)
    assert mem.requests == [0x0, 0x10, 0x20]