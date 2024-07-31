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

# This is a self-check test for various possible hazards in Super RISC-V
# processor. It uses x31 to collect any fail codes. If x31 is non-zero at the
# end of the test, it means the test failed.

.section .mailbox, "aw", @nobits
mb_halt: .word 0
mb_putc: .word 0

.section .text
.global _start
_start:
    # set default value for used registers
    li x1, 1
    li x2, 1
    li x3, 1
    li x4, 1
    li x5, 1
    li x6, 1
    li x7, 1
    li x8, 1
    li x9, 1
    li x10, 1
    li x11, 1
    li x12, 1
    li x13, 1
    li x14, 1
    li x15, 1
    li x16, 1
    li x17, 1
    li x18, 1
    li x19, 1
    li x20, 1
    li x21, 1
    li x22, 1
    li x23, 1
    li x24, 1
    li x25, 1
    li x26, 1
    li x27, 1
    li x28, 1
    li x29, 1

.balign 8
    li x1, 2 # packet with i0 forwarded value (li will become addi)
    nop
    mv x10, x1 # fwd from EX2 i0 to EX1 i0
    mv x11, x1 # fwd from EX2 i0 to EX1 i1
    mv x12, x1 # fwd from EX3 i0 to EX1 i0
    mv x13, x1 # fwd from EX3 i0 to EX1 i1
    mv x14, x1 # fwd from WB i0 to EX1 i0
    mv x15, x1 # fwd from WB i0 to EX1 i1
    mv x16, x1 # fwd new GPR value in ID
    mv x17, x1 # fwd new GPR value in ID
    mv x18, x1 # read GPR value in ID
    mv x19, x1 # read GPR value in ID

.balign 8
    nop # packet with i1 forwarded value
    li x2, 4
    mv x20, x2 # fwd from EX2 i1 to EX1 i0
    mv x21, x2 # fwd from EX2 i1 to EX1 i1
    mv x22, x2 # fwd from EX3 i1 to EX1 i0
    mv x23, x2 # fwd from EX3 i1 to EX1 i1
    mv x24, x2 # fwd from WB i1 to EX1 i0
    mv x25, x2 # fwd from WB i1 to EX1 i1
    mv x26, x2 # fwd new GPR value in ID
    mv x27, x2 # fwd new GPR value in ID
    mv x28, x2 # read GPR value in ID
    mv x29, x2 # read GPR value in ID

    # adding 10 * 2 + 10 * 4 = 60
    add x10, x10, x11
    add x12, x12, x13
    add x14, x14, x15
    add x16, x16, x17
    add x18, x18, x19
    add x20, x20, x21
    add x22, x22, x23
    add x24, x24, x25
    add x26, x26, x27
    add x28, x28, x29
    add x10, x10, x12
    add x14, x14, x16
    add x18, x18, x20
    add x22, x22, x24
    add x26, x26, x28
    add x10, x10, x14
    add x18, x18, x22
    add x10, x10, x18
    add x10, x10, x26
    addi x31, x10, -60 # should be 0

.balign 8
    li x3, 6
    li x4, 8
    mv x10, x3 # fwd from EX2 i0 to EX1 i0
    mv x11, x4 # fwd from EX2 i1 to EX1 i1
    mv x12, x3 # fwd from EX3 i0 to EX1 i0
    mv x13, x4 # fwd from EX3 i1 to EX1 i1
    mv x14, x3 # fwd from WB i0 to EX1 i0
    mv x15, x4 # fwd from WB i1 to EX1 i1
    mv x16, x3 # fwd new GPR value in ID
    mv x17, x4 # fwd new GPR value in ID
    mv x18, x3 # read GPR value in ID
    mv x19, x4 # read GPR value in ID

.balign 8
    li x5, 10
    li x6, 12
    mv x20, x6 # fwd from EX2 i1 to EX1 i0
    mv x21, x5 # fwd from EX2 i0 to EX1 i1
    mv x22, x6 # fwd from EX3 i1 to EX1 i0
    mv x23, x5 # fwd from EX3 i0 to EX1 i1
    mv x24, x6 # fwd from WB i1 to EX1 i0
    mv x25, x5 # fwd from WB i0 to EX1 i1
    mv x26, x6 # fwd new GPR value in ID
    mv x27, x5 # fwd new GPR value in ID
    mv x28, x6 # read GPR value in ID
    mv x29, x5 # read GPR value in ID

    # adding 5 * (6 + 8) + 5 * (10 + 12 ) = 180
    add x10, x10, x11
    add x12, x12, x13
    add x14, x14, x15
    add x16, x16, x17
    add x18, x18, x19
    add x20, x20, x21
    add x22, x22, x23
    add x24, x24, x25
    add x26, x26, x27
    add x28, x28, x29
    add x10, x10, x12
    add x14, x14, x16
    add x18, x18, x20
    add x22, x22, x24
    add x26, x26, x28
    add x10, x10, x14
    add x18, x18, x22
    add x10, x10, x18
    add x10, x10, x26
    addi x10, x10, -180 # should be 0
    or x31, x31, x10 # accumulate error, if present

.balign 8
    li x7, 14 # inter-packet hazard (must stall)
    mv x10, x7
    mv x11, x7
    li x8, 16
    mv x12, x8
    mv x13, x8

.balign 8
    li x9, 18 # chained hazards (will be serialized)
    mv x20, x9
    mv x21, x20
    mv x22, x21
    mv x23, x22
    mv x24, x23
    mv x25, x24
    mv x26, x25
    mv x27, x26
    mv x28, x27
    mv x29, x28

    # adding 2 * (14 + 16) + 10 * 18 = 240
    add x10, x10, x11
    add x12, x12, x13
    add x20, x20, x21
    add x22, x22, x23
    add x24, x24, x25
    add x26, x26, x27
    add x28, x28, x29
    add x10, x10, x12
    add x20, x20, x22
    add x24, x24, x26
    add x10, x10, x20
    add x24, x24, x28
    add x10, x10, x24
    addi x10, x10, -240 # 0
    or x31, x31, x10

    li x1, 0x5
    li x2, 0xB
.balign 8
    mv x10, x1
    mv x10, x2 # write after write (same inst packet)
    or x11, x1, x2
    and x11, x1, x2 # another
    addi x10, x10, -0xB
    addi x11, x11, -0x1
    or x31, x31, x10
    or x31, x31, x11

    la x1, mem_word
    li x2, 20
    li x3, 22

.balign 8
    sw x2, 0(x1)
    lw x20, 0(x1) # load after store (same inst packet)
    nop
    sw x3, 0(x1)
    lw x21, 0(x1) # load after store (different packet)
    add x20, x20, x21
    addi x20, x20, -42
    or x31, x31, x20

    li x4, 24
    sw x4, 0(x1) # prepare new memory value

.balign 8
    lw x10, 0(x1) # load instruction in i0
    mv x20, x10 # load-use in n+1
.balign 8
    lw x11, 0(x1) # load in i0
    nop
    mv x21, x11 # load-use in n+2
.balign 8
    lw x12, 0(x1)
    nop
    nop
    mv x22, x12 # load-use in n+3
.balign 8
    lw x13, 0(x1)
    nop
    nop
    nop
    mv x23, x13 # n+4 ...
.balign 8
    lw x14, 0(x1)
    nop
    nop
    nop
    nop
    mv x24, x14
.balign 8
    lw x15, 0(x1)
    nop
    nop
    nop
    nop
    nop
    mv x25, x15 # first fwd from WB to EX1 (no stalling)
.balign 8
    lw x16, 0(x1)
    nop
    nop
    nop
    nop
    nop
    nop
    mv x26, x16
.balign 8
    lw x17, 0(x1)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    mv x27, x17 # first fwd new GPR value in ID
.balign 8
    lw x18, 0(x1)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    mv x28, x18
.balign 8
    lw x19, 0(x1)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    mv x29, x19 # first read GPR value in ID

    # adding 10 * 24 = 240
    add x20, x20, x21
    add x22, x22, x23
    add x24, x24, x25
    add x26, x26, x27
    add x28, x28, x29
    add x20, x20, x22
    add x24, x24, x26
    add x20, x20, x24
    add x20, x20, x28
    addi x20, x20, -240
    or x31, x31, x20

    li x5, 26
    sw x5, 0(x1) # prepare new memory value

.balign 8
    nop
    lw x10, 0(x1) # load instruction in i1
    mv x20, x10 # load-use in n+1
.balign 8
    nop
    lw x11, 0(x1) # load in i1
    nop
    mv x21, x11 # load-use in n+2
.balign 8
    nop
    lw x12, 0(x1)
    nop
    nop
    mv x22, x12 # load-use in n+3
.balign 8
    nop
    lw x13, 0(x1)
    nop
    nop
    nop
    mv x23, x13 # n+4 ...
.balign 8
    nop
    lw x14, 0(x1)
    nop
    nop
    nop
    nop
    mv x24, x14 # first fwd from WB to EX1 (no stalling)
.balign 8
    nop
    lw x15, 0(x1)
    nop
    nop
    nop
    nop
    nop
    mv x25, x15
.balign 8
    nop
    lw x16, 0(x1)
    nop
    nop
    nop
    nop
    nop
    nop
    mv x26, x16 # first fwd new GPR value in ID
.balign 8
    nop
    lw x17, 0(x1)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    mv x27, x17
.balign 8
    nop
    lw x18, 0(x1)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    mv x28, x18 # first read GPR value in ID
.balign 8
    nop
    lw x19, 0(x1)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    mv x29, x19

    # adding 10 * 26 = 260
    add x20, x20, x21
    add x22, x22, x23
    add x24, x24, x25
    add x26, x26, x27
    add x28, x28, x29
    add x20, x20, x22
    add x24, x24, x26
    add x20, x20, x24
    add x20, x20, x28
    addi x20, x20, -260
    or x31, x31, x20

    la x2, next_mem_word
    li x6, 28
    li x7, 30

.balign 8
    sw x6, 0(x1)
    sw x7, 0(x2) # structural hazard LSU on store
    lw x10, 0(x1)
    lw x11, 0(x2) # on load
    slli x10, x10, 1
    slli x11, x11, 1
    sw x10, 0(x1)
    sw x11, 0(x2)
    li x10, 1
    li x11, 1
    lw x10, 0(x1)
    lw x11, 0(x2)
    addi x10, x10, -56
    addi x11, x11, -60
    or x31, x31, x10
    or x31, x31, x11

    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 1
    li x21, 1
    li x22, 1
    li x23, 1
    li x24, 1
    li x25, 1
    li x26, 1
    li x27, 1
    li x28, 1
    li x29, 1

.balign 8
    jal x0, 1f # skip 0 instructions from i0
1:
    li x20, 0
.balign 8
    jal x0, 1f # skip 1 instruction (control hazard)
    li x11, 1
1:
    li x21, 0
.balign 8
    jal x0, 1f # skip 2 ...
    li x12, 1
    li x12, 1
1:
    li x22, 0
.balign 8
    jal x0, 1f
    li x13, 1
    li x13, 1
    li x13, 1
1:
    li x23, 0
.balign 8
    jal x0, 1f
    li x14, 1
    li x14, 1
    li x14, 1
    li x14, 1
1:
    li x24, 0
.balign 8
    jal x0, 1f
    li x15, 1
    li x15, 1
    li x15, 1
    li x15, 1
    li x15, 1
1:
    li x25, 0
.balign 8
    jal x0, 1f
    li x16, 1
    li x16, 1
    li x16, 1
    li x16, 1
    li x16, 1
    li x16, 1
1:
    li x26, 0
.balign 8
    jal x0, 1f
    li x17, 1
    li x17, 1
    li x17, 1
    li x17, 1
    li x17, 1
    li x17, 1
    li x17, 1
1:
    li x27, 0 # first instruction not in pipeline yet
.balign 8
    jal x0, 1f
    li x18, 1
    li x18, 1
    li x18, 1
    li x18, 1
    li x18, 1
    li x18, 1
    li x18, 1
    li x18, 1
1:
    li x28, 0
.balign 8
    jal x0, 1f
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
1:
    li x29, 0

    or x10, x10, x11
    or x12, x12, x13
    or x14, x14, x15
    or x16, x16, x17
    or x18, x18, x19
    or x20, x20, x21
    or x22, x22, x23
    or x24, x24, x25
    or x26, x26, x27
    or x28, x28, x29
    or x10, x10, x12
    or x14, x14, x16
    or x18, x18, x20
    or x22, x22, x24
    or x26, x26, x28
    or x10, x10, x14
    or x18, x18, x22
    or x31, x31, x26
    or x31, x31, x10
    or x31, x31, x18

    # initialize to ones again
    li x20, 1
    li x21, 1
    li x22, 1
    li x23, 1
    li x24, 1
    li x25, 1
    li x26, 1
    li x27, 1
    li x28, 1
    li x29, 1

.balign 8
    nop
    jal x0, 1f # skip 0 instructions from i1
1:
    li x20, 0
.balign 8
    nop
    jal x0, 1f # skip 1 instruction (control hazard)
    li x11, 1
1:
    li x21, 0
.balign 8
    nop
    jal x0, 1f # skip 2 ...
    li x12, 1
    li x12, 1
1:
    li x22, 0
.balign 8
    nop
    jal x0, 1f
    li x13, 1
    li x13, 1
    li x13, 1
1:
    li x23, 0
.balign 8
    nop
    jal x0, 1f
    li x14, 1
    li x14, 1
    li x14, 1
    li x14, 1
1:
    li x24, 0
.balign 8
    nop
    jal x0, 1f
    li x15, 1
    li x15, 1
    li x15, 1
    li x15, 1
    li x15, 1
1:
    li x25, 0
.balign 8
    nop
    jal x0, 1f
    li x16, 1
    li x16, 1
    li x16, 1
    li x16, 1
    li x16, 1
    li x16, 1
1:
    li x26, 0 # first instruction not in pipeline yet
.balign 8
    nop
    jal x0, 1f
    li x17, 1
    li x17, 1
    li x17, 1
    li x17, 1
    li x17, 1
    li x17, 1
    li x17, 1
1:
    li x27, 0
.balign 8
    nop
    jal x0, 1f
    li x18, 1
    li x18, 1
    li x18, 1
    li x18, 1
    li x18, 1
    li x18, 1
    li x18, 1
    li x18, 1
1:
    li x28, 0
.balign 8
    nop
    jal x0, 1f
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
    li x19, 1
1:
    li x29, 0

    or x10, x10, x11
    or x12, x12, x13
    or x14, x14, x15
    or x16, x16, x17
    or x18, x18, x19
    or x20, x20, x21
    or x22, x22, x23
    or x24, x24, x25
    or x26, x26, x27
    or x28, x28, x29
    or x10, x10, x12
    or x14, x14, x16
    or x18, x18, x20
    or x22, x22, x24
    or x26, x26, x28
    or x10, x10, x14
    or x18, x18, x22
    or x31, x31, x26
    or x31, x31, x10
    or x31, x31, x18

    la x1, mb_halt
halt_loop:
    sw x31, 0(x1)
    j halt_loop

.section .bss
mem_word: .word 0
next_mem_word: .word 0
