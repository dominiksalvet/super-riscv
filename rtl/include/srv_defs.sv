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

package srv_defs; // Super RISC-V defines

typedef struct packed {
    logic           i0_valid;
    logic [31:0]    i0_inst;
    logic           i1_valid;
    logic [31:0]    i1_inst;
    logic [31:0]    addr; // shared instructon address
} inst_pkt_t;

typedef struct packed {
    logic       i0_valid;
    logic       i0_ready; // result should be available on next clock
    logic [4:0] i0_addr;
    logic       i1_valid;
    logic       i1_ready;
    logic [4:0] i1_addr;
} fwd_pkt_t;

typedef enum {
    FWD_EX2_I1,
    FWD_EX2_I0,
    FWD_EX3_I1,
    FWD_EX3_I0,
    FWD_WB_I1,
    FWD_WB_I0,
    FWD_NONE
} fwd_src_t;

typedef enum {
    ALU_S1_RS1,
    ALU_S1_PC,
    ALU_S1_0 // value 0
} alu_s1_mux_t;

typedef enum {
    ALU_S2_RS2,
    ALU_S2_IMM,
    ALU_S2_4 // value 4
} alu_s2_mux_t;

typedef enum {
    AGU_S1_RS1,
    AGU_S1_PC
} agu_s1_mux_t;

// reuse funct3 as much as possible
typedef enum logic [3:0] {
    ALU_ADD =   4'b0000,
    ALU_SUB =   4'b1000,
    ALU_SLL =   4'b0001,
    ALU_SLT =   4'b0010,
    ALU_SLTU =  4'b0011,
    ALU_XOR =   4'b0100,
    ALU_SRL =   4'b0101,
    ALU_SRA =   4'b1101,
    ALU_OR =    4'b0110,
    ALU_AND =   4'b0111
} alu_opcode_t;

// describes instruction and its resources
typedef struct packed {
    logic rs1;
    logic rs2;
    logic imm;
    logic pc; // read PC
    logic alu;
    logic agu;
    logic bru; // jump or branch
    logic lsu; // load or store
    logic rd;
} enable_pkt_t;

// data and opcodes for instruction execution
typedef struct packed {
    logic [31:0] rs1_val;
    logic [31:0] rs2_val;
    logic [31:0] imm;
    alu_s1_mux_t alu_s1_sel;
    alu_s2_mux_t alu_s2_sel;
    alu_opcode_t alu_opc;
    agu_s1_mux_t agu_s1_sel;
    logic [3:0]  extra_opc; // described in inst_dec
    logic [4:0]  rd_addr;
} exec_pkt_t;

typedef struct packed {
    logic        i0_valid;
    logic [4:0]  i0_addr;
    logic [31:0] i0_val;
    logic        i1_valid;
    logic [4:0]  i1_addr;
    logic [31:0] i1_val;
} res_pkt_t; // result packet

// pipe in which instruction should be executed
typedef enum {
    PIPE_EXU,
    PIPE_LSU
} exec_pipe_t;

typedef struct packed {
    logic        valid;
    logic [3:0]  opc;
    logic [31:0] addr;
    logic [31:0] wdata;
} lsu_pkt_t;

endpackage
