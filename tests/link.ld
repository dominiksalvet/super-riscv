/*
    Super RISC-V - superscalar dual-issue RISC-V processor
    Copyright (C) 2024-2025 Dominik Salvet

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

OUTPUT_ARCH(riscv);
ENTRY(_start);

/* TODO: add support for GP pointer, stack/heap/start_address size parameter */

MEMORY
{
    IMEM (rx)    : ORIGIN = 0x10000000, LENGTH = 64K
    DMEM (rw)    : ORIGIN = 0x20000000, LENGTH = 64K
    MAILBOX (rw) : ORIGIN = 0xf0000000, LENGTH = 256
}

SECTIONS
{
    .init : { *(.init) } > IMEM
    .text : { *(.text) } > IMEM

    .rodata : { *(.rodata) } > DMEM
    .data : { *(.data) } > DMEM

    .sdata : { *(.sdata) } > DMEM
    .sbss :
    {
        __bss_start = .;
        *(.sbss)
    } > DMEM

    .bss :
    {
        *(.bss)
        __bss_end = .;
    } > DMEM

    .heap : ALIGN(8)
    {
        __heap_start = .;
        . = . + 0x1000; /* heap size */
        __heap_end = .;
    } > DMEM

    .stack : ALIGN(16)
    {
        __stack_bottom = .;
        . = . + 0x1000; /* stack size */
        __stack_top = .;
    } > DMEM

    .mailbox :
    {
        __mb_halt = .;
        . += 4;
        __mb_putc = .;
        . += 4;
    } > MAILBOX
}
