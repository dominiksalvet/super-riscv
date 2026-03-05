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

#define LINE_MAX_L 128
#define LINE_MSG "Can you read() 'this' L1N3?"

void custom_readline(char *line)
{
    extern volatile char __mb_getc;

    char cur_c;
    while ((cur_c = __mb_getc) != '\n') {
        *line++ = cur_c;
    }

    *line = '\0';
}

int main(int argc, char const *argv[])
{
    char read_line[LINE_MAX_L];
    custom_readline(read_line);

    for (int i = 0; i < sizeof(LINE_MSG); i++) {
        if (read_line[i] != LINE_MSG[i]) {
            return 1;
        }
    }

    return 0;
}
