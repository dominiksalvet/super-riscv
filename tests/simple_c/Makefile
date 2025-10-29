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

# EXTRA_CFLAGS = -g
CFLAGS = $(RV_ISA_FLAGS) $(EXTRA_CFLAGS)

build: $(TEST_BUILD_DIR)/$(TEST_NAME)

$(TEST_BUILD_DIR):
	mkdir -p $@

$(TEST_BUILD_DIR)/crt0.o: $(TESTS_DIR)/crt0.S | $(TEST_BUILD_DIR)
	$(RV_GCC) $(CFLAGS) -c $< -o $@

$(TEST_BUILD_DIR)/%: %.c $(TESTS_DIR)/link.ld $(TEST_BUILD_DIR)/crt0.o | $(TEST_BUILD_DIR)
	$(RV_GCC) $(CFLAGS) -T $(TESTS_DIR)/link.ld $(TEST_BUILD_DIR)/crt0.o $< -nostdlib -lgcc -o $@

print_test_names:
	@echo *.c | tr ' ' '\n' | sed 's/\.c$$//'
