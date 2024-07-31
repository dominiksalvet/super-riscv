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

// TODO: use asynchronous low active reset
module super_riscv // Super RISC-V top module
    import srv_defs::*;
(
    input logic        clk,
    input logic        rst,
    input logic [31:0] rst_vec,

    // instruction memory AHB-Lite signals
    output logic [31:0] imem_haddr,
    output logic [2:0]  imem_hburst,
    output logic        imem_hmastlock,
    output logic [3:0]  imem_hprot,
    output logic [2:0]  imem_hsize,
    output logic [1:0]  imem_htrans,
    output logic [63:0] imem_hwdata,
    output logic        imem_hwrite,

    input logic [63:0]  imem_hrdata,
    input logic         imem_hready,
    input logic         imem_hresp,

    // data memory AHB-Lite signals
    output logic [31:0] dmem_haddr,
    output logic [2:0]  dmem_hburst,
    output logic        dmem_hmastlock,
    output logic [3:0]  dmem_hprot,
    output logic [2:0]  dmem_hsize,
    output logic [1:0]  dmem_htrans,
    output logic [31:0] dmem_hwdata,
    output logic        dmem_hwrite,

    input logic [31:0]  dmem_hrdata,
    input logic         dmem_hready,
    input logic         dmem_hresp
);

logic        ifu_take_jmp;
logic [31:0] ifu_jmp_addr;
inst_pkt_t   ifu_inst_p;

ifu ifu0 (.*);

logic        dec_i0_valid,       dec_i1_valid;
enable_pkt_t dec_i0_en_p,        dec_i1_en_p;
exec_pkt_t   dec_i0_exec_p,      dec_i1_exec_p;
fwd_src_t    dec_i0_rs1_fwd_src, dec_i1_rs1_fwd_src;
fwd_src_t    dec_i0_rs2_fwd_src, dec_i1_rs2_fwd_src;
logic [31:0] dec_pc_val;

dec dec0 (.*);

fwd_pkt_t ex1_fwd_p, ex2_fwd_p, ex3_fwd_p;
res_pkt_t exu_res_p;

exu exu0 (.*);

lsu_pkt_t    lsu_p;
logic        lsu_addr_wait, lsu_resp_wait;
logic        lsu_resp_valid;
logic [31:0] lsu_rdata;

lsu lsu0 (.*);

// TODO: replace stall with chained ready signals (eliminate unnecessary stalls, e.g. when empty dec)
// pipeline control
logic stall_ifu;
logic stall_dec;
logic flush_dec;
logic dec_ready;
logic exu_ready;

// control logic across the units
assign stall_ifu = !dec_ready || !exu_ready;
assign stall_dec = !exu_ready;
assign flush_dec = ifu_take_jmp;

endmodule
