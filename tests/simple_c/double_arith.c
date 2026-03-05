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

#define EPSILON 1e-9

double double_abs(double a)
{
    return a < 0.0 ? -a : a;
}

int double_equal(double a, double b)
{
    return double_abs(a - b) < EPSILON;
}

int main(int argc, char const *argv[])
{
    double a = 3.141592653589;
    double b = -0.69;
    double c = 28.39219;
    double d = 20.4;
    int   e = 30;

    double neg_result = -a;
    double add_result = a + b;
    double sub_result = a - b;
    double mul_result = a * b;
    double div_result = a / b;
    double mac_result = (a * b) + c;
    int   cvt1_result = d; // double to integer
    double cvt2_result = e; // integer to double

    int neg_correct = double_equal(neg_result, -3.141592653589);
    int add_correct = double_equal(add_result, 2.451592654);
    int sub_correct = double_equal(sub_result, 3.831592654);
    int mul_correct = double_equal(mul_result, -2.167698931);
    int div_correct = double_equal(div_result, -4.553032831);
    int mac_correct = double_equal(mac_result, 26.224491069);
    int cvt1_correct = cvt1_result == 20;
    int cvt2_correct = double_equal(cvt2_result, 30.0);

    if (neg_correct && add_correct && sub_correct && mul_correct && div_correct && mac_correct && cvt1_correct && cvt2_correct)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}
