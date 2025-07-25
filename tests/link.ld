/*
    Super RISC-V - superscalar dual-issue RISC-V processor
    Copyright (C) 2024 Dominik Salvet

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

SECTIONS
{
    . = 0x1000;
    .text : { *(.text) }
    . = 0x2000;
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    .bss : { *(.bss) }
    . = 0x3000;
    .mailbox : { *(.mailbox) }
}
