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
module ahb_mem ( // dual port AHB-Lite memory
    input logic clk,
    input logic rst,

    // instruction interface
    input logic [31:0]  imem_haddr,
// verilator lint_off UNUSED
    input logic [2:0]   imem_hburst,
    input logic         imem_hmastlock,
    input logic [3:0]   imem_hprot,
    input logic [2:0]   imem_hsize,
// verilator lint_on UNUSED
    input logic [1:0]   imem_htrans,
// verilator lint_off UNUSED
    input logic [63:0]  imem_hwdata,
    input logic         imem_hwrite,
// verilator lint_on UNUSED

    output logic [63:0] imem_hrdata,
    output logic        imem_hready,
    output logic        imem_hresp,

    // data interface
    input logic [31:0]  dmem_haddr,
// verilator lint_off UNUSED
    input logic [2:0]   dmem_hburst,
    input logic         dmem_hmastlock,
    input logic [3:0]   dmem_hprot,
// verilator lint_on UNUSED
    input logic [2:0]   dmem_hsize,
    input logic [1:0]   dmem_htrans,
    input logic [31:0]  dmem_hwdata,
    input logic         dmem_hwrite,

    output logic [31:0] dmem_hrdata,
    output logic        dmem_hready,
    output logic        dmem_hresp
);

// commom memory storage for both ports
logic [7:0] r_mem [logic [31:0]]; // associative array

// verilator lint_off UNUSED
logic [31:0] r_imem_haddr;
// verilator lint_on UNUSED
logic [1:0]  r_imem_htrans;

always_ff @(posedge clk) begin : imem_accept_req
    if (rst)
        r_imem_htrans <= 2'b00;
    else begin
        r_imem_haddr <=  imem_haddr;
        r_imem_htrans <= imem_htrans;
    end
end

// TODO: set only used lanes, others are unknown
always_comb begin : imem_read_data
    if (r_imem_htrans == 2'b10)
        imem_hrdata = {r_mem[{r_imem_haddr[31:3], 3'b111}],
                       r_mem[{r_imem_haddr[31:3], 3'b110}],
                       r_mem[{r_imem_haddr[31:3], 3'b101}],
                       r_mem[{r_imem_haddr[31:3], 3'b100}],
                       r_mem[{r_imem_haddr[31:3], 3'b011}],
                       r_mem[{r_imem_haddr[31:3], 3'b010}],
                       r_mem[{r_imem_haddr[31:3], 3'b001}],
                       r_mem[{r_imem_haddr[31:3], 3'b000}]};
    else
        imem_hrdata = 'x; // unknown hrdata when no memory read
end

// TODO: add latency emulation
assign imem_hready = 1'b1;
assign imem_hresp = 1'b0;

logic [31:0] r_dmem_haddr;
logic [2:0]  r_dmem_hsize;
logic [1:0]  r_dmem_htrans;
logic        r_dmem_hwrite;

always_ff @(posedge clk) begin : dmem_accept_req
    if (rst)
        r_dmem_htrans <= 2'b00;
    else begin
        r_dmem_haddr <=  dmem_haddr;
        r_dmem_hsize <=  dmem_hsize;
        r_dmem_htrans <= dmem_htrans;
        r_dmem_hwrite <= dmem_hwrite;
    end
end

logic [3:0] dmem_wstrb;

always_comb begin : dmem_setup_write_strobe
    case (r_dmem_hsize)
        3'b000:  dmem_wstrb = 4'b0001 << r_dmem_haddr[1:0];
        3'b001:  dmem_wstrb = 4'b0011 << {r_dmem_haddr[1], 1'b0};
        3'b010:  dmem_wstrb = 4'b1111;
        default: dmem_wstrb = 'x;
    endcase
end

always_ff @(posedge clk) begin : dmem_write_data
    if (!rst && r_dmem_htrans == 2'b10 && r_dmem_hwrite) begin
        if (dmem_wstrb[3]) r_mem[{r_dmem_haddr[31:2], 2'b11}] <= dmem_hwdata[31:24];
        if (dmem_wstrb[2]) r_mem[{r_dmem_haddr[31:2], 2'b10}] <= dmem_hwdata[23:16];
        if (dmem_wstrb[1]) r_mem[{r_dmem_haddr[31:2], 2'b01}] <= dmem_hwdata[15:8];
        if (dmem_wstrb[0]) r_mem[{r_dmem_haddr[31:2], 2'b00}] <= dmem_hwdata[7:0];
    end
end

// combinatory read to reflect same address write in previous cycle
always_comb begin : dmem_read_data
    if (r_dmem_htrans == 2'b10 && !r_dmem_hwrite)
        dmem_hrdata = {r_mem[{r_dmem_haddr[31:2], 2'b11}],
                       r_mem[{r_dmem_haddr[31:2], 2'b10}],
                       r_mem[{r_dmem_haddr[31:2], 2'b01}],
                       r_mem[{r_dmem_haddr[31:2], 2'b00}]};
    else
        dmem_hrdata = 'x;
end

assign dmem_hready = 1'b1;
assign dmem_hresp = 1'b0;

endmodule
