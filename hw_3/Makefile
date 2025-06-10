# Path to directories
ROOT := /workspace/hw3/
ENV_DIR := /gem5/
RISCV_DIR := /opt/riscv/bin

# Compiler and assembler
CC   := $(RISCV_DIR)/riscv64-unknown-linux-gnu-gcc
AS   := $(RISCV_DIR)/riscv64-unknown-linux-gnu-as
LD   := $(RISCV_DIR)/riscv64-unknown-linux-gnu-ld
DP   := $(RISCV_DIR)/riscv64-unknown-linux-gnu-objdump
HEX  := $(RISCV_DIR)/riscv64-unknown-linux-gnu-objcopy
CPP  := $(RISCV_DIR)/riscv64-unknown-linux-gnu-g++
CMP  := $(RISCV_DIR)/riscv64-unknown-linux-gnu-size
DBG  := $(RISCV_DIR)/riscv64-unknown-linux-gnu-gdb

# Program name
PROG := merge_sort


# Target files
CPP_SRC := $(PROG).cpp
C_SRC   := $(PROG).c
ASM_SRC := $(PROG).s

CPP_OUT := $(PROG)
C_OUT   := $(PROG)
ASM_OUT := $(PROG)
HEX_OUT := $(PROG).hex

DP_ASM  := $(PROG).asm
DP_EXEC := $(PROG)

# Compiler options
# ARCH_FLAGS := -march=rv64gcv -mabi=lp64d
ARCH_FLAGS := -march=rv32gc -mabi=ilp32
STATIC_FLAG := -static

.PHONY: all g++ gcc asm dump_asm dump_hex calc_size gem5 profile save clean

# Compile C++ code
g++: $(CPP_SRC)
	$(CPP) $(ARCH_FLAGS) $(CPP_SRC) -o $(CPP_OUT) $(STATIC_FLAG)
	@echo "C++ code compiled to $(CPP_OUT)"

# Compile C code
gcc: $(C_SRC)
	$(CC) $(ARCH_FLAGS) $(C_SRC) -o $(C_OUT) $(STATIC_FLAG)
	@echo "C code compiled to $(C_OUT)"

# Assemble assembly code
asm: $(ASM_SRC)
	sed -i -e '$$a\\' $(ASM_SRC)
	$(CPP) $(ARCH_FLAGS) $(ASM_SRC) -o $(ASM_OUT) $(STATIC_FLAG)
	@echo "Assembly code assembled to $(ASM_OUT)"

# Disassemble compiled C code
dump_asm:
	$(DP) -d $(C_OUT) > $(DP_ASM)
	@echo "Disassembled $(C_OUT) to $(DP_ASM)"

# Convert compiled C code to machine code
dump_hex:
	$(HEX) -O verilog $(DP_EXEC) $(HEX_OUT)
	@echo "Converted $(DP_EXEC) to machine code (hex) $(HEX_OUT)"

# Calculate the size of the machine code
calc_size: dump_hex
	du -sh ./$(DP_EXEC)
	@echo "Size of $(DP_EXEC) is calculated"

# Emulate the program on gem5 with additional arguments
gem5:
	@echo "e.g. make gem5 GEM5_ARGS=\"--isa_type 32 --l1i_size 1kB --l1i_assoc 2 --l1d_size 1kB --l1d_assoc 2 --l2_size 16kB --l2_assoc 4\""
	cd $(ENV_DIR); \
	rm -rf $(ROOT)m5out; \
	build/RISCV/gem5.opt --outdir="$(ROOT)m5out" $(ROOT)simple-riscv-mod-config.py $(ROOT)$(PROG) $(GEM5_ARGS) 
	@echo "Emulated $(PROG) on gem5 with arguments: $(GEM5_ARGS)"

# Profile the program
profile:
	python3 profiler.py
	python3 profiler_plot.py 
	@echo "Profiled $(PROG) on gem5"

save:
	python3 profiler.py -a
	@echo "Saved $(PROG) profile data"
	
# Clean up generated files
clean:
	rm -f $(PROG) $(HEX_OUT) $(ASM_OUT).o $(DP_ASM)
	@echo "Cleaned up generated files"