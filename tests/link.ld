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

/* TODO: add sbss/sdata support */

SECTIONS
{
    . = 0x1000;
    .text :
    {
        *(.init)
        *(.text)
    }

    . = 0x2000;
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    .bss :
    {
        __bss_start = .;
        *(.bss)
        __bss_end = .;
    }

    . = 0x3000;
    .stack : ALIGN(16)
    {
        . = . + 0x1000;
        __stack_top = .;
    }

    . = 0x4000;
    .mailbox :
    {
        __mb_halt = .;
        . += 4;
        __mb_putc = .;
        . += 4;
    }
}
