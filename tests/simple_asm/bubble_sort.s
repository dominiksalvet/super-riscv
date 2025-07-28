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

# self-check bubble sort test for RISC-V

.section .mailbox, "aw", @nobits
mb_halt: .word 0
mb_putc: .word 0

.section .text
.global _start
_start:
    lw x30, array_size
    la x31, array

    li x11, 0 # number of already sorted items
bubble_sort:
    bge x11, x30, check_sorted

    sub x12, x30, x11 # number of to-be-sorted items
    li x13, 0         # index of current item

bubble_step:
    addi x14, x13, 1 # compared item index
    blt x14, x12, 1f
    addi x11, x11, 1
    j bubble_sort
1:
    slli x15, x13, 2
    add x15, x15, x31
    lw x16, 0(x15) # load two numbers
    lw x17, 4(x15)

    bge x17, x16, 2f # check if swap
    sw x17, 0(x15)
    sw x16, 4(x15)
2:
    addi x13, x13, 1
    j bubble_step

check_sorted:
    li x10, 0 # success in default
    beqz x30, sorted # zero size array is sorted
    
    lw x12, 0(x31) # lower element
    li x11, 1 # higher element index

sorted_loop:
    bge x11, x30, sorted # single item is sorted

    slli x13, x11, 2
    add x13, x13, x31
    lw x13, 0(x13) # higher element

    blt x13, x12, not_sorted

    mv x12, x13 # current higher is new lower
    addi x11, x11, 1
    j sorted_loop

not_sorted:
    li x10, 1
sorted:
    la x11, mb_halt
halt_loop:
    sw x10, 0(x11)
    j halt_loop

.section .data
array_size: .word 30
array: .word 28, 4, 8, -3, 20, 344, 4, -434, 43, 92927
       .word 2, 3, 423424, 545, 3434, -23, 34, 876, 873, 20
       .word 0, -4, 4324, -43434, 4, 1, 2, -2, -2, 9
