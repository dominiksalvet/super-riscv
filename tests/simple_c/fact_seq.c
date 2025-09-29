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

#define MAX_FACT_INDEX 12 // factorial of 12

const unsigned int FACTS[] =
{
    1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880,
    3628800, 39916800, 479001600,
};

// TODO: add support for multiplication operator even with RV32I
int my_mul(int a, int b)
{
    int acc = 0;

    for (int i = 0; i < a; i++)
    {
        acc += b;
    }

    return acc;
}

int get_fact(int num)
{
    if (num <= 1)
        return 1;
    else
        // return num * get_fact(num - 1);
        return my_mul(num, get_fact(num - 1));
}

int main(int argc, char const *argv[])
{
    int fail_indicator = 0;

    for (int i = 0; i <= MAX_FACT_INDEX; i++)
    {
        int cur_fact = get_fact(i);

        if (cur_fact != FACTS[i])
        {
            fail_indicator = 1;
        }
    }

    return fail_indicator;
}
