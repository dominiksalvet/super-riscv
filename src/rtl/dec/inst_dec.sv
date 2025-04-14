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

module inst_dec // instruction decoder
    import riscv_defs::*;
    import srv_defs::*;
(
    input logic [31:0] inst,

    output enable_pkt_t en_p,

    output logic [4:0]  rs1_addr,
    output logic [4:0]  rs2_addr,
    output logic [4:0]  rd_addr,
    output logic [31:0] imm,

    output alu_s1_mux_t alu_s1_sel,
    output alu_s2_mux_t alu_s2_sel,
    output alu_opcode_t alu_opc,
    output agu_s1_mux_t agu_s1_sel,
    output logic [3:0]  extra_opc // reuse funct3 as much as possible
);

// instructions fields
// verilator lint_off UNUSED
logic [6:0] funct7;
// verilator lint_on UNUSED
logic [4:0] rs2;
logic [4:0] rs1;
logic [2:0] funct3;
logic [4:0] rd;
opcode_t opcode;

assign funct7 = inst[31:25];
assign rs2 = inst[24:20];
assign rs1 = inst[19:15];
assign funct3 = inst[14:12];
assign rd = inst[11:7];
assign opcode = opcode_t'(inst[6:0]);

// initialize enable packet
assign en_p.rs1 = opcode inside {OPC_JALR, OPC_BRANCH, OPC_LOAD, OPC_STORE, OPC_OP_IMM, OPC_OP};
assign en_p.rs2 = opcode inside {OPC_BRANCH, OPC_STORE, OPC_OP};
assign en_p.imm = opcode inside {OPC_LUI, OPC_AUIPC, OPC_JAL, OPC_JALR, OPC_BRANCH, OPC_LOAD, OPC_STORE, OPC_OP_IMM};
assign en_p.pc = opcode inside {OPC_AUIPC, OPC_JAL, OPC_JALR, OPC_BRANCH};
assign en_p.alu = opcode inside {OPC_LUI, OPC_AUIPC, OPC_JAL, OPC_JALR, OPC_BRANCH, OPC_OP_IMM, OPC_OP};
assign en_p.agu = opcode inside {OPC_JAL, OPC_JALR, OPC_BRANCH, OPC_LOAD, OPC_STORE};
assign en_p.bru = opcode inside {OPC_JAL, OPC_JALR, OPC_BRANCH};
assign en_p.lsu = opcode inside {OPC_LOAD, OPC_STORE};
// TODO: consider clearing rd enable bit when rd_addr==0
assign en_p.rd = opcode inside {OPC_LUI, OPC_AUIPC, OPC_JAL, OPC_JALR, OPC_LOAD, OPC_OP_IMM, OPC_OP};

// prepare operands
assign rs1_addr = rs1;
assign rs2_addr = rs2;
assign rd_addr = rd;

// immediate value decoding
logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;

// TODO: consider immediate extending in EX1 stage
assign i_imm = 32'(signed'(inst[31:20]));
assign s_imm = 32'(signed'({inst[31:25], inst[11:7]}));
assign b_imm = 32'(signed'({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}));
assign u_imm = {inst[31:12], 12'b0};
assign j_imm = 32'(signed'({inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}));

always_comb begin : imm_decoding
    case (opcode)
        OPC_JALR, OPC_LOAD, OPC_OP_IMM: imm = i_imm;
        OPC_STORE:                      imm = s_imm;
        OPC_BRANCH:                     imm = b_imm;
        OPC_LUI, OPC_AUIPC:             imm = u_imm;
        OPC_JAL:                        imm = j_imm;
        default:                        imm = 'x;
    endcase
end

// functional units control signals
always_comb begin : alu_ctl
    case (opcode)
        OPC_LUI:                        alu_s1_sel = ALU_S1_0;
        OPC_AUIPC, OPC_JAL, OPC_JALR:   alu_s1_sel = ALU_S1_PC;
        OPC_BRANCH, OPC_OP_IMM, OPC_OP: alu_s1_sel = ALU_S1_RS1;
        default:                        alu_s1_sel = alu_s1_mux_t'('x);
    endcase

    case (opcode)
        OPC_JAL, OPC_JALR:              alu_s2_sel = ALU_S2_4;
        OPC_LUI, OPC_AUIPC, OPC_OP_IMM: alu_s2_sel = ALU_S2_IMM;
        OPC_BRANCH, OPC_OP:             alu_s2_sel = ALU_S2_RS2;
        default:                        alu_s2_sel = alu_s2_mux_t'('x);
    endcase

    case (opcode)
        OPC_OP: alu_opc = alu_opcode_t'({funct7[5], funct3});
        OPC_OP_IMM: begin
            if (funct3 == FN3_SRL_SRA)
                alu_opc = alu_opcode_t'({funct7[5], funct3});
            else
                alu_opc = alu_opcode_t'({1'b0, funct3});
        end
        OPC_BRANCH: begin
            if (funct3 inside {FN3_BLTU, FN3_BGEU})
                alu_opc = ALU_SLTU;
            else
                alu_opc = ALU_SLT;
        end
        OPC_LUI, OPC_AUIPC, OPC_JAL, OPC_JALR: alu_opc = ALU_ADD;
        default: alu_opc = alu_opcode_t'('x);
    endcase
end

always_comb begin : agu_ctl
    case (opcode)
        OPC_JALR, OPC_LOAD, OPC_STORE: agu_s1_sel = AGU_S1_RS1;
        OPC_JAL, OPC_BRANCH:           agu_s1_sel = AGU_S1_PC;
        default:                       agu_s1_sel = agu_s1_mux_t'('x);
    endcase
end

always_comb begin : extra_ctl
    case (opcode)
        OPC_JAL, OPC_JALR, OPC_BRANCH:  extra_opc = {opcode[2], funct3};
        OPC_LOAD, OPC_STORE:            extra_opc = {opcode[5], funct3};
        default:                        extra_opc = 'x;
    endcase
end

endmodule
