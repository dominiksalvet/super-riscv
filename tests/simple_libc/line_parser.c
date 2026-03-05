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
#include <stdlib.h>
#include <ctype.h>

#define LINE_MAX_L 64
#define TOTAL_LINES 6

#define S_VAL "HELLORISCV"
#define I_VAL -32
#define C_VAL 'S'
#define F_VAL 25.5f

int main(int argc, char const *argv[])
{
    char line[LINE_MAX_L];
    int lines_read = 0;

    // read next line
    while (fgets(line, sizeof line, stdin)) {
        // remove newline character
        line[strcspn(line, "\n")] = '\0';

        // split on spaces (3 columns)
        char *s_type  = strtok(line, " ");
        char *s_count = strtok(NULL, " ");
        char *s_data  = strtok(NULL, " ");

        // check if splitting was successful
        if (!s_type || !s_count || !s_data) {
            return 2;
        }

        char type = s_type[0];

        if (!isalpha(type)) {
            return 10;
        }
        type = tolower(type);

        int count = atoi(s_count);

        // invalid value and error code of atoi()
        if (count <= 0) {
            return 3;
        }

        if (count != strlen(s_data)) {
            return 4;
        }

        switch (type) {
            case 'c':
                char c_val = s_data[0];
                if (c_val != C_VAL) {
                    return 5;
                }
                break;
            case 'i':
                int i_val = atoi(s_data);
                if (i_val != I_VAL) {
                    return 6;
                }
                break;
            case 's':            
                char *s_val = s_data;
                strupr(s_val); // we manipulate original string
                if (strcmp(s_val, S_VAL) != 0) {
                    return 7;
                }
                break;
            case 'f':
                float f_val = atof(s_data);
                if (f_val != F_VAL) {
                    return 8;
                }
                break;
            default:
                return 9;
                break;
        }

        lines_read++;
    }

    if (lines_read != TOTAL_LINES) {
        return 1;
    }

    return 0;
}
