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

int main(int argc, char const *argv[])
{
    int fail_indicator = 0;

    int num = 42;
    int *ptr = &num;

    if (num != *ptr)
    {
        fail_indicator = 1;
    }

    if (&num != ptr)
    {
        fail_indicator = 1;
    }

    *ptr = 2025;

    if (num != *ptr)
    {
        fail_indicator = 1;
    }

    num = 19;

    if (num != *ptr)
    {
        fail_indicator = 1;
    }

    int *array_ptr[3];

    array_ptr[0] = &num;
    array_ptr[1] = ptr;

    if (*array_ptr[0] != num)
    {
        fail_indicator = 1;
    }

    if (*array_ptr[1] != num)
    {
        fail_indicator = 1;
    }

    int num2 = 100;

    *(array_ptr + 2) = &num2;

    if (*array_ptr[2] != num2)
    {
        fail_indicator = 1;
    }

    if (array_ptr[2] != &num2)
    {
        fail_indicator = 1;
    }

    num2 = num;

    if (num != num)
    {
        fail_indicator = 1;
    }

    if (&num == &num2)
    {
        fail_indicator = 1;
    }

    if (ptr != &num)
    {
        fail_indicator = 1;
    }

    ptr = &num2;

    if (ptr == &num)
    {
        fail_indicator = 1;
    }

    return fail_indicator;
}
