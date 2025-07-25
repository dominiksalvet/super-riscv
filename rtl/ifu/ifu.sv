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

// TODO: add full support for AHB-Lite
module ifu // instruction fetch unit
    import srv_defs::*;
(
    input logic        clk,
    input logic        rst,
    input logic [31:0] rst_vec,
    input logic        stall_ifu,

    input logic        ifu_take_jmp,
    input logic [31:0] ifu_jmp_addr,

    output inst_pkt_t ifu_inst_p,

    // AHB-Lite signals
    output logic [31:0] imem_haddr,
    output logic [2:0]  imem_hburst,
    output logic        imem_hmastlock,
    output logic [3:0]  imem_hprot,
    output logic [2:0]  imem_hsize,
    output logic [1:0]  imem_htrans,
    output logic [63:0] imem_hwdata,
    output logic        imem_hwrite,

    input logic [63:0]  imem_hrdata,
// verilator lint_off UNUSED
    input logic         imem_hready,
    input logic         imem_hresp
// verilator lint_on UNUSED
);

logic        r_no_fetch;
logic [31:0] r_pc;

always_ff @(posedge clk) begin : next_pc
    if (rst)
        r_pc <= rst_vec;
    else if (ifu_take_jmp)
        r_pc <= ifu_jmp_addr;
    else if (fetch_en)
        r_pc <= {r_pc[31:3], 1'b0, r_pc[1:0]} + 32'd8;

    // cannot fetch immediately when reset is down (prevent I2O path)
    r_no_fetch <= rst;
end

assign imem_haddr =     r_pc;
assign imem_hburst =    3'b000; // single burst
assign imem_hmastlock = 1'b0; // no locked transfers
assign imem_hprot =     4'b0010; // non-cacheable, non-bufferable, privileged, opcode
assign imem_hsize =     {2'b01, ~r_pc[2]};
assign imem_htrans =    {fetch_en, 1'b0}; // only nonsequential transfers
assign imem_hwdata =    'x;
assign imem_hwrite =    1'b0; // only read transfers

logic        r_if2_valid; // transfer is in progress
logic [31:0] r_if2_pc;

always_ff @(posedge clk) begin : fetch_inst
    if (rst || ifu_take_jmp)
        r_if2_valid <= 1'b0;
    else begin
        if (fetch_en)
            r_if2_pc <= r_pc;

        r_if2_valid <= fetch_en;
    end
end

inst_pkt_t fetch_inst_p;

assign fetch_inst_p.i0_valid = r_if2_valid && !r_if2_pc[2];
assign fetch_inst_p.i0_inst = imem_hrdata[31:0];
assign fetch_inst_p.i1_valid = r_if2_valid;
assign fetch_inst_p.i1_inst = imem_hrdata[63:32];
assign fetch_inst_p.addr = {r_if2_pc[31:3], 1'b0, r_if2_pc[1:0]};

logic ifb_full, ifb_afull;

ifb ifb0 (
    .clk, .rst,
    .flush(ifu_take_jmp),
    .in_inst_p(fetch_inst_p), // contains valid signals for control
    .use_out(!stall_ifu),
    .out_inst_p(ifu_inst_p),
    .full(ifb_full),
    .afull(ifb_afull)
);

logic fetch_en;
assign fetch_en = !(r_no_fetch || ifb_full || (ifb_afull && r_if2_valid));

endmodule
