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

char global_var1;
short global_var2;
int global_var3;
long long global_var4;
int global_array[32];

static char global_static_var1;
static short global_static_var2;
static int global_static_var3;
static long long global_static_var4;
static int global_static_array[32];

int main(int argc, char const *argv[])
{
    static char local_static_var1;
    static short local_static_var2;
    static int local_static_var3;
    static long long local_static_var4;
    static int local_static_array[32];

    int global_vars_ok = 0;
    int global_static_vars_ok = 0;
    int local_static_vars_ok = 0;
    int arrays_ok = 1;

    if (global_var1 == 0 && global_var2 == 0 && global_var3 == 0 && global_var4 == 0)
    {
        global_vars_ok = 1;
    }

    if (global_static_var1 == 0 && global_static_var2 == 0 && global_static_var3 == 0 && global_static_var4 == 0)
    {
        global_static_vars_ok = 1;
    }

    if (local_static_var1 == 0 && local_static_var2 == 0 && local_static_var3 == 0 && local_static_var4 == 0)
    {
        local_static_vars_ok = 1;
    }

    for (int i = 0; i < 32; i++)
    {
        if (global_array[i] != 0 || global_static_array[i] != 0 || local_static_array[i] != 0)
        {
            arrays_ok = 0;
        }
    }

    if (global_vars_ok == 1 && global_static_vars_ok == 1 && local_static_vars_ok == 1 && arrays_ok == 1)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}
