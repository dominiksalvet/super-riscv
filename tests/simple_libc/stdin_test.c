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

#include <stdio.h>
#include <string.h>

int main(int argc, char const *argv[])
{
    int inum;
    char msg[100];
    float fnum;
    
    if (scanf("%d %s %f", &inum, msg, &fnum) != 3) {
        return 1;
    }

    if (inum == 42 && strcmp(msg, "forty-two") == 0 && fnum == 42.25f) {
        return 0;
    } else {
        return 2;
    }
}
