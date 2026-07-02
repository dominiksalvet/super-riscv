/*
    Super RISC-V - superscalar dual-issue RISC-V processor
    Copyright (C) 2026 Dominik Salvet

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

package exec_trace_pkg; // RISC-V execution tracer

import riscv_types_pkg::*;

// used for tracking architectural events
typedef struct packed {
    logic [31:0] addr;
    logic [31:0] inst;
    logic        gpr_we;
    logic [4:0]  gpr_addr;
    logic [31:0] gpr_wdata;
    logic        mem_en;
    logic [3:0]  mem_opc;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic        pc_we;
    logic [31:0] pc_wdata;
} trace_pkt_t;

function automatic string get_trace_header();
    return {
        " ---------------------------------------------------------------------------------------------------------------------------------------------------------- \n",
        "| Slot | Cycle      | Retired    | Address    | Instruction | Disassembly                    | Events                                                      |\n",
        "|------|------------|------------|------------|-------------|--------------------------------|-------------------------------------------------------------|"
    };
endfunction

function automatic string get_trace_string(
    int issue_slot,
    longint cur_inst_ret,
    longint cur_cycle,
    trace_pkt_t trace_p
);
    string msg;
    string event_msg;

    msg = $sformatf(
        "|   i%0d | %10d | %10d | 0x%h |  0x%h | %-30s |",
        issue_slot,
        cur_cycle,
        cur_inst_ret,
        trace_p.addr,
        trace_p.inst,
        riscv_disasm(trace_p.addr, trace_p.inst)
    );

    if (trace_p.gpr_we && trace_p.gpr_addr != 5'b0) begin
        event_msg = $sformatf(
            "         gpr[%d] = 0x%h |",
            trace_p.gpr_addr,
            trace_p.gpr_wdata
        );
        msg = {msg, event_msg};
    end

    if (trace_p.mem_en) begin
        if (trace_p.mem_opc[3] == OPC_LOAD[5]) begin
            int read_bytes;

            case (trace_p.mem_opc[2:0])
                FN3_LB, FN3_LBU: read_bytes = 1;
                FN3_LH, FN3_LHU: read_bytes = 2;
                default:         read_bytes = 4;
            endcase
            
            event_msg = $sformatf(
                "      read_%0db mem[0x%h] |",
                read_bytes,
                trace_p.mem_addr
            );
        end else begin
            string written_val;

            case (trace_p.mem_opc[2:0])
                FN3_SB:  written_val = $sformatf("0x%h      ", trace_p.mem_wdata[7:0]);
                FN3_SH:  written_val = $sformatf("0x%h    ", trace_p.mem_wdata[15:0]);
                default: written_val = $sformatf("0x%h", trace_p.mem_wdata);
            endcase

            event_msg = $sformatf(
                " mem[0x%h] = %s |",
                trace_p.mem_addr,
                written_val
            );
        end
        
        msg = {msg, event_msg};
    end

    if (trace_p.pc_we) begin
        event_msg = $sformatf("              pc = 0x%h |", trace_p.pc_wdata);
        msg = {msg, event_msg};
    end

    return msg;
endfunction

function automatic string riscv_disasm(
    logic [31:0] inst_addr,
    logic [31:0] inst
);
    string disasm;

    logic [6:0] funct7;
    logic [4:0] rs2;
    logic [4:0] rs1;
    logic [2:0] funct3;
    logic [4:0] rd;
    opcode_t    opcode;

    int i_imm, s_imm, b_imm, j_imm;
    logic [31:0] b_imm_tar, j_imm_tar;

    funct7 = inst[31:25];
    rs2    = inst[24:20];
    rs1    = inst[19:15];
    funct3 = inst[14:12];
    rd     = inst[11:7];
    opcode = opcode_t'(inst[6:0]);

    i_imm = int'(signed'(inst[31:20]));
    s_imm = int'(signed'({inst[31:25], inst[11:7]}));
    b_imm = int'(signed'({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}));
    j_imm = int'(signed'({inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}));

    b_imm_tar = inst_addr + b_imm;
    j_imm_tar = inst_addr + j_imm;

    case (opcode)
        OPC_OP_IMM: begin
            case (funct3)
                FN3_ADD_SUB: disasm = $sformatf("addi x%0d, x%0d, %0d", rd, rs1, i_imm);
                FN3_SLL: begin
                    if (funct7 == 7'b0000000)
                        disasm = $sformatf("slli x%0d, x%0d, %0d", rd, rs1, inst[24:20]);
                end
                FN3_SLT:     disasm = $sformatf("slti x%0d, x%0d, %0d", rd, rs1, i_imm);
                FN3_SLTU:    disasm = $sformatf("sltiu x%0d, x%0d, %0d", rd, rs1, i_imm);
                FN3_XOR:     disasm = $sformatf("xori x%0d, x%0d, %0d", rd, rs1, i_imm);
                FN3_SRL_SRA: begin
                    case (funct7)
                        7'b0000000: disasm = $sformatf("srli x%0d, x%0d, %0d", rd, rs1, inst[24:20]);
                        7'b0100000: disasm = $sformatf("srai x%0d, x%0d, %0d", rd, rs1, inst[24:20]);
                        default;
                    endcase
                end
                FN3_OR:      disasm = $sformatf("ori x%0d, x%0d, %0d", rd, rs1, i_imm);
                FN3_AND:     disasm = $sformatf("andi x%0d, x%0d, %0d", rd, rs1, i_imm);
                default;
            endcase
        end
        OPC_LUI: begin
            disasm = $sformatf("lui x%0d, 0x%x", rd, inst[31:12]);
        end
        OPC_AUIPC: begin
            disasm = $sformatf("auipc x%0d, 0x%x", rd, inst[31:12]);
        end
        OPC_OP: begin
            case ({funct7, funct3})
                {7'b0000000, FN3_ADD_SUB}: disasm = $sformatf("add x%0d, x%0d, x%0d", rd, rs1, rs2);
                {7'b0100000, FN3_ADD_SUB}: disasm = $sformatf("sub x%0d, x%0d, x%0d", rd, rs1, rs2);
                {7'b0000000, FN3_SLL}:     disasm = $sformatf("sll x%0d, x%0d, x%0d", rd, rs1, rs2);
                {7'b0000000, FN3_SLT}:     disasm = $sformatf("slt x%0d, x%0d, x%0d", rd, rs1, rs2);
                {7'b0000000, FN3_SLTU}:    disasm = $sformatf("sltu x%0d, x%0d, x%0d", rd, rs1, rs2);
                {7'b0000000, FN3_XOR}:     disasm = $sformatf("xor x%0d, x%0d, x%0d", rd, rs1, rs2);
                {7'b0000000, FN3_SRL_SRA}: disasm = $sformatf("srl x%0d, x%0d, x%0d", rd, rs1, rs2);
                {7'b0100000, FN3_SRL_SRA}: disasm = $sformatf("sra x%0d, x%0d, x%0d", rd, rs1, rs2);
                {7'b0000000, FN3_OR}:      disasm = $sformatf("or x%0d, x%0d, x%0d", rd, rs1, rs2);
                {7'b0000000, FN3_AND}:     disasm = $sformatf("and x%0d, x%0d, x%0d", rd, rs1, rs2);
                default;
            endcase
        end
        OPC_JAL: begin
            disasm = $sformatf("jal x%0d, 0x%h", rd, j_imm_tar);
        end
        OPC_JALR: begin
            disasm = $sformatf("jalr x%0d, %0d(x%0d)", rd, i_imm, rs1);
        end
        OPC_BRANCH: begin
            case (funct3)
                FN3_BEQ:  disasm = $sformatf("beq x%0d, x%0d, 0x%h", rs1, rs2, b_imm_tar);
                FN3_BNE:  disasm = $sformatf("bne x%0d, x%0d, 0x%h", rs1, rs2, b_imm_tar);
                FN3_BLT:  disasm = $sformatf("blt x%0d, x%0d, 0x%h", rs1, rs2, b_imm_tar);
                FN3_BGE:  disasm = $sformatf("bge x%0d, x%0d, 0x%h", rs1, rs2, b_imm_tar);
                FN3_BLTU: disasm = $sformatf("bltu x%0d, x%0d, 0x%h", rs1, rs2, b_imm_tar);
                FN3_BGEU: disasm = $sformatf("bgeu x%0d, x%0d, 0x%h", rs1, rs2, b_imm_tar);
                default;
            endcase
        end
        OPC_LOAD: begin
            case (funct3)
                FN3_LB:  disasm = $sformatf("lb x%0d, %0d(x%0d)", rd, i_imm, rs1);
                FN3_LH:  disasm = $sformatf("lh x%0d, %0d(x%0d)", rd, i_imm, rs1);
                FN3_LW:  disasm = $sformatf("lw x%0d, %0d(x%0d)", rd, i_imm, rs1);
                FN3_LBU: disasm = $sformatf("lbu x%0d, %0d(x%0d)", rd, i_imm, rs1);
                FN3_LHU: disasm = $sformatf("lhu x%0d, %0d(x%0d)", rd, i_imm, rs1);
                default;
            endcase
        end
        OPC_STORE: begin
            case (funct3)
                FN3_SB:  disasm = $sformatf("sb x%0d, %0d(x%0d)", rs2, s_imm, rs1);
                FN3_SH:  disasm = $sformatf("sh x%0d, %0d(x%0d)", rs2, s_imm, rs1);
                FN3_SW:  disasm = $sformatf("sw x%0d, %0d(x%0d)", rs2, s_imm, rs1);
                default;
            endcase
        end
        OPC_MISC_MEM: begin
            if (funct3 == 3'b000)
                disasm = "fence"; // all fence variants are disassembled like this
        end
        // TODO: add OPC_SYSTEM once ECALL and EBREAK is supported
        default;
    endcase

    if (disasm.len() == 0)
        disasm = "<unrecognized instruction>";

    return disasm;
endfunction

endpackage
