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
module lsu // load-store unit
    import srv_defs::*;
    import riscv_defs::*;
(
    input logic  clk,
    input logic  rst,

    input lsu_pkt_t lsu_p,

    output logic        lsu_addr_wait, // wait for memory addressing
    output logic        lsu_resp_wait, // wait for memory response
    output logic        lsu_resp_valid,
    output logic [31:0] lsu_rdata,

    // AHB-Lite signals
    output logic [31:0] dmem_haddr,
    output logic [2:0]  dmem_hburst,
    output logic        dmem_hmastlock,
    output logic [3:0]  dmem_hprot,
    output logic [2:0]  dmem_hsize,
    output logic [1:0]  dmem_htrans,
    output logic [31:0] dmem_hwdata,
    output logic        dmem_hwrite,

    input logic [31:0]  dmem_hrdata,
// verilator lint_off UNUSED
    input logic         dmem_hready,
    input logic         dmem_hresp
// verilator lint_on UNUSED
);

lsu_pkt_t r_ex2_lsu_p;

always_ff @(posedge clk) begin : address_phase
    if (rst)
        r_ex2_lsu_p.valid <= 1'b0;
    else begin
        if (lsu_p.valid) begin
            r_ex2_lsu_p.opc <= lsu_p.opc;
            r_ex2_lsu_p.addr <= lsu_p.addr;

            if (lsu_p.opc[3] == OPC_STORE[5]) begin
                r_ex2_lsu_p.wdata[7:0] <= lsu_p.wdata[7:0]; // byte and wider

                if (lsu_p.opc[0] || lsu_p.opc[1]) // halfword and wider
                    r_ex2_lsu_p.wdata[15:8] <= lsu_p.wdata[15:8];

                if (lsu_p.opc[1]) // word
                    r_ex2_lsu_p.wdata[31:16] <= lsu_p.wdata[31:16];
            end
        end

        r_ex2_lsu_p.valid <= lsu_p.valid;
    end
end

assign dmem_haddr =     r_ex2_lsu_p.addr;
assign dmem_hburst =    3'b000; // single burst
assign dmem_hmastlock = 1'b0; // no locked transfers
assign dmem_hprot =     4'b0011; // non-cacheable, non-bufferable, privileged, data
assign dmem_hsize =     {1'b0, r_ex2_lsu_p.opc[1:0]};
assign dmem_htrans =    {r_ex2_lsu_p.valid, 1'b0}; // only nonsequential transfers
assign dmem_hwrite =    r_ex2_lsu_p.opc[3];

logic        r_ex3_valid;
load_fn3_t   r_ex3_load_opc;
logic [1:0]  r_ex3_low_addr;
logic [31:0] r_ex3_wdata;

always_ff @(posedge clk) begin : data_phase
    if (rst)
        r_ex3_valid <= 1'b0;
    else begin
        if (r_ex2_lsu_p.valid) begin
            if (r_ex2_lsu_p.opc[3] == OPC_LOAD[5]) begin
                r_ex3_load_opc <= load_fn3_t'(r_ex2_lsu_p.opc[2:0]);
                r_ex3_low_addr <= r_ex2_lsu_p.addr[1:0];
            end else begin
                case (r_ex2_lsu_p.opc[1:0])
                    FN3_SB[1:0]:
                        case (r_ex2_lsu_p.addr[1:0])
                            2'b00: r_ex3_wdata[7:0] <= r_ex2_lsu_p.wdata[7:0];
                            2'b01: r_ex3_wdata[15:8] <= r_ex2_lsu_p.wdata[7:0];
                            2'b10: r_ex3_wdata[23:16] <= r_ex2_lsu_p.wdata[7:0];
                            2'b11: r_ex3_wdata[31:24] <= r_ex2_lsu_p.wdata[7:0];
                        endcase

                    FN3_SH[1:0]:
                        if (r_ex2_lsu_p.addr[1])
                            r_ex3_wdata[31:16] <= r_ex2_lsu_p.wdata[15:0];
                        else
                            r_ex3_wdata[15:0] <= r_ex2_lsu_p.wdata[15:0];

                    FN3_SW[1:0]: r_ex3_wdata <= r_ex2_lsu_p.wdata;
                    default;
                endcase
            end
        end

        r_ex3_valid <= r_ex2_lsu_p.valid;
    end
end

assign dmem_hwdata = r_ex3_wdata;

assign lsu_addr_wait = 1'b0;
assign lsu_resp_wait = 1'b0;
assign lsu_resp_valid = r_ex3_valid;

// TODO: check the path length of hrdata to a register
always_comb begin : prepare_read_data
    logic [7:0]  ex3_load_byte;
    logic [15:0] ex3_load_halfword;

    case (r_ex3_low_addr)
        2'b00: ex3_load_byte = dmem_hrdata[7:0];
        2'b01: ex3_load_byte = dmem_hrdata[15:8];
        2'b10: ex3_load_byte = dmem_hrdata[23:16];
        2'b11: ex3_load_byte = dmem_hrdata[31:24];
    endcase

    if (r_ex3_low_addr[1])
        ex3_load_halfword = dmem_hrdata[31:16];
    else
        ex3_load_halfword = dmem_hrdata[15:0];

    case (r_ex3_load_opc)
        FN3_LB:  lsu_rdata = 32'(  signed'(ex3_load_byte));
        FN3_LBU: lsu_rdata = 32'(unsigned'(ex3_load_byte));
        FN3_LH:  lsu_rdata = 32'(  signed'(ex3_load_halfword));
        FN3_LHU: lsu_rdata = 32'(unsigned'(ex3_load_halfword));
        FN3_LW:  lsu_rdata = dmem_hrdata;
        default: lsu_rdata = 'x;
    endcase
end

endmodule
