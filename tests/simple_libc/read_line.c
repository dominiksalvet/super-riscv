/*
    Super RISC-V - superscalar dual-issue RISC-V processor
    Copyright (C) 2026 Dominik Salvet

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

#include <stdio.h>
#include <string.h>

#define LINE_MAX_L 128
#define LINE_MSG "Can you read() 'this' L1N3?"

int main(int argc, char const *argv[])
{
    char read_line[LINE_MAX_L];

    if (!fgets(read_line, sizeof read_line, stdin)) {
        return 1;
    }
    read_line[strcspn(read_line, "\n")] = '\0';

    if (strcmp(read_line, LINE_MSG) != 0) {
        return 2;
    }

    return 0;
}
