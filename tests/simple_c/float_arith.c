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

#define EPSILON 1e-6f

float float_abs(float a)
{
    return a < 0.f ? -a : a;
}

int float_equal(float a, float b)
{
    return float_abs(a - b) < EPSILON;
}

int main(int argc, char const *argv[])
{
    float a = 3.141592653589f;
    float b = -0.69f;
    float c = 28.39219f;
    float d = 20.4f;
    int   e = 30;

    float neg_result = -a;
    float add_result = a + b;
    float sub_result = a - b;
    float mul_result = a * b;
    float div_result = a / b;
    float mac_result = (a * b) + c;
    int   cvt1_result = d; // float to integer
    float cvt2_result = e; // integer to float

    int neg_correct = float_equal(neg_result, -3.141592653589f);
    int add_correct = float_equal(add_result, 2.451592654f);
    int sub_correct = float_equal(sub_result, 3.831592654f);
    int mul_correct = float_equal(mul_result, -2.167698931f);
    int div_correct = float_equal(div_result, -4.553032831f);
    int mac_correct = float_equal(mac_result, 26.224491069f);
    int cvt1_correct = cvt1_result == 20;
    int cvt2_correct = float_equal(cvt2_result, 30.0f);

    if (neg_correct && add_correct && sub_correct && mul_correct && div_correct && mac_correct && cvt1_correct && cvt2_correct)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}
