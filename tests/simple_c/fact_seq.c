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

#define MAX_FACT_INDEX 20 // factorial of 20

const long long FACTS[] =
{
    1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880,
    3628800LL, 39916800LL, 479001600LL, 6227020800LL, 87178291200LL, 1307674368000LL, 20922789888000LL, 355687428096000LL, 6402373705728000LL, 121645100408832000LL,
    2432902008176640000LL
};

long long get_fact(long long num)
{
    if (num <= 1)
        return 1;
    else
        return num * get_fact(num - 1);
}

int main(int argc, char const *argv[])
{
    int fail_indicator = 0;

    for (int i = 0; i <= MAX_FACT_INDEX; i++)
    {
        long long cur_fact = get_fact(i);

        if (cur_fact != FACTS[i])
        {
            fail_indicator = 1;
        }
    }

    return fail_indicator;
}
