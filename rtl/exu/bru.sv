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

module bru // branch unit
    import riscv_defs::*;
(
    input logic        i0_valid, // i0 uses BRU
    input logic [3:0]  i0_opc, // branch opcode
    input logic        i0_eq,
    input logic        i0_lt,
    input logic [31:0] i0_jmp_addr,

    input logic        i1_valid,
    input logic [3:0]  i1_opc,
    input logic        i1_eq,
    input logic        i1_lt,
    input logic [31:0] i1_jmp_addr,

    output logic        take_jmp,
    output logic        jmp_src_i0,
    output logic [31:0] jmp_addr
);

logic i0_jmp_en, i1_jmp_en;

always_comb begin : enable_jmps
    if (i0_opc[3] == OPC_JAL[2])
        i0_jmp_en = 1'b1;
    else begin
        case (i0_opc[2:0])
            FN3_BEQ:           i0_jmp_en =  i0_eq;
            FN3_BNE:           i0_jmp_en = !i0_eq;
            FN3_BLT, FN3_BLTU: i0_jmp_en =  i0_lt;
            FN3_BGE, FN3_BGEU: i0_jmp_en = !i0_lt;
            default:           i0_jmp_en = 'x;
        endcase
    end

    if (i1_opc[3] == OPC_JAL[2])
        i1_jmp_en = 1'b1;
    else begin
        case (i1_opc[2:0])
            FN3_BEQ:           i1_jmp_en =  i1_eq;
            FN3_BNE:           i1_jmp_en = !i1_eq;
            FN3_BLT, FN3_BLTU: i1_jmp_en =  i1_lt;
            FN3_BGE, FN3_BGEU: i1_jmp_en = !i1_lt;
            default:           i1_jmp_en = 'x;
        endcase
    end
end

logic i0_take_jmp, i1_take_jmp;

assign i0_take_jmp = i0_jmp_en && i0_valid;
assign i1_take_jmp = i1_jmp_en && i1_valid;

assign take_jmp = i0_take_jmp || i1_take_jmp;
assign jmp_src_i0 = i0_take_jmp; // i0 has higher priority
assign jmp_addr = i0_take_jmp ? i0_jmp_addr : i1_jmp_addr;

endmodule
