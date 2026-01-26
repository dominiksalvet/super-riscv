#
#   Super RISC-V - superscalar dual-issue RISC-V processor
#   Copyright (C) 2024-2026 Dominik Salvet
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
#   MAX_CYCLES=<value>  max cycles of simulation (0 - no limit)
#   TEST_GROUP=<group>  selected group of tests
#   TEST_NAME=<name>    test to be run on the CPU
#   WAVES_FILE=<path>   path of output signal waves file
#   X_VAL=0|1|2         unknown values in SV are replaced with:
#                       0 - zeros, 1 - ones, 2 - random values
#   SEED=<value>        seed used for any randomized event
#   INPUT_IN_FILE=1     use input file of respective test as stdin
#                       e.g., TEST_NAME=foo -> stdin=foo_input.txt
#                       if not existing, empty file is used instead

RTL_DIR = rtl
TB_DIR = tb
TESTS_DIR = tests
UTILS_DIR = utils

# out directory is used for generated files
OUT_DIR = out
BUILD_DIR = $(OUT_DIR)/build
OUT_TESTS_DIR = $(OUT_DIR)/tests

# TODO: consider support for other simulators (free, student editions, ...)
VERILATOR = verilator
GTKWAVE = gtkwave

# RISC-V GCC tools
RV_AS = riscv64-unknown-elf-as
RV_LD = riscv64-unknown-elf-ld
RV_GCC = riscv64-unknown-elf-gcc
RV_OBJCOPY = riscv64-unknown-elf-objcopy
RV_OBJDUMP = riscv64-unknown-elf-objdump
RV_READELF = riscv64-unknown-elf-readelf
RV_SIZE = riscv64-unknown-elf-size
RV_ISA_FLAGS = -march=rv32i -mabi=ilp32

# RV_OBJDUMP_FLAGS = -M numeric,no-aliases
# RV_OBJDUMP_FLAGS = --source -l

# Newlib standard C library
NEWLIB_INCLUDE ?= /opt/newlib/riscv64-unknown-elf/include
NEWLIB_LIB ?= /opt/newlib/riscv64-unknown-elf/lib/rv32i/ilp32

# TODO: rename package files and their directories (include -> pkg)
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

# TODO: start testing using third-party test suites
# TODO: add support for popular benchmarks
# supported test group names
TEST_GROUPS = simple_asm\
              simple_c\
              simple_libc

# process accepted macros
TEST_GROUP ?= simple_asm
TEST_NAME ?= hello_world
WAVES_FILE ?= $(OUT_DIR)/waves.fst
X_VAL ?= 0

TEST_BUILD_DIR = $(OUT_TESTS_DIR)/$(TEST_GROUP)
TEST_PREFIX = $(TEST_BUILD_DIR)/$(TEST_NAME)
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

# extra arguments for building tests (programs)
TEST_BUILD_ARGS = \
    RV_AS=$(RV_AS) \
    RV_LD=$(RV_LD) \
    RV_GCC=$(RV_GCC) \
    RV_ISA_FLAGS='$(RV_ISA_FLAGS)' \
    NEWLIB_INCLUDE=$(NEWLIB_INCLUDE) \
    NEWLIB_LIB=$(NEWLIB_LIB) \
    TESTS_DIR=$(abspath $(TESTS_DIR)) \
    TEST_BUILD_DIR=$(abspath $(TEST_BUILD_DIR)) \
    TEST_NAME=$(TEST_NAME)

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
          -DEXEC_TRACE_SUPPORT\
          $^ $(CPP_WRAPPER)
	touch $@

$(BUILD_DIR)/$(TOP_CLASS): $(CPP_WRAPPER) $(BUILD_DIR)_verilated
	$(MAKE) -j -C $(BUILD_DIR) -f $(TOP_CLASS).mk

# this target uses a precompiled program and ignores user macros
hello_world: $(BUILD_DIR)/$(TOP_CLASS) $(UTILS_DIR)/hello_world.hex
	./$< +verilator+noassert +verilator+rand+reset+0 +test+path=$(UTILS_DIR)/hello_world.hex

# this rule must be executed even when target exists
FORCE:
$(TEST_PREFIX): FORCE
	$(MAKE) -C $(TESTS_DIR)/$(TEST_GROUP) $(TEST_BUILD_ARGS)

$(TEST_PREFIX).hex: $(TEST_PREFIX)
	$(RV_OBJCOPY) -O verilog $< $@
	chmod -x $@

$(TEST_PREFIX).dis: $(TEST_PREFIX)
	$(RV_OBJDUMP) $(RV_OBJDUMP_FLAGS) -d $< > $@.tmp
	mv $@.tmp $@

$(TEST_PREFIX)_info.txt: $(TEST_PREFIX)
	$(RV_READELF) -a $< > $@.tmp
	mv $@.tmp $@

# compose simulation rules
SIM_PREREQ := $(BUILD_DIR)/$(TOP_CLASS) $(TEST_PREFIX).hex
DEBUG_PREREQ := $(SIM_PREREQ) $(TEST_PREFIX) $(TEST_PREFIX).dis $(TEST_PREFIX)_info.txt
EXEC_RECIPE := ./$(BUILD_DIR)/$(TOP_CLASS) $(EXEC_FLAGS)
ifeq ($(INPUT_IN_FILE), 1)
    SIM_PREREQ += $(OUT_TESTS_DIR)/input_copy.txt
    DEBUG_PREREQ += $(OUT_TESTS_DIR)/input_copy.txt
    EXEC_RECIPE += < $(OUT_TESTS_DIR)/input_copy.txt
endif

$(OUT_TESTS_DIR)/input_copy.txt: FORCE
	cp $(TESTS_DIR)/$(TEST_GROUP)/$(TEST_NAME)_input.txt $@ 2>/dev/null || true > $@

sim: $(SIM_PREREQ)
	$(EXEC_RECIPE)

# when generating debug info, simulation is allowed to fail
debug: $(DEBUG_PREREQ)
	rm -f $(WAVES_FILE)
	$(RV_SIZE) -G $(TEST_PREFIX)
	$(EXEC_RECIPE) +waves +waves+file=$(WAVES_FILE) || true
	test -f $(WAVES_FILE)

waves: debug
	$(GTKWAVE) $(WAVES_FILE) $(UTILS_DIR)/config.gtkw

print_test_groups:
	@echo $(TEST_GROUPS) | tr ' ' '\n'

print_test_names:
	@$(MAKE) -C $(TESTS_DIR)/$(TEST_GROUP) --no-print-directory $@

clean:
	if [ -d $(OUT_DIR) ]; then rm -r $(OUT_DIR); fi

clean_tests:
	if [ -d $(OUT_TESTS_DIR) ]; then rm -r $(OUT_TESTS_DIR); fi
