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

module ifb // instruction fetch buffer
    import srv_defs::*;
(
    input logic clk,
    input logic rst,
    input logic flush,

    input inst_pkt_t  in_inst_p,
    input logic       use_out, // output instruction packet will be consumed
    output inst_pkt_t out_inst_p,

    output logic full,
    output logic afull // almost full
);

inst_pkt_t r_inst_p [1:0]; // two IFB items
logic r_wptr, r_rptr;
logic r_full;

logic empty;
logic push, pop;

assign empty = !r_full && r_wptr == r_rptr;
assign push = (in_inst_p.i0_valid || in_inst_p.i1_valid) && (!empty || !use_out);
assign pop = use_out && !empty;

always_ff @(posedge clk) begin : fifo
    if (rst || flush) begin
        r_wptr <= 1'b0;
        r_rptr <= 1'b0;
        r_full <= 1'b0;
    end else begin
        if (push) begin
            r_inst_p[r_wptr] <= in_inst_p;
            r_wptr <= ~r_wptr;
        end

        if (pop)
            r_rptr <= ~r_rptr;

        if (afull && push && !pop)
            r_full <= 1'b1;
        else if (!push && pop)
            r_full <= 1'b0;
    end
end

always_ff @(posedge clk) begin : check_push_to_full
    if (!rst)
        assert (!(push && r_full));
end

assign out_inst_p = empty && use_out ? in_inst_p : r_inst_p[r_rptr];
assign full = r_full;
assign afull = r_wptr != r_rptr;

endmodule
