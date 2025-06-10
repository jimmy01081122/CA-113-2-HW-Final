# Path to directories
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
PROG := hw2_assembly

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
ARCH_FLAGS := -march=rv32gc -mabi=ilp32
STATIC_FLAG := -static

.PHONY: all g++ gcc asm dump_asm dump_hex gem5 clean hw2_compile_ccode hw2_compile_assembly

# Compile C++ code
g++: $(CPP_SRC)
	$(CPP) $(ARCH_FLAGS) $(CPP_SRC) -o $(CPP_OUT) $(STATIC_FLAG)
	@echo "C++ code compiled to $(CPP_OUT)"

# Compile C code
gcc: $(C_SRC)
	$(CC) $(ARCH_FLAGS) $(C_SRC) -o $(C_OUT) $(STATIC_FLAG)
	@echo "C code compiled to $(C_OUT)"

# Assemble assembly code
asm:
	sed -i -e '$$a\\' $(ASM_SRC)
	$(CPP) $(ARCH_FLAGS) $(ASM_SRC) -o $(ASM_OUT) $(STATIC_FLAG)
	@echo "Assembly code assembled to $(ASM_OUT)"


#================ HW2 compile ====================
# Compile hw2_ccode.cpp 
hw2_compile_ccode: 
	$(CPP) $(ARCH_FLAGS) hw2_ccode.cpp -o hw2_ccode $(STATIC_FLAG)
	@echo "\n hw2_ccode.cpp has been compiled to hw2_ccode \n"
	$(DP) -d hw2_ccode > hw2_ccode.asm
	@echo "\n Disassembled hw2_ccode to hw2_ccode.asm \n"

# Compile hw2 assembly.cpp and LIS.s 
hw2_compile_assembly:	
	$(CPP) $(ARCH_FLAGS) hw2_assembly.cpp LIS.s -o hw2_assembly $(STATIC_FLAG)
	@echo "\n hw2 assembly.cpp and LIS.s  have been compiled to hw2_assembly \n"
	$(DP) -d hw2_assembly > hw2_assembly.asm
	@echo "\n Disassembled hw2_assembly to hw2_assembly.asm \n"
#================ HW2 compile ====================

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
	../gem5/build/RISCV/gem5.opt --debug-flags=Exec --debug-file=out_exec.txt simple-riscv-mod.py $(PROG) $(GEM5_ARGS)
	@echo "Emulated $(PROG) on gem5 with arguments: $(GEM5_ARGS)"


# Clean up generated files
clean:
	rm -f $(PROG) $(HEX_OUT) $(ASM_OUT).o $(DP_ASM)
	@echo "Cleaned up generated files"

