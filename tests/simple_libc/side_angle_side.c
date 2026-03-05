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

#include <math.h>
#include <stdio.h>

#define EPSILON 1e-4f
#define PI_VAL 3.14159265358979323846f

// expected values
float side_a_exp;
float side_b_exp;
float side_c_exp;

float angle_a_exp; // angle in front of side a
float angle_b_exp;
float angle_c_exp;

int float_equal(float a, float b)
{
    return fabsf(a - b) < EPSILON;
}

int main(int argc, char const *argv[])
{
    // read expected side values
    if (scanf("%f %f %f", &side_a_exp, &side_b_exp, &side_c_exp) != 3) {
        return 1;
    }
    // read expected angle values
    if (scanf("%f %f %f", &angle_a_exp, &angle_b_exp, &angle_c_exp) != 3) {
        return 2;
    }

    // we pretend we know side a, side b, angle C
    float side_a = side_a_exp;
    float side_b = side_b_exp;
    float angle_c = angle_c_exp;

    // side c - law of cosines
    float side_c = sqrtf(
        powf(side_a, 2.0f) + powf(side_b, 2.0f) - (2 * side_a * side_b * cosf(angle_c))
    );

    // angle A - law of sines
    float angle_a = asinf(
        (side_a * sinf(angle_c)) / side_c
    );

    // angle B - angles sum to PI
    float angle_b = PI_VAL - angle_a - angle_c;

    if (
        float_equal(side_c, side_c_exp) &&
        float_equal(angle_a, angle_a_exp) &&
        float_equal(angle_b, angle_b_exp)
    ) {
        return 0;
    }

    return 3;
}
