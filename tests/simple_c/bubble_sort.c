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

const int ARRAY_SIZE = 30;

int array[] =
{
    28, 4, 8, -3, 20, 344, 4, -434, 43, 92927,
    2, 3, 423424, 545, 3434, -23, 34, 876, 873, 20,
    0, -4, 4324, -43434, 4, 1, 2, -2, -2, 9
};

void bubble_sort()
{
    for (int i = 0; i < ARRAY_SIZE - 1; i++) // sorted count
    {
        for (int j = 0; j < ARRAY_SIZE - 1 - i; j++)
        {
            if (array[j + 1] < array[j])
            {
                // swap
                int tmp = array[j];
                array[j] = array[j + 1];
                array[j + 1] = tmp;
            }
        }
    }
}

int check_sorted()
{
    for (int i = 0; i < ARRAY_SIZE - 1; i++)
    {
        if (array[i + 1] < array[i])
        {
            return 0; // not sorted
        }
    }

    return 1; // sorted
}

int main(int argc, char const *argv[])
{
    bubble_sort();

    int is_sorted;
    is_sorted = check_sorted();

    if (is_sorted)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}
