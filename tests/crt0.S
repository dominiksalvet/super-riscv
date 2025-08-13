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

# TODO: add support for C++ programs
.section .init
.global _start
_start:
    la sp, __stack_top

    # zero sbss and bss sections
    la t0, __sbss_start # moving pointer
    la t1, __bss_end

_bss_init_loop:
    bge t0, t1, _bss_init_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j _bss_init_loop
_bss_init_done:

    li a0, 0 # argc = 0
    li a1, 0 # argv = 0 (null pointer)
    call main

_finish:
    la t0, __mb_halt
_halt_loop:
    sw a0, 0(t0) # report main return value
    j _halt_loop
