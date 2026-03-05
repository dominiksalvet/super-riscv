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

#define MAX_FIB_INDEX 47 // 48-th fibonacci number

const unsigned int FIBS[] =
{
    0, 1, 1, 2, 3, 5, 8, 13, 21, 34,
    55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181,
    6765, 10946, 17711, 28657, 46368, 75025, 121393, 196418, 317811, 514229,
    832040, 1346269, 2178309, 3524578, 5702887, 9227465, 14930352, 24157817, 39088169, 63245986,
    102334155, 165580141, 267914296, 433494437, 701408733, 1134903170, 1836311903, 2971215073
};

int get_fib(int index)
{
    int n_1 = 0;
    int n = 1;

    for (int i = 0; i < index; i++)
    {
        int next_n = n + n_1;
        n_1 = n;
        n = next_n;
    }

    return n_1;
}

int main(int argc, char const *argv[])
{
    int fail_indicator = 0;

    for (int i = 0; i <= MAX_FIB_INDEX; i++)
    {
        int cur_fib = get_fib(i);

        if (cur_fib != FIBS[i])
        {
            fail_indicator = 1;
        }
    }

    return fail_indicator;
}
