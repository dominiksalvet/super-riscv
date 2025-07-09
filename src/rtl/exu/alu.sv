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

module alu // arithmetic logic unit
    import srv_defs::*;
(
    input logic [31:0] s1,
    input logic [31:0] s2,
    input alu_opcode_t opc,

    output logic [31:0] res,
    output logic        eq,
    output logic        lt
);

// reusable adder
logic adder_sign;
logic adder_sub;
logic [32:0] adder_s1, adder_s2;

assign adder_sign = opc != ALU_SLTU;
assign adder_sub = opc != ALU_ADD;
assign adder_s1 = {adder_sign & s1[31], s1}; // conditional sign extension
assign adder_s2 = {adder_sign & s2[31], s2} ^ {33{adder_sub}};

logic [31:0] adder_res;
logic adder_cout;

assign {adder_cout, adder_res} = adder_s1 + adder_s2 + {32'b0, adder_sub};

always_comb begin : calculations
    case (opc)
        ALU_ADD, ALU_SUB:  res = adder_res;
        ALU_SLT, ALU_SLTU: res = {31'b0, adder_cout};
        ALU_SLL:           res = s1 << s2[4:0];
        ALU_SRL:           res = s1 >> s2[4:0];
        ALU_SRA:           res = signed'(s1) >>> s2[4:0];
        ALU_XOR:           res = s1 ^ s2;
        ALU_OR:            res = s1 | s2;
        ALU_AND:           res = s1 & s2;
        default:           res = 'x;
    endcase
end

assign eq = s1 == s2;
assign lt = adder_cout;

endmodule
