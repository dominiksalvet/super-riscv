/*
    Super RISC-V - superscalar dual-issue RISC-V processor
    Copyright (C) 2025 Dominik Salvet

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

void custom_print(char *str)
{
    extern volatile char __mb_putc;

    while (*str != '\0') {
        __mb_putc = *str++;
    }
}

int main(int argc, char const *argv[])
{
    custom_print(
        " ----------------------------------------------- \n"
        "|                                               |\n"
        "|          Hello World, can you C it?           |\n"
        "|                                               |\n"
        " ----------------------------------------------- \n"
    );

    return 0;
}
