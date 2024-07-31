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

module fwd_init // forwarding initiator
    import srv_defs::*;
(
    input logic [4:0] rs_addr,

    input fwd_pkt_t ex1_fwd_p,
    input fwd_pkt_t ex2_fwd_p,
    input fwd_pkt_t ex3_fwd_p,

    output logic     fwd_ready,
    output fwd_src_t fwd_src // next cycle forwarding source
);

always_comb begin
    // default values
    fwd_ready = 1'b1;
    fwd_src = FWD_NONE;

    if (rs_addr != 5'b0) begin
        if (ex1_fwd_p.i1_valid && ex1_fwd_p.i1_addr == rs_addr) begin // first EX1 i1
            fwd_ready = ex1_fwd_p.i1_ready;
            fwd_src = FWD_EX2_I1;
        end else if (ex1_fwd_p.i0_valid && ex1_fwd_p.i0_addr == rs_addr) begin // then EX1 i0
            fwd_ready = ex1_fwd_p.i0_ready;
            fwd_src = FWD_EX2_I0;
        end else if (ex2_fwd_p.i1_valid && ex2_fwd_p.i1_addr == rs_addr) begin // then EX2 i1
            fwd_ready = ex2_fwd_p.i1_ready;
            fwd_src = FWD_EX3_I1;
        end else if (ex2_fwd_p.i0_valid && ex2_fwd_p.i0_addr == rs_addr) begin // and so on
            fwd_ready = ex2_fwd_p.i0_ready;
            fwd_src = FWD_EX3_I0;
        end else if (ex3_fwd_p.i1_valid && ex3_fwd_p.i1_addr == rs_addr) begin
            fwd_ready = ex3_fwd_p.i1_ready;
            fwd_src = FWD_WB_I1;
        end else if (ex3_fwd_p.i0_valid && ex3_fwd_p.i0_addr == rs_addr) begin
            fwd_ready = ex3_fwd_p.i0_ready;
            fwd_src = FWD_WB_I0;
        end
    end
end

endmodule
