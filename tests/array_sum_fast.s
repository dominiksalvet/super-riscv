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

# array sum program optimized for Super RISC-V (also uses loop unrolling)

.section .mailbox, "aw", @nobits
mb_halt: .word 0
mb_putc: .word 0

.section .text
.global _start
_start:
    la x1, num_array # current address
    la x2, num_array_end # stop address

    lw x3, ref_result
    li x4, 0 # current result

.balign 8
loop_head:
    bge x1, x2, finished
    lw x10, 0(x1)
    lw x11, 4(x1)
    lw x12, 8(x1)
    lw x13, 12(x1)
    lw x14, 16(x1)
    lw x15, 20(x1)
    lw x16, 24(x1)
    lw x17, 28(x1)
    addi x1, x1, 64

.balign 8
next_loop:
    add x4, x4, x10
    lw x18, -32(x1)
    add x4, x4, x11
    lw x19, -28(x1)
    add x4, x4, x12
    lw x20, -24(x1)
    add x4, x4, x13
    lw x21, -20(x1)

    add x4, x4, x14
    lw x22, -16(x1)
    add x4, x4, x15
    lw x23, -12(x1)
    add x4, x4, x16
    lw x24, -8(x1)
    add x4, x4, x17
    lw x25, -4(x1)

    bge x1, x2, loop_tail
    addi x1, x1, 64

    add x4, x4, x18
    lw x10, -64(x1)
    add x4, x4, x19
    lw x11, -60(x1)
    add x4, x4, x20
    lw x12, -56(x1)
    add x4, x4, x21
    lw x13, -52(x1)

    add x4, x4, x22
    lw x14, -48(x1)
    add x4, x4, x23
    lw x15, -44(x1)
    add x4, x4, x24
    lw x16, -40(x1)
    add x4, x4, x25
    lw x17, -36(x1)

    j next_loop

.balign 8
    nop
loop_tail:
    # clever sum reduction
    add x4, x4, x18
    add x4, x4, x19
    add x20, x20, x21
    add x4, x4, x20
    add x22, x22, x23
    add x4, x4, x22
    add x24, x24, x25
    add x4, x4, x24

finished:
    la x5, mb_halt
    sub x4, x4, x3 # return value

halt_loop:
    sw x4, 0(x5)
    j halt_loop

.section .rodata
ref_result: .word 496115
# size of the number array must be divisible by 16 (or padded with zeros)
num_array: .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
           .word 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610
           .word 0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384
           .word -2, -3, -5, -7, -11, -13, -17, -19, -23, -29, -31, -37, -41, -43, -47, -53
           .word -1, 2, 3, 4, 4445, 6, 7, 8, 9, 10, 11, 16, 13, 14, 15, 16
           .word 220, 1, -1, 2, 3, 45, 8, 13, 21, 34, -55, 89, 144, 233, 377, 610
           .word 2, 2, 2, 4, 9878, 16, 32, 64, -128, 256, -52, 1024, 2048, -4096, -892, 163
           .word -2, -3, -5, 7, -11, -13, 17, -1900, -23, -29, -31, -37, -41, 43, -47, -53
           .word 1, 2, 3, 4, 5, 90, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
           .word 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 37, 610
           .word 0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 20000, 2048, 4096, 8192, 16384
           .word -2, -6, -5, -7, -11, -16, -17, -19, -23, -29, -31, -37, -41, -43, -47, -53
           .word -1, 2, 3, 4, 4445, 6, 7, 8, 9, 10, 11, 16, 13, 14, 15, 16
           .word 222222, 1, -19877, 2, 3, 45, 8, 13, 21, 34, -55, 89, 144, 233, 377, 610
           .word 2, 2, 2, 4, 9878, 16, 32, 64, -128, 256, -52, 1024, 2048, -4096, -892, 163
           .word -2, -3, -5, -7, -11, -13, 17, -1900, -23, -29, -31, -37, -41, 43, 2233, -53
           .word 1, 2, 3, 4, 5, 6, 7, 783, 9, 10, 11, 12, 13, 14, 15, 16
           .word 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610
           .word 0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, -24, 2048, 4096, 8192, 16384
           .word -2, -3, -5, -7, -11, -13, -17, -19, -23, -29, -31, -37, -41, -43, -47, -53
           .word -1, 2, 3, 333, 4445, 6, 7, 8, 9, 10, 11, 16, 13, 14, 15, 16
           .word 220, 1, -1, 2, 3, 45, 8, 13, 21, 34, -55, 89, 144, 233, 377, 610
           .word 2, 2, 2, 4, 9878, 16, 32, 64, -128, 256, -52, 1024, 2048, -4096, -892, 163
           .word -2, -3, -5, 7, -11, -13, 17, -1900, -23, -29, -31, -37, -41, 43, -47, -53
           .word 1, 2, 3, 4, 5, 90, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
           .word 0, 1, 1, 2, 3, 5, 8, 13, 21, 3334, 55, 89, 144, 233, 37, 610
           .word 0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 20000, 2048, 4096, 8192, -106384
           .word -2, -6, -5, -7, -11, -16, -17, -19, -23, -29, -31, -37, -41, -43, -47, -53
           .word -1, 2, 3, 4, 4445, 26, 7, 8, 9, 10, 11, 16, 13, 14, 15, 16
           .word 222222, 1, -19877, 2, 3, 45, 8, 13, 21, 34, -55, 89, 144, 233, 377, 610
           .word 2, 2, 2, 4, 233, 16, 32, 64, -128, 256, -52, 1024, 2048, -4096, -892, 163
           .word -2, -3, -5, -7, -11, -13, 17, -1900, -23, -29, -31, -37, -41, 43, -22, -5398
num_array_end: .word 0 # end of array pointer
