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

module dec // decoding unit
    import srv_defs::*;
(
    input logic  clk,
    input logic  rst,
    input logic  stall_dec,
    input logic  flush_dec,
    output logic dec_ready,

    input inst_pkt_t ifu_inst_p,

    // operand forwarding
    input fwd_pkt_t ex1_fwd_p,
    input fwd_pkt_t ex2_fwd_p,
    input fwd_pkt_t ex3_fwd_p,
    // result propagation
    input res_pkt_t exu_res_p, // from WB stage

    // decoded signals
    output logic        dec_i0_valid, // valid instruction to execute
    output enable_pkt_t dec_i0_en_p,
    output exec_pkt_t   dec_i0_exec_p,
    output logic        dec_i1_valid,
    output enable_pkt_t dec_i1_en_p,
    output exec_pkt_t   dec_i1_exec_p,
    output logic [31:0] dec_pc_val,

    // individual operand forwarding sources
    output fwd_src_t dec_i0_rs1_fwd_src,
    output fwd_src_t dec_i0_rs2_fwd_src,
    output fwd_src_t dec_i1_rs1_fwd_src,
    output fwd_src_t dec_i1_rs2_fwd_src
);

inst_pkt_t r_inst_p;

// TODO: consider instruction predecode to reduce switching activity (rs1/2, imm, ...)
always_ff @(posedge clk) begin : catch_inst
    if (rst || flush_dec) begin
        r_inst_p.i0_valid <= 1'b0;
        r_inst_p.i1_valid <= 1'b0;
    end else if (!stall_dec) begin
        if (i0_ready) begin
            if (i1_ready) begin
                if (ifu_inst_p.i0_valid)
                    r_inst_p.i0_inst <= ifu_inst_p.i0_inst;

                if (ifu_inst_p.i1_valid)
                    r_inst_p.i1_inst <= ifu_inst_p.i1_inst;

                if (ifu_inst_p.i0_valid || ifu_inst_p.i1_valid)
                    r_inst_p.addr <= ifu_inst_p.addr;

                r_inst_p.i0_valid <= ifu_inst_p.i0_valid;
                r_inst_p.i1_valid <= ifu_inst_p.i1_valid;
            end else
                r_inst_p.i0_valid <= 1'b0;
        end
    end
end

enable_pkt_t i0_en_p,       i1_en_p;
logic [4:0]  i0_rs1_addr,   i1_rs1_addr;
logic [4:0]  i0_rs2_addr,   i1_rs2_addr;
logic [4:0]  i0_rd_addr,    i1_rd_addr;
logic [31:0] i0_imm,        i1_imm;
alu_s1_mux_t i0_alu_s1_sel, i1_alu_s1_sel;
alu_s2_mux_t i0_alu_s2_sel, i1_alu_s2_sel;
alu_opcode_t i0_alu_opc,    i1_alu_opc;
agu_s1_mux_t i0_agu_s1_sel, i1_agu_s1_sel;
logic [3:0]  i0_extra_opc,  i1_extra_opc;

inst_dec i0_inst_dec (
    .inst(r_inst_p.i0_inst),
    .en_p(i0_en_p),
    .rs1_addr(i0_rs1_addr),
    .rs2_addr(i0_rs2_addr),
    .rd_addr(i0_rd_addr),
    .imm(i0_imm),
    .alu_s1_sel(i0_alu_s1_sel),
    .alu_s2_sel(i0_alu_s2_sel),
    .alu_opc(i0_alu_opc),
    .agu_s1_sel(i0_agu_s1_sel),
    .extra_opc(i0_extra_opc)
);

inst_dec i1_inst_dec (
    .inst(r_inst_p.i1_inst),
    .en_p(i1_en_p),
    .rs1_addr(i1_rs1_addr),
    .rs2_addr(i1_rs2_addr),
    .rd_addr(i1_rd_addr),
    .imm(i1_imm),
    .alu_s1_sel(i1_alu_s1_sel),
    .alu_s2_sel(i1_alu_s2_sel),
    .alu_opc(i1_alu_opc),
    .agu_s1_sel(i1_agu_s1_sel),
    .extra_opc(i1_extra_opc)
);

// unforwarded read register data
logic [31:0] i0_rs1_val, i0_rs2_val, i1_rs1_val, i1_rs2_val;

gpr gpr0 (
    .clk,
    .raddr0(i0_rs1_addr),
    .raddr1(i0_rs2_addr),
    .raddr2(i1_rs1_addr),
    .raddr3(i1_rs2_addr),
    .rdata0(i0_rs1_val),
    .rdata1(i0_rs2_val),
    .rdata2(i1_rs1_val),
    .rdata3(i1_rs2_val),
    .we0(exu_res_p.i0_valid),
    .we1(exu_res_p.i1_valid),
    .waddr0(exu_res_p.i0_addr),
    .waddr1(exu_res_p.i1_addr),
    .wdata0(exu_res_p.i0_val),
    .wdata1(exu_res_p.i1_val)
);

logic i0_rs1_ready, i0_rs2_ready, i1_rs1_ready, i1_rs2_ready;

fwd_init i0_rs1_fwd_init (
    .*,
    .rs_addr(i0_rs1_addr),
    .fwd_ready(i0_rs1_ready),
    .fwd_src(dec_i0_rs1_fwd_src)
);

fwd_init i0_rs2_fwd_init (
    .*,
    .rs_addr(i0_rs2_addr),
    .fwd_ready(i0_rs2_ready),
    .fwd_src(dec_i0_rs2_fwd_src)
);

fwd_init i1_rs1_fwd_init (
    .*,
    .rs_addr(i1_rs1_addr),
    .fwd_ready(i1_rs1_ready),
    .fwd_src(dec_i1_rs1_fwd_src)
);

fwd_init i1_rs2_fwd_init (
    .*,
    .rs_addr(i1_rs2_addr),
    .fwd_ready(i1_rs2_ready),
    .fwd_src(dec_i1_rs2_fwd_src)
);

// instruction dispatch
logic i0_waits_for_fwd, i1_waits_for_fwd;
logic i0_modifies_rd;
logic i1_uses_i0_rd;
logic run_i0_first; // serialize instructions within the pair
logic i0_ready, i1_ready;

assign i0_waits_for_fwd = (i0_en_p.rs1 && !i0_rs1_ready) || (i0_en_p.rs2 && !i0_rs2_ready);
assign i1_waits_for_fwd = (i1_en_p.rs1 && !i1_rs1_ready) || (i1_en_p.rs2 && !i1_rs2_ready);

assign i0_modifies_rd = i0_en_p.rd && i0_rd_addr != 5'b0;
assign i1_uses_i0_rd = (i1_en_p.rs1 && i1_rs1_addr == i0_rd_addr) || (i1_en_p.rs2 && i1_rs2_addr == i0_rd_addr);
// uncomment last part for instruction serialization (single-issue execution)
assign run_i0_first = (i0_modifies_rd && i1_uses_i0_rd) || (i0_en_p.lsu && i1_en_p.lsu) /* || 1'b1 */;

// TODO: consider memory instructions fusion based on simple deterministic issue slots pattern
assign i0_ready = !(r_inst_p.i0_valid && i0_waits_for_fwd);
assign i1_ready = !(r_inst_p.i1_valid && (i1_waits_for_fwd || (r_inst_p.i0_valid && run_i0_first)));
assign dec_ready = i0_ready && i1_ready;

// prepare decoded output signals
assign dec_i0_valid = r_inst_p.i0_valid && i0_ready;
assign dec_i0_en_p = i0_en_p;
assign dec_i0_exec_p = '{i0_rs1_val, i0_rs2_val, i0_imm, i0_alu_s1_sel, i0_alu_s2_sel, i0_alu_opc, i0_agu_s1_sel, i0_extra_opc, i0_rd_addr};
assign dec_i1_valid = r_inst_p.i1_valid && i1_ready && i0_ready; // i1 must not execute first
assign dec_i1_en_p = i1_en_p;
assign dec_i1_exec_p = '{i1_rs1_val, i1_rs2_val, i1_imm, i1_alu_s1_sel, i1_alu_s2_sel, i1_alu_opc, i1_agu_s1_sel, i1_extra_opc, i1_rd_addr};
assign dec_pc_val = r_inst_p.addr;

endmodule
