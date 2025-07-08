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

module exu // execution unit
    import srv_defs::*;
(
    input logic  clk,
    input logic  rst,
    output logic exu_ready,

    // signals from decoding unit
    input logic        dec_i0_valid,
    input enable_pkt_t dec_i0_en_p,
    input exec_pkt_t   dec_i0_exec_p,
    input logic        dec_i1_valid,
    input enable_pkt_t dec_i1_en_p,
    input exec_pkt_t   dec_i1_exec_p,
    input logic [31:0] dec_pc_val,

    // forwarding control
    input fwd_src_t dec_i0_rs1_fwd_src,
    input fwd_src_t dec_i0_rs2_fwd_src,
    input fwd_src_t dec_i1_rs1_fwd_src,
    input fwd_src_t dec_i1_rs2_fwd_src,

    output fwd_pkt_t ex1_fwd_p,
    output fwd_pkt_t ex2_fwd_p,
    output fwd_pkt_t ex3_fwd_p,
    output res_pkt_t exu_res_p, // result

    output logic        ifu_take_jmp,
    output logic [31:0] ifu_jmp_addr,

    // load-store unit signals
    output lsu_pkt_t    lsu_p,

    input logic         lsu_addr_wait,
    input logic         lsu_resp_wait,
    input logic         lsu_resp_valid,
    input logic [31:0]  lsu_rdata
);

// EXU entry registers (EX1 stage)
logic        r_i0_valid,       r_i1_valid;
logic        r_i0_bru_en,      r_i1_bru_en;
logic        r_i0_lsu_en,      r_i1_lsu_en;
logic        r_i0_rd_en,       r_i1_rd_en;
exec_pkt_t   r_i0_exec_p,      r_i1_exec_p;
fwd_src_t    r_i0_rs1_fwd_src, r_i1_rs1_fwd_src;
fwd_src_t    r_i0_rs2_fwd_src, r_i1_rs2_fwd_src;
logic [31:0] r_pc_val;

// TODO: remove all data registers from rst paths
// TODO: consider whether simplify some write enable logic (rs1/2 val, imm, ...)
// TODO: consider filling empty EXU stages (ex1, ex2, ...) when EXU is stalling as a whole
always_ff @(posedge clk) begin : catch_decoded
    if (rst || ifu_take_jmp) begin
        r_i0_valid <= 1'b0;
        r_i1_valid <= 1'b0;
    end else if (exu_ready) begin
        if (dec_i0_valid) begin
            if (dec_i0_en_p.rs1) begin
                r_i0_rs1_fwd_src <= dec_i0_rs1_fwd_src;

                if (dec_i0_rs1_fwd_src == FWD_NONE)
                    r_i0_exec_p.rs1_val <= dec_i0_exec_p.rs1_val;
            end
            
            if (dec_i0_en_p.rs2) begin
                r_i0_rs2_fwd_src <= dec_i0_rs2_fwd_src;

                if (dec_i0_rs2_fwd_src == FWD_NONE)
                    r_i0_exec_p.rs2_val <= dec_i0_exec_p.rs2_val;
            end

            if (dec_i0_en_p.imm)
                r_i0_exec_p.imm <= dec_i0_exec_p.imm;

            if (dec_i0_en_p.alu) begin
                r_i0_exec_p.alu_s1_sel <= dec_i0_exec_p.alu_s1_sel;
                r_i0_exec_p.alu_s2_sel <= dec_i0_exec_p.alu_s2_sel;
                r_i0_exec_p.alu_opc <= dec_i0_exec_p.alu_opc;
            end

            if (dec_i0_en_p.agu)
                r_i0_exec_p.agu_s1_sel <= dec_i0_exec_p.agu_s1_sel;
            
            if (dec_i0_en_p.bru || dec_i0_en_p.lsu)
                r_i0_exec_p.extra_opc <= dec_i0_exec_p.extra_opc;

            if (dec_i0_en_p.rd)
                r_i0_exec_p.rd_addr <= dec_i0_exec_p.rd_addr;

            r_i0_bru_en <= dec_i0_en_p.bru;
            r_i0_lsu_en <= dec_i0_en_p.lsu;
            r_i0_rd_en <= dec_i0_en_p.rd;
        end

        if (dec_i1_valid) begin
            if (dec_i1_en_p.rs1) begin
                r_i1_rs1_fwd_src <= dec_i1_rs1_fwd_src;

                if (dec_i1_rs1_fwd_src == FWD_NONE)
                    r_i1_exec_p.rs1_val <= dec_i1_exec_p.rs1_val;
            end
            
            if (dec_i1_en_p.rs2) begin
                r_i1_rs2_fwd_src <= dec_i1_rs2_fwd_src;

                if (dec_i1_rs2_fwd_src == FWD_NONE)
                    r_i1_exec_p.rs2_val <= dec_i1_exec_p.rs2_val;
            end

            if (dec_i1_en_p.imm)
                r_i1_exec_p.imm <= dec_i1_exec_p.imm;

            if (dec_i1_en_p.alu) begin
                r_i1_exec_p.alu_s1_sel <= dec_i1_exec_p.alu_s1_sel;
                r_i1_exec_p.alu_s2_sel <= dec_i1_exec_p.alu_s2_sel;
                r_i1_exec_p.alu_opc <= dec_i1_exec_p.alu_opc;
            end

            if (dec_i1_en_p.agu)
                r_i1_exec_p.agu_s1_sel <= dec_i1_exec_p.agu_s1_sel;
            
            if (dec_i1_en_p.bru || dec_i1_en_p.lsu)
                r_i1_exec_p.extra_opc <= dec_i1_exec_p.extra_opc;

            if (dec_i1_en_p.rd)
                r_i1_exec_p.rd_addr <= dec_i1_exec_p.rd_addr;

            r_i1_bru_en <= dec_i1_en_p.bru;
            r_i1_lsu_en <= dec_i1_en_p.lsu;
            r_i1_rd_en <= dec_i1_en_p.rd;
        end

        if ((dec_i0_valid && dec_i0_en_p.pc) || (dec_i1_valid && dec_i1_en_p.pc))
            r_pc_val <= dec_pc_val;

        r_i0_valid <= dec_i0_valid;
        r_i1_valid <= dec_i1_valid;
    end
end

logic [31:0] i0_pc_val, i1_pc_val;
assign i0_pc_val = r_pc_val;
assign i1_pc_val = {r_pc_val[31:3], 1'b1, r_pc_val[1:0]};

// operand forwarding in EX1 stage
logic [31:0] i0_final_rs1_val, i0_final_rs2_val, i1_final_rs1_val, i1_final_rs2_val;

always_comb begin : forward_values
    case (r_i0_rs1_fwd_src)
        FWD_EX2_I1: i0_final_rs1_val = r_ex2_i1_rd_val;
        FWD_EX2_I0: i0_final_rs1_val = r_ex2_i0_rd_val;
        FWD_EX3_I1: i0_final_rs1_val = r_ex3_i1_rd_val;
        FWD_EX3_I0: i0_final_rs1_val = r_ex3_i0_rd_val;
        FWD_WB_I1:  i0_final_rs1_val = r_wb_i1_rd_val;
        FWD_WB_I0:  i0_final_rs1_val = r_wb_i0_rd_val;
        FWD_NONE:   i0_final_rs1_val = r_i0_exec_p.rs1_val;
    endcase

    case (r_i0_rs2_fwd_src)
        FWD_EX2_I1: i0_final_rs2_val = r_ex2_i1_rd_val;
        FWD_EX2_I0: i0_final_rs2_val = r_ex2_i0_rd_val;
        FWD_EX3_I1: i0_final_rs2_val = r_ex3_i1_rd_val;
        FWD_EX3_I0: i0_final_rs2_val = r_ex3_i0_rd_val;
        FWD_WB_I1:  i0_final_rs2_val = r_wb_i1_rd_val;
        FWD_WB_I0:  i0_final_rs2_val = r_wb_i0_rd_val;
        FWD_NONE:   i0_final_rs2_val = r_i0_exec_p.rs2_val;
    endcase

    case (r_i1_rs1_fwd_src)
        FWD_EX2_I1: i1_final_rs1_val = r_ex2_i1_rd_val;
        FWD_EX2_I0: i1_final_rs1_val = r_ex2_i0_rd_val;
        FWD_EX3_I1: i1_final_rs1_val = r_ex3_i1_rd_val;
        FWD_EX3_I0: i1_final_rs1_val = r_ex3_i0_rd_val;
        FWD_WB_I1:  i1_final_rs1_val = r_wb_i1_rd_val;
        FWD_WB_I0:  i1_final_rs1_val = r_wb_i0_rd_val;
        FWD_NONE:   i1_final_rs1_val = r_i1_exec_p.rs1_val;
    endcase

    case (r_i1_rs2_fwd_src)
        FWD_EX2_I1: i1_final_rs2_val = r_ex2_i1_rd_val;
        FWD_EX2_I0: i1_final_rs2_val = r_ex2_i0_rd_val;
        FWD_EX3_I1: i1_final_rs2_val = r_ex3_i1_rd_val;
        FWD_EX3_I0: i1_final_rs2_val = r_ex3_i0_rd_val;
        FWD_WB_I1:  i1_final_rs2_val = r_wb_i1_rd_val;
        FWD_WB_I0:  i1_final_rs2_val = r_wb_i0_rd_val;
        FWD_NONE:   i1_final_rs2_val = r_i1_exec_p.rs2_val;
    endcase
end

logic [31:0] i0_alu_s1,  i1_alu_s1;
logic [31:0] i0_alu_s2,  i1_alu_s2;
logic [31:0] i0_alu_res, i1_alu_res;
logic        i0_alu_eq,  i1_alu_eq;
logic        i0_alu_lt,  i1_alu_lt;

always_comb begin : set_alu_operands
    case (r_i0_exec_p.alu_s1_sel)
        ALU_S1_RS1: i0_alu_s1 = i0_final_rs1_val;
        ALU_S1_PC:  i0_alu_s1 = i0_pc_val;
        ALU_S1_0:   i0_alu_s1 = 32'b0;
    endcase

    case (r_i0_exec_p.alu_s2_sel)
        ALU_S2_RS2: i0_alu_s2 = i0_final_rs2_val;
        ALU_S2_IMM: i0_alu_s2 = r_i0_exec_p.imm;
        ALU_S2_4:   i0_alu_s2 = 32'd4;
    endcase

    case (r_i1_exec_p.alu_s1_sel)
        ALU_S1_RS1: i1_alu_s1 = i1_final_rs1_val;
        ALU_S1_PC:  i1_alu_s1 = i1_pc_val;
        ALU_S1_0:   i1_alu_s1 = 32'b0;
    endcase

    case (r_i1_exec_p.alu_s2_sel)
        ALU_S2_RS2: i1_alu_s2 = i1_final_rs2_val;
        ALU_S2_IMM: i1_alu_s2 = r_i1_exec_p.imm;
        ALU_S2_4:   i1_alu_s2 = 32'd4;
    endcase
end

alu i0_alu (
    .s1(i0_alu_s1),
    .s2(i0_alu_s2),
    .opc(r_i0_exec_p.alu_opc),
    .res(i0_alu_res),
    .eq(i0_alu_eq),
    .lt(i0_alu_lt)
);

alu i1_alu (
    .s1(i1_alu_s1),
    .s2(i1_alu_s2),
    .opc(r_i1_exec_p.alu_opc),
    .res(i1_alu_res),
    .eq(i1_alu_eq),
    .lt(i1_alu_lt)
);

// address generation
logic [31:0] i0_agu_s1,  i1_agu_s1;
logic [31:0] i0_agu_res, i1_agu_res;

always_comb begin : set_agu_operands
    case (r_i0_exec_p.agu_s1_sel)
        AGU_S1_RS1: i0_agu_s1 = i0_final_rs1_val;
        AGU_S1_PC:  i0_agu_s1 = i0_pc_val;
    endcase

    case (r_i1_exec_p.agu_s1_sel)
        AGU_S1_RS1: i1_agu_s1 = i1_final_rs1_val;
        AGU_S1_PC:  i1_agu_s1 = i1_pc_val;
    endcase
end

assign i0_agu_res = i0_agu_s1 + r_i0_exec_p.imm;
assign i1_agu_res = i1_agu_s1 + r_i1_exec_p.imm;

logic        bru_take_jmp;
logic        bru_jmp_src_i0;
logic [31:0] bru_jmp_addr;

bru bru0 (
    .i0_valid(r_i0_valid && r_i0_bru_en),
    .i0_opc(r_i0_exec_p.extra_opc),
    .i0_eq(i0_alu_eq),
    .i0_lt(i0_alu_lt),
    .i0_jmp_addr(i0_agu_res),
    .i1_valid(r_i1_valid && r_i1_bru_en),
    .i1_opc(r_i1_exec_p.extra_opc),
    .i1_eq(i1_alu_eq),
    .i1_lt(i1_alu_lt),
    .i1_jmp_addr(i1_agu_res),
    .take_jmp(bru_take_jmp),
    .jmp_src_i0(bru_jmp_src_i0),
    .jmp_addr(bru_jmp_addr)
);

assign ifu_take_jmp = bru_take_jmp && exu_ready;
assign ifu_jmp_addr = bru_jmp_addr;

// when valid jump is in i0, the i1 instruction will be invalidated
logic next_i1_valid;
assign next_i1_valid = r_i1_valid && !(bru_take_jmp && bru_jmp_src_i0);

logic i0_uses_lsu, i1_uses_lsu;
assign i0_uses_lsu = r_i0_valid    && r_i0_lsu_en;
assign i1_uses_lsu = next_i1_valid && r_i1_lsu_en;

always_comb begin : driving_lsu_ports
    lsu_p.valid = (i0_uses_lsu || i1_uses_lsu) && exu_ready;

    if (i0_uses_lsu) begin
        lsu_p.opc = r_i0_exec_p.extra_opc;
        lsu_p.addr = i0_agu_res;
        lsu_p.wdata = i0_final_rs2_val;
    end else begin
        lsu_p.opc = r_i1_exec_p.extra_opc;
        lsu_p.addr = i1_agu_res;
        lsu_p.wdata = i1_final_rs2_val;
    end
end

always_ff @(posedge clk) begin : check_lsu_mutex
    if (!rst)
        assert (!(i0_uses_lsu && i1_uses_lsu));
end

assign ex1_fwd_p = '{r_i0_valid && r_i0_rd_en, !r_i0_lsu_en, r_i0_exec_p.rd_addr,
                     r_i1_valid && r_i1_rd_en, !r_i1_lsu_en, r_i1_exec_p.rd_addr};

logic        r_ex2_i0_valid,   r_ex2_i1_valid;
exec_pipe_t  r_ex2_i0_pipe,    r_ex2_i1_pipe;
logic        r_ex2_i0_rd_en,   r_ex2_i1_rd_en;
logic [4:0]  r_ex2_i0_rd_addr, r_ex2_i1_rd_addr;
logic [31:0] r_ex2_i0_rd_val,  r_ex2_i1_rd_val;

always_ff @(posedge clk) begin : ex2_regs
    if (rst) begin
        r_ex2_i0_valid <= 1'b0;
        r_ex2_i1_valid <= 1'b0;
    end else if (exu_ready) begin
        if (r_i0_valid) begin
            r_ex2_i0_pipe <= r_i0_lsu_en ? PIPE_LSU : PIPE_EXU;
            r_ex2_i0_rd_en <= r_i0_rd_en;

            if (r_i0_rd_en) begin
                r_ex2_i0_rd_addr <= r_i0_exec_p.rd_addr;

                if (!r_i0_lsu_en)
                    r_ex2_i0_rd_val <= i0_alu_res;
            end
        end

        if (next_i1_valid) begin
            r_ex2_i1_pipe <= r_i1_lsu_en ? PIPE_LSU : PIPE_EXU;
            r_ex2_i1_rd_en <= r_i1_rd_en;

            if (r_i1_rd_en) begin
                r_ex2_i1_rd_addr <= r_i1_exec_p.rd_addr;

                if (!r_i1_lsu_en)
                    r_ex2_i1_rd_val <= i1_alu_res;
            end
        end

        r_ex2_i0_valid <= r_i0_valid;
        r_ex2_i1_valid <= next_i1_valid;
    end
end

assign ex2_fwd_p = '{r_ex2_i0_valid && r_ex2_i0_rd_en, r_ex2_i0_pipe == PIPE_EXU, r_ex2_i0_rd_addr,
                     r_ex2_i1_valid && r_ex2_i1_rd_en, r_ex2_i1_pipe == PIPE_EXU, r_ex2_i1_rd_addr};

logic        r_ex3_i0_valid,   r_ex3_i1_valid;
exec_pipe_t  r_ex3_i0_pipe,    r_ex3_i1_pipe;
logic        r_ex3_i0_rd_en,   r_ex3_i1_rd_en;
logic [4:0]  r_ex3_i0_rd_addr, r_ex3_i1_rd_addr;
logic [31:0] r_ex3_i0_rd_val,  r_ex3_i1_rd_val;

always_ff @(posedge clk) begin : ex3_regs
    if (rst) begin
        r_ex3_i0_valid <= 1'b0;
        r_ex3_i1_valid <= 1'b0;
    end else if (exu_ready) begin
        if (r_ex2_i0_valid) begin
            r_ex3_i0_pipe <= r_ex2_i0_pipe;
            r_ex3_i0_rd_en <= r_ex2_i0_rd_en;

            if (r_ex2_i0_rd_en) begin
                r_ex3_i0_rd_addr <= r_ex2_i0_rd_addr;

                if (r_ex2_i0_pipe == PIPE_EXU)
                    r_ex3_i0_rd_val <= r_ex2_i0_rd_val;
            end
        end

        if (r_ex2_i1_valid) begin
            r_ex3_i1_pipe <= r_ex2_i1_pipe;
            r_ex3_i1_rd_en <= r_ex2_i1_rd_en;

            if (r_ex2_i1_rd_en) begin
                r_ex3_i1_rd_addr <= r_ex2_i1_rd_addr;

                if (r_ex2_i1_pipe == PIPE_EXU)
                    r_ex3_i1_rd_val <= r_ex2_i1_rd_val;
            end
        end

        r_ex3_i0_valid <= r_ex2_i0_valid;
        r_ex3_i1_valid <= r_ex2_i1_valid;
    end
end

assign ex3_fwd_p = '{r_ex3_i0_valid && r_ex3_i0_rd_en, 1'b1, r_ex3_i0_rd_addr,
                     r_ex3_i1_valid && r_ex3_i1_rd_en, 1'b1, r_ex3_i1_rd_addr};

logic        r_wb_i0_valid,   r_wb_i1_valid;
logic        r_wb_i0_lsu_en,  r_wb_i1_lsu_en; // LSU used for this instruction
logic        r_wb_i0_rd_en,   r_wb_i1_rd_en;
logic [4:0]  r_wb_i0_rd_addr, r_wb_i1_rd_addr;
logic [31:0] r_wb_i0_rd_val,  r_wb_i1_rd_val;

// TODO: consider different LSU integration to make it universal (e.g., for adding divider) and less stalling
always_ff @(posedge clk) begin : wb_regs
    if (rst) begin
        r_wb_i0_valid <= 1'b0;
        r_wb_i1_valid <= 1'b0;
    end else if (exu_ready) begin
        if (r_ex3_i0_valid) begin
            r_wb_i0_lsu_en <= r_ex3_i0_pipe == PIPE_LSU;
            r_wb_i0_rd_en <= r_ex3_i0_rd_en;

            if (r_ex3_i0_rd_en) begin
                r_wb_i0_rd_addr <= r_ex3_i0_rd_addr;

                case (r_ex3_i0_pipe)
                    PIPE_EXU:                     r_wb_i0_rd_val <= r_ex3_i0_rd_val;
                    PIPE_LSU: if (lsu_resp_valid) r_wb_i0_rd_val <= lsu_rdata;
                endcase
            end
        end

        if (r_ex3_i1_valid) begin
            r_wb_i1_lsu_en <= r_ex3_i1_pipe == PIPE_LSU;
            r_wb_i1_rd_en <= r_ex3_i1_rd_en;

            if (r_ex3_i1_rd_en) begin
                r_wb_i1_rd_addr <= r_ex3_i1_rd_addr;

                case (r_ex3_i1_pipe)
                    PIPE_EXU:                     r_wb_i1_rd_val <= r_ex3_i1_rd_val;
                    PIPE_LSU: if (lsu_resp_valid) r_wb_i1_rd_val <= lsu_rdata;
                endcase
            end
        end

        r_wb_i0_valid <= r_ex3_i0_valid;
        r_wb_i1_valid <= r_ex3_i1_valid;
    end else if (lsu_resp_wait && lsu_resp_valid) begin
        if (r_wb_i0_valid && r_wb_i0_lsu_en && r_wb_i0_rd_en)
            r_wb_i0_rd_val <= lsu_rdata; // receive the data additionally

        if (r_wb_i1_valid && r_wb_i1_lsu_en && r_wb_i1_rd_en)
            r_wb_i1_rd_val <= lsu_rdata;
    end
end

assign exu_res_p = '{r_wb_i0_valid && r_wb_i0_rd_en && exu_ready, r_wb_i0_rd_addr, r_wb_i0_rd_val,
                     r_wb_i1_valid && r_wb_i1_rd_en && exu_ready, r_wb_i1_rd_addr, r_wb_i1_rd_val};

assign exu_ready = !lsu_addr_wait && !lsu_resp_wait;

endmodule
