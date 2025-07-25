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

package riscv_defs;

typedef enum logic [6:0] {
    OPC_OP_IMM =    7'b0010011,
    OPC_LUI =       7'b0110111,
    OPC_AUIPC =     7'b0010111,
    OPC_OP =        7'b0110011,
    OPC_JAL =       7'b1101111,
    OPC_JALR =      7'b1100111,
    OPC_BRANCH =    7'b1100011,
    OPC_LOAD =      7'b0000011,
    OPC_STORE =     7'b0100011,
    OPC_MISC_MEM =  7'b0001111,
    OPC_SYSTEM =    7'b1110011
} opcode_t;

typedef enum logic [2:0] {
    FN3_BEQ =   3'b000,
    FN3_BNE =   3'b001,
    FN3_BLT =   3'b100,
    FN3_BGE =   3'b101,
    FN3_BLTU =  3'b110,
    FN3_BGEU =  3'b111
} branch_fn3_t;

typedef enum logic [2:0] {
    FN3_LB =    3'b000,
    FN3_LH =    3'b001,
    FN3_LW =    3'b010,
    FN3_LBU =   3'b100,
    FN3_LHU =   3'b101
} load_fn3_t;

typedef enum logic [2:0] {
    FN3_SB = 3'b000,
    FN3_SH = 3'b001,
    FN3_SW = 3'b010
} store_fn3_t;

typedef enum logic [2:0] {
    FN3_SRL_SRA = 3'b101
} arith_fn3_t;

endpackage
