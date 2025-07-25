/*
    Super RISC-V - superscalar dual-issue RISC-V processor
    Copyright (C) 2024 Dominik Salvet

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

// ACCEPTED ARGUMENTS:
//   +waves               enable signal values dump
//   +waves+file=<path>   path of output signal waves file
//   +max+cycles=<value>  max cycles of simulation
//   +test+path=<path>    path to memory image of test
//   +verilator*          Verilator simulation runtime arguments

#include <iostream>
#include <string>
#include <memory>
#include <verilated.h>
#include <verilated_fst_c.h>
#include "Vtb.h"

using std::string;
using std::unique_ptr;
using std::make_unique;

constexpr vluint64_t TIME_STAMP_STEP = 5;

vluint64_t time_stamp = 0;

// report simulation time if needed (e.g., for assertions)
double sc_time_stamp() {
    return time_stamp;
}

int main(int argc, char** argv)
{
    bool waves = false;
    string waves_path = "waves.fst";

    for (int i = 1; i < argc; i++)
    {
        const string arg = argv[i];
        const size_t equal_index = arg.find('=');

        if (equal_index == string::npos) // no '=' in argument
        {
            if (arg == "+waves") {
                waves = true;
            }
        }
        else
        {
            // split option and its value based on '=' character
            const string arg_opt(arg, 0, equal_index);
            const string arg_val(arg, equal_index + 1, arg.length() - equal_index - 1);

            if (arg_opt == "+waves+file") {
                waves_path = arg_val;
            }
        }
    }

    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(waves);
    unique_ptr<Vtb> tb(new Vtb); // testbench instance

    unique_ptr<VerilatedFstC> tfp;
    if (waves)
    {
        tfp = make_unique<VerilatedFstC>();
        tb->trace(tfp.get(), 99);
        tfp->open(waves_path.c_str());

        if (!tfp->isOpen())
        {
            std::cerr << "Unable to create file for waves: " << waves_path << std::endl;
            return 1;
        }
    }

    // simulation
    tb->clk = 0;
    tb->eval(); // call initial blocks

    while (!Verilated::gotFinish())
    {
        if (waves) {
            tfp->dump(time_stamp);
        }

        time_stamp += TIME_STAMP_STEP;
        tb->clk = !tb->clk;
        tb->eval();
    }

    // TODO: call these even on $fatal or assertions
    tb->final(); // call final blocks

    if (waves)
    {
        tfp->dump(time_stamp);
        tfp->close();
    }

    return 0;
}
