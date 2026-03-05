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

const int FIXED_ONE = 1000000; // 1.000000
const int FIXED_LN2 =  693147; // 0.693147

const int MAX_TERMS = 160;
const int EQUAL_FACTOR = 10000; // ignore 4 lowest digits

int fixed_equal(int a, int b)
{
    return (a / EQUAL_FACTOR) == (b / EQUAL_FACTOR);
}

int main(int argc, char const *argv[])
{
    int sum = 0;

    // series: 1 - 1/2 + 1/3 - 1/4 + 1/5 - 1/6 + ... = ln(2)
    for (int i = 1; i <= MAX_TERMS; i++)
    {
        int current_term;

        if (i & 1)
        {
            current_term = FIXED_ONE / i;
        }
        else
        {
            current_term = -(FIXED_ONE / i);
        }

        sum += current_term;
    }

    if (fixed_equal(sum, FIXED_LN2))
    {
        return 0;
    }
    else
    {
        return 1;
    }
}
