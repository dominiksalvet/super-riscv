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

# this is a Hello World program for Super RISC-V processor

.section .mailbox, "aw", @nobits
mb_halt: .word 0
mb_putc: .word 0

.section .text
.global _start
_start:
    la x1, mb_putc
    la x2, msg

.balign 8
    lb x3, 0(x2)
print_loop:
    beqz x3, print_finished
    sb x3, 0(x1)
    addi x2, x2, 1
    lb x3, 0(x2)
    j print_loop

print_finished:
    la x1, mb_halt
    li x2, 0
halt_loop:
    sw x2, 0(x1)
    j halt_loop

.section .rodata
msg: .ascii " ----------------------------------------------- \n"
     .ascii "|                                               |\n"
     .ascii "|   Hello World, I am Super RISC-V processor!   |\n"
     .ascii "|                                               |\n"
     .ascii " ----------------------------------------------- \n"
     .byte 0
