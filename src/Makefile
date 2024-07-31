#
#   Super RISC-V - superscalar dual-issue RISC-V processor
#   Copyright (C) 2024 Dominik Salvet
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# ACCEPTED MACROS:
#   ASSERTS=1           enable SV assertions
#   MAX_CYCLES=<value>  max cycles of simulation
#   TEST_NAME=<name>    test to be run on the CPU
#   WAVES_FILE=<path>   path of output signal waves file
#   X_VAL=0|1|2         unknown values in SV are replaced with:
#                       0 - zeros, 1 - ones, 2 - random values
#   SEED=<value>        seed used for any randomized event

RTL_DIR = rtl
TB_DIR = tb
TESTS_DIR = tests
UTILS_DIR = utils
# out directory is used for generated files
OUT_DIR = out

# TODO: consider support for other simulators (free, student editions, ...)
VERILATOR = verilator
GTKWAVE = gtkwave

# RISC-V tools
RV_AS = riscv32-unknown-elf-as
RV_LD = riscv32-unknown-elf-ld
RV_OBJCOPY = riscv32-unknown-elf-objcopy
RV_OBJDUMP = riscv32-unknown-elf-objdump

SRC_FILES = $(RTL_DIR)/include/srv_defs.sv\
            $(RTL_DIR)/include/riscv_defs.sv\
            $(RTL_DIR)/super_riscv.sv\
            $(RTL_DIR)/ifu/ifu.sv\
            $(RTL_DIR)/ifu/ifb.sv\
            $(RTL_DIR)/dec/dec.sv\
            $(RTL_DIR)/dec/inst_dec.sv\
            $(RTL_DIR)/dec/gpr.sv\
            $(RTL_DIR)/dec/fwd_init.sv\
            $(RTL_DIR)/exu/exu.sv\
            $(RTL_DIR)/exu/alu.sv\
            $(RTL_DIR)/exu/bru.sv\
            $(RTL_DIR)/lsu.sv\
            $(TB_DIR)/tb.sv\
            $(TB_DIR)/ahb_mem.sv

TOP_MODULE = tb
# wrapper is used by verilator-generated makefile (hence absolute path)
CPP_WRAPPER = $(abspath $(TB_DIR)/$(TOP_MODULE)_wrapper.cpp)
TOP_CLASS = V$(TOP_MODULE)

# out directory structure
BUILD_DIR = $(OUT_DIR)/build
OUT_TESTS_DIR = $(OUT_DIR)/tests

# process accepted macros
TEST_NAME ?= hello_world
WAVES_FILE ?= $(OUT_DIR)/waves.fst
X_VAL ?= 0

TEST_PREFIX = $(OUT_TESTS_DIR)/$(TEST_NAME)
EXEC_FLAGS =

# prepare execution flags for CPU simulator
ifneq ($(ASSERTS), 1)
    EXEC_FLAGS += +verilator+noassert
endif
ifdef MAX_CYCLES
    EXEC_FLAGS += +max+cycles=$(MAX_CYCLES)
endif
EXEC_FLAGS += +verilator+rand+reset+$(X_VAL)
ifdef SEED
    EXEC_FLAGS += +verilator+seed+$(SEED)
endif
EXEC_FLAGS += +test+path=$(TEST_PREFIX).hex

# lint and transform RTL to C++ in default (quick check)
verilate: $(BUILD_DIR)_verilated
build: $(BUILD_DIR)/$(TOP_CLASS)

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)_verilated: $(SRC_FILES) | $(BUILD_DIR)
	$(VERILATOR) --cc --exe -Wall --top-module $(TOP_MODULE)\
          --assert\
          --trace-fst --trace-structs\
          --x-assign unique --x-initial unique\
          -Mdir $(BUILD_DIR)\
          $^ $(CPP_WRAPPER)
	touch $@

$(BUILD_DIR)/$(TOP_CLASS): $(CPP_WRAPPER) $(BUILD_DIR)_verilated
	$(MAKE) -j -C $(BUILD_DIR) -f $(TOP_CLASS).mk

# this target uses a precompiled program and ignores user macros
hello_world: $(BUILD_DIR)/$(TOP_CLASS) $(UTILS_DIR)/hello_world.hex
	./$< +verilator+noassert +verilator+rand+reset+0 +test+path=$(UTILS_DIR)/hello_world.hex

# TODO: create more universal test compilation (individual makefiles, C programs, use GCC, ...)
$(OUT_TESTS_DIR):
	mkdir -p $@

$(OUT_TESTS_DIR)/%.o: $(TESTS_DIR)/%.s | $(OUT_TESTS_DIR)
	$(RV_AS) -march=rv32i -mabi=ilp32 $< -o $@

$(OUT_TESTS_DIR)/%: $(OUT_TESTS_DIR)/%.o $(TESTS_DIR)/link.ld
	$(RV_LD) -nostdlib -T $(TESTS_DIR)/link.ld $< -o $@

$(OUT_TESTS_DIR)/%.hex: $(OUT_TESTS_DIR)/%
	$(RV_OBJCOPY) -O verilog $< $@

$(OUT_TESTS_DIR)/%.dis: $(OUT_TESTS_DIR)/%
	$(RV_OBJDUMP) -D -M numeric,no-aliases $< > $@.tmp
	mv $@.tmp $@

sim: $(BUILD_DIR)/$(TOP_CLASS) $(TEST_PREFIX).hex
	./$< $(EXEC_FLAGS)

# TODO: add support for CPU execution tracing
# when generating debug info, simulation is allowed to fail
debug: $(BUILD_DIR)/$(TOP_CLASS) $(TEST_PREFIX).hex $(TEST_PREFIX).dis
	rm -f $(WAVES_FILE)
	./$< $(EXEC_FLAGS) +waves +waves+file=$(WAVES_FILE) || true
	test -f $(WAVES_FILE)

waves: debug
	$(GTKWAVE) $(WAVES_FILE) $(UTILS_DIR)/config.gtkw

clean:
	if [ -d $(OUT_DIR) ]; then rm -r $(OUT_DIR); fi
