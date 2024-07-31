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

# compute Fibonacci sequence and compare with prepared results on RISC-V

.section .mailbox, "aw", @nobits
mb_halt: .word 0
mb_putc: .word 0

.section .text
.global _start
_start:
    li x10, 0 # get_fib n-th counter
    li x11, 47 # max n-th (max 47 for 32-bit numbers)
    li x12, 0 # fail indicator, must stay zero
    la x13, fibs # address of prepared fib numbers

fib_seq:
    bgt x10, x11, finish_test
    mv x20, x10
    call get_fib # input x20, output x21
    sll x14, x10, 2
    add x14, x13, x14
    lw x15, 0(x14) # reference value from memory
    sub x16, x15, x21
    or x12, x12, x16 # record error, if present
    addi x10, x10, 1
    j fib_seq

finish_test:
    la x10, mb_halt
halt_loop:
    sw x12, 0(x10)
    j halt_loop

# x20 - get n-th
# x21 - returned value
get_fib:
    bnez x20, 1f
    li x21, 0
    ret
1:
    li x22, 1 # counter
    li x23, 0 # n-1
    li x24, 1 # n
fib_step:
    beq x22, x20, fib_done
    add x25, x23, x24
    mv x23, x24
    mv x24, x25
    addi x22, x22, 1
    j fib_step
fib_done:
    mv x21, x24
    ret

.section .rodata
# first 48 Fibonacci numbers
fibs: .word 0, 1, 1, 2, 3, 5, 8, 13, 21, 34
      .word 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181
      .word 6765, 10946, 17711, 28657, 46368, 75025, 121393, 196418, 317811, 514229
      .word 832040, 1346269, 2178309, 3524578, 5702887, 9227465, 14930352, 24157817, 39088169, 63245986
      .word 102334155, 165580141, 267914296, 433494437, 701408733, 1134903170, 1836311903, 2971215073
