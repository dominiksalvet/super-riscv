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

# TODO: define TODO_* labels

.section .init
.global _start
_start:
    la sp, TODO_STACK

    // zero bss section
    la t0, __bss_start // moving pointer
    la t1, __bss_end

_bss_init_loop:
    bge t0, t1, _bss_init_done
    sb zero, 0(t0)
    addi t0, t0, 1
    j _bss_init_loop
_bss_init_done:

    call main

_finish:
    la t0, __mb_halt
_halt_loop:
    sw a0, 0(t0) // report main return value
    j _halt_loop
