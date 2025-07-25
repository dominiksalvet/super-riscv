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

module gpr // general purpose registers
(
    input logic clk,

    // read ports
    input logic [4:0] raddr0,
    input logic [4:0] raddr1,
    input logic [4:0] raddr2,
    input logic [4:0] raddr3,

    output logic [31:0] rdata0,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2,
    output logic [31:0] rdata3,

    // write ports
    input logic we0,
    input logic we1,

    input logic [4:0] waddr0,
    input logic [4:0] waddr1,

    input logic [31:0] wdata0,
    input logic [31:0] wdata1
);

logic [31:0] r_regs [31:1]; // memory representation

// register read with write forwarding
assign rdata0 = raddr0 == 5'b0 ? 32'b0 :
                (we1 && waddr1 == raddr0) ? wdata1 :
                (we0 && waddr0 == raddr0) ? wdata0 : r_regs[raddr0];

assign rdata1 = raddr1 == 5'b0 ? 32'b0 :
                (we1 && waddr1 == raddr1) ? wdata1 :
                (we0 && waddr0 == raddr1) ? wdata0 : r_regs[raddr1];

assign rdata2 = raddr2 == 5'b0 ? 32'b0 :
                (we1 && waddr1 == raddr2) ? wdata1 :
                (we0 && waddr0 == raddr2) ? wdata0 : r_regs[raddr2];

assign rdata3 = raddr3 == 5'b0 ? 32'b0 :
                (we1 && waddr1 == raddr3) ? wdata1 :
                (we0 && waddr0 == raddr3) ? wdata0 : r_regs[raddr3];

// TODO: make sure this is optimal (for simultaneous writes from both issues)
always_ff @(posedge clk) begin : reg_write
    if (waddr0 != 5'b0 && we0)
        r_regs[waddr0] <= wdata0;
    if (waddr1 != 5'b0 && we1)
        r_regs[waddr1] <= wdata1;
end

endmodule
