#
#   Super RISC-V - superscalar dual-issue RISC-V processor
#   Copyright (C) 2025 Dominik Salvet
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

# WARNING: this makefile is not intended to be used by end user

LDFLAGS = --defsym=__stack_size=0 --defsym=__heap_size=0 --no-relax-gp

build: $(TEST_BUILD_DIR)/$(TEST_NAME)

$(TEST_BUILD_DIR):
	mkdir -p $@

$(TEST_BUILD_DIR)/%.o: %.s | $(TEST_BUILD_DIR)
	$(RV_AS) $(RV_ISA_FLAGS) $< -o $@

$(TEST_BUILD_DIR)/%: $(TEST_BUILD_DIR)/%.o $(TESTS_DIR)/link.ld
	$(RV_LD) -m elf32lriscv $(LDFLAGS) -T $(TESTS_DIR)/link.ld $< -nostdlib -o $@

print_test_names:
	@echo *.s | tr ' ' '\n' | sed 's/\.s$$//'
