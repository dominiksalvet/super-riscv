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

# This is a simple self-check test of all RISC-V basic instructions (RV32I).
# It uses register x1 to accumulate fail codes. If x1 is non-zero at the end
# of the test, it means the test failed.

.option push
.option arch, -c

.section .mailbox, "aw", @nobits
mb_halt: .word 0
mb_putc: .word 0

.section .text
.global _start
_start:
    # LUI
    lui x1, 0xFFFFF # first test case
    lui x1, 0

    lui x2, 0x333 # next test case ...
    li x3, 0x333
    sll x3, x3, 12
    sub x2, x2, x3
    or x1, x1, x2 # accumulate error, if present

    lui x4, 0xF0000
    lui x5, 0xFFFE
    or x4, x4, x5
    sra x4, x4, 13
    addi x4, x4, 1
    or x1, x1, x4

    # AUIPC
    auipc x6, 0
    auipc x7, 0
    sub x6, x6, x7
    addi x6, x6, 4
    or x1, x1, x6

    auipc x8, 0
    auipc x9, 1
    lui x10, 1
    add x8, x8, x10
    sub x8, x9, x8
    addi x8, x8, -4
    or x1, x1, x8

    # JAL
    li x11, 0
    jal x0, 1f
    li x11, 1
1:
    or x1, x1, x11

    li x12, 1
    jal x0, 3f
2:
    li x12, 0
    jal x0, 4f
    li x12, 1
3:
    jal x0, 2b
    li x12, 1
4:
    or x1, x1, x12

    li x13, 1
    jal x14, 5f
    jal x0, 6f
5:
    auipc x13, 0
    addi x13, x13, -4
    sub x13, x13, x14
6:
    or x1, x1, x13

    # JALR
    li x14, 0
    la x15, 1f
    jalr x0, 0(x15)
    li x14, 1
1:
    or x1, x1, x14

    li x16, 1
    li x17, 26
    li x18, -18
    li x19, -9
    la x20, add_x16_x19
    jalr x21, -8(x20)
    jal x0, 2f
add_x16_x17:
    add x16, x16, x17
add_x16_x18:
    add x16, x16, x18
add_x16_x19:
    add x16, x16, x19
    jalr x0, 0(x21)
2:
    or x1, x1, x16

    li x22, 1
    jal x23, 3f
    jal x0, 4f
3:
    li x22, 0
    jr x23
4:
    or x1, x1, x22

    # conditional branches
    li x24, 0
    li x25, 57
    mv x26, x25
    bne x25, x26, 1f
    blt x25, x26, 1f
    blt x26, x25, 1f
    bltu x25, x26, 1f
    bltu x26, x25, 1f
    beq x25, x26, 2f
1:
    li x24, 1
2:
    or x1, x1, x24

    li x27, 0
    li x28, 19
    li x29, 97
    beq x28, x29, 3f
    blt x29, x28, 3f
    bge x28, x29, 3f
    bltu x29, x28, 3f
    bgeu x28, x29, 3f
    blt x28, x29, 4f
3:
    li x27, 1
4:
    or x1, x1, x27

    li x30, 0
    li x31, 5
    li x2, 0
5:
    bge x30, x31, 6f
    addi x30, x30, 3
    addi x2, x2, 1
    j 5b
6:
    addi x2, x2, -2
    or x1, x1, x2

    li x3, 0
    li x4, 10
    li x5, -15
    li x6, -10
    blt x6, x5, 7f
    blt x4, x5, 7f
    bgt x5, x4, 7f
    bgtu x3, x4, 7f
    bge x5, x6, 7f
    bge x6, x4, 7f
    ble x4, x6, 7f
    bleu x4, x3, 7f
    beqz x4, 7f
    bnez x3, 7f
    blez x4, 7f
    bgez x6, 7f
    bltz x3, 7f
    bgtz x3, 7f
    blt x5, x6, 8f
7:
    li x3, 1
8:
    or x1, x1, x3

    # load instructions
    li x7, 1
    la x8, zero_word
    lw x7, 0(x8)
    or x1, x1, x7

    li x9, 0x98
    la x10, var_word
    lbu x11, 0(x10)
    sub x11, x11, x9
    or x1, x1, x11

    li x12, 0xFEDC
    li x13, 0xFFFFFEDC
    lhu x14, 2(x10)
    lh x15, 2(x10)
    sub x12, x12, x14
    sub x13, x13, x15
    or x1, x1, x12
    or x1, x1, x13

    li x14, 0xFFFFFFDC
    lb x15, 2(x10)
    sub x15, x15, x14
    or x1, x1, x15

    # store instructions
    li x16, 20
    li x17, 0
    sw x16, uninit_word, x18
    lw x17, uninit_word
    sub x16, x16, x17
    or x1, x1, x16

    li x19, 15
    li x20, 0
    sb x19, 1(x18)
    lbu x20, 1(x18)
    sub x19, x19, x20
    or x1, x1, x19

    li x21, -42
    li x22, 0
    sh x21, 2(x18)
    lh x22, 2(x18)
    sub x21, x21, x22
    or x1, x1, x21

    # arithmetic immediate instructions
    li x23, 38
    li x24, 49
    li x25, 0xFF
    neg x26, x23 # -38
    neg x27, x24 # -49
    not x28, x25 # 0xFFFFFF00

    addi x29, x23, 11
    sub x29, x29, x24 # 0
    slti x30, x26, -37 # 1
    slti x31, x26, 37 # 1
    sltiu x2, x23, 39 # 1
    xori x3, x28, 0xFE
    not x3, x3 # 1
    ori x4, x28, 0xF
    ori x4, x4, 0xF0
    not x4, x4 # 0
    andi x5, x25, 0x07
    addi x5, x5, -6 # 1
    slli x6, x25, 24
    srli x6, x6, 30
    addi x6, x6, -2 # 1
    add x7, x26, x26 # -76
    srai x7, x7, 2 # -19
    addi x7, x7, 20 # 1

    add x30, x30, x31 # 2
    add x2, x2, x3 # 2
    add x5, x5, x6 # 2
    add x30, x30, x7 # 3
    add x2, x2, x5 # 4
    add x30, x30, x2 # 7
    addi x30, x30, -7 # 0

    or x1, x1, x29
    or x1, x1, x4
    or x1, x1, x30

    # arithmetic register instructions
    add x31, x23, x26 # 0
    sub x2, x24, x23
    addi x2, x2, -11 # 0
    li x3, 0xF2
    sll x4, x25, x3
    addi x3, x3, 7
    srl x4, x4, x3 # 0x1
    addi x4, x4, -1 # 0
    li x5, -32
    li x6, 3
    sra x7, x5, x6 # -4
    addi x7, x7, 4 # 0
    slt x8, x26, x27 # 0
    sltu x9, x24, x23 # 0
    xor x10, x25, x28
    addi x10, x10, 1 # 0
    li x11, 0x1F
    li x12, 0xF8
    or x13, x11, x12 # 0xFF
    sub x13, x13, x25 # 0
    and x14, x11, x12 # 0x18
    addi x14, x14, -0x18 # 0
    li x15, 0
    li x16, 1
    seqz x17, x16 # 0
    snez x18, x15 # 0
    sltz x19, x15 # 0
    sgtz x20, x15 # 0

    or x31, x31, x2
    or x4, x4, x7
    or x8, x8, x9
    or x10, x10, x13
    or x14, x14, x17
    or x18, x18, x19
    or x31, x31, x4
    or x8, x8, x10
    or x14, x14, x18
    or x31, x31, x8
    or x14, x14, x20
    or x1, x1, x31
    or x1, x1, x14

    # FENCE
    fence

    # clean pipeline before halting
.rep 16
    nop
.endr

    # end of test (x1 collects fail flags)
    la x2, mb_halt
halt_loop:
    sw x1, 0(x2)
    j halt_loop

.section .data
zero_word: .word 0
var_word: .word 0xFEDCBA98

.section .bss
uninit_word: .word 0

.option pop
