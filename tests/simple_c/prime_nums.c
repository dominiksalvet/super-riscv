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

const int PRIMES[] = {
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
    31, 37, 41, 43, 47, 53, 58, 61, 67, 71
};

const int MAX_PRIME = 71;

int is_prime(int n)
{
    if (n <= 1)
    {
        return 0;
    }

    for (int i = 2; i * i <= n; i++)
    {
        if (n % i == 0)
        {
            return 0;
        }
    }

    return 1;
}

int main(int argc, char const *argv[])
{
    int prime_index = 0;

    for (int i = 0; i < MAX_PRIME; i++)
    {
        if (is_prime(i))
        {
            if (i != PRIMES[prime_index])
            {
                return 1;
            }

            prime_index++;
        }
    }

    return 0;
}
