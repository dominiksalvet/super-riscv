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

MEMORY
{
    IMEM (rx)    : ORIGIN = 0x20000000, LENGTH = 64K
    DMEM (rw)    : ORIGIN = 0x30000000, LENGTH = 64K
    MAILBOX (rw) : ORIGIN = 0xf0000000, LENGTH = 256
}

SECTIONS
{
    __stack_size = DEFINED(__stack_size) ? __stack_size : 4K;
    __heap_size  = DEFINED(__heap_size)  ? __heap_size  : 4K;

    .init : { *(.init) } > IMEM
    .text : { *(.text) } > IMEM

    .rodata : { *(.rodata) } > DMEM
    .data :
    {
        __data_start = .;
        *(.data)
    } > DMEM

    .srodata : { *(.srodata) } > DMEM
    .sdata :
    {
        __sdata_start = .;
        *(.sdata)
    } > DMEM

    .sbss : ALIGN(4)
    {
        __sbss_start = .; /* bss sections begin */
        *(.sbss)
        . = ALIGN(4);
        __sbss_end = .;
    } > DMEM
    .bss : ALIGN(4)
    {
        *(.bss)
        . = ALIGN(4);
        __bss_end = .;
    } > DMEM

    /* priority: sdata > sbss > srodata > data > bss */
    __global_pointer$ = MIN(__sdata_start + 0x800,
                            MAX(__data_start + 0x800, __sbss_end - 0x800)
                        );

    .heap : ALIGN(8)
    {
        __heap_start = .;
        . = . + __heap_size;
        __heap_end = .;
    } > DMEM

    .stack : ALIGN(16)
    {
        __stack_bottom = .;
        . = . + __stack_size;
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
