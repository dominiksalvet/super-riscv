/*
    Super RISC-V - superscalar dual-issue RISC-V processor
    Copyright (C) 2024-2026 Dominik Salvet

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

// testbench, top module for testing
module tb
    import srv_types_pkg::*;
    import riscv_types_pkg::*;
(
    input logic clk // clock is driven by verilator
);

logic        rst;
logic [31:0] rst_vec;

// Super RISC-V core instance
super_riscv core (
    .dmem_hrdata(dmem_hrdata_to_core),
    .*
);

logic [31:0] imem_haddr;
logic [2:0]  imem_hburst;
logic        imem_hmastlock;
logic [3:0]  imem_hprot;
logic [2:0]  imem_hsize;
logic [1:0]  imem_htrans;
logic [63:0] imem_hwdata;
logic        imem_hwrite;
logic [63:0] imem_hrdata;
logic        imem_hready;
logic        imem_hresp;

logic [31:0] dmem_haddr;
logic [2:0]  dmem_hburst;
logic        dmem_hmastlock;
logic [3:0]  dmem_hprot;
logic [2:0]  dmem_hsize;
logic [1:0]  dmem_htrans;
logic [31:0] dmem_hwdata;
logic        dmem_hwrite;
logic [31:0] dmem_hrdata_to_core;
logic [31:0] dmem_hrdata_from_mem;
logic        dmem_hready;
logic        dmem_hresp;

// dual-port memory instance
ahb_mem mem (
    .dmem_hrdata(dmem_hrdata_from_mem),
    .*
);

// basic AHB-Lite protocol checker
logic past_rst;

always_ff @(posedge clk) begin : check_ahb
    if (past_rst) begin
        imem_rst_htrans : assert (imem_htrans == 2'b00);
        dmem_rst_htrans : assert (dmem_htrans == 2'b00);
    end

    if (!rst) begin
        if (imem_htrans == 2'b10) begin
            imem_valid_hsize : assert (imem_hsize inside {3'b010, 3'b011});

            imem_haddr_align : case (imem_hsize)
                3'b010: assert (imem_haddr[1:0] == 2'b00);
                3'b011: assert (imem_haddr[2:0] == 3'b000);
                default;
            endcase
        end

        if (dmem_htrans == 2'b10) begin
            dmem_valid_hsize : assert (dmem_hsize inside {3'b000, 3'b001, 3'b010});
            
            dmem_haddr_align : case (dmem_hsize)
                3'b001: assert (dmem_haddr[0] == 1'b0);
                3'b010: assert (dmem_haddr[1:0] == 2'b00);
                default;
            endcase
        end
    end   
end

// simulation constants
parameter DEFAULT_MAX_CYCLES = 250_000;
parameter RESET_CYCLES = 4; // must be >0

parameter DEFAULT_RST_VEC = 32'h2000_0000;
parameter MAILBOX_BASE = 32'hf000_0000;

// individual mailbox actions (simple semihosting)
parameter MB_HALT_ADDR = MAILBOX_BASE;     // end processor simulation
parameter MB_PUTC_ADDR = MAILBOX_BASE + 4; // print a single character
parameter MB_GETC_ADDR = MAILBOX_BASE + 8; // read a single character

// other constanst
parameter STDIN_FD = 32'h80000000; // might not work on some simulators (need manual $fopen)

// simulation control variables
longint cycles;
longint max_cycles;
string mem_image_path;

// basic peformance monitoring
longint inst_ret; // number of retired instructions
longint i0_next_inst_ret;
longint i1_next_inst_ret;

initial begin : sim_init
    if (!$value$plusargs("max+cycles=%d", max_cycles))
        max_cycles = DEFAULT_MAX_CYCLES;

    if (!$value$plusargs("test+path=%s", mem_image_path))
        $fatal(1, "No test path specified");

    $readmemh(mem_image_path, mem.r_mem);

    cycles = 0;
    inst_ret = 0;

    rst = 1'b1;
    past_rst = 1'b0;
    rst_vec = DEFAULT_RST_VEC;
end

assign i0_next_inst_ret = inst_ret + longint'(core.exu0.r_wb_i0_valid);
assign i1_next_inst_ret = i0_next_inst_ret + longint'(core.exu0.r_wb_i1_valid);

always_ff @(posedge clk) begin : sim_ctl
    // active for RESET_CYCLES rising edges of clock
    if (cycles == RESET_CYCLES - 1)
        rst <= 1'b0;

    // max cycles timeout (fail), if not halting the same cycle
    if (max_cycles != 0 && cycles >= max_cycles && !mb_halt_event)
        $fatal(1, "Maximum cycles limit (%0d) reached", max_cycles);

`ifdef EXEC_TRACE_SUPPORT
    // CPU execution trace
    if (core.exu0.r_wb_i0_valid)
        $display(get_trace_string(0, i0_next_inst_ret, cycles, core.exu0.wb_i0_final_trace_p));

    if (core.exu0.r_wb_i1_valid)
        $display(get_trace_string(1, i1_next_inst_ret, cycles, core.exu0.wb_i1_final_trace_p));
`endif

    cycles <= cycles + 1;
    past_rst <= rst;

    if (!rst && core.exu0.exu_ready)
        inst_ret <= i1_next_inst_ret;
end

// testbench mailbox control
logic mem_read;
logic mem_write;
logic mb_halt_event;
logic mb_putc_event;
logic mb_getc_event;

assign mem_read = !rst && mem.r_dmem_htrans == 2'b10 && !mem.r_dmem_hwrite;
assign mem_write = !rst && mem.r_dmem_htrans == 2'b10 && mem.r_dmem_hwrite;
assign mb_halt_event = mem_write && mem.r_dmem_haddr == MB_HALT_ADDR;
assign mb_putc_event = mem_write && mem.r_dmem_haddr == MB_PUTC_ADDR;
assign mb_getc_event = mem_read && mem.r_dmem_haddr == MB_GETC_ADDR;

// the core uses mailbox addresses to send signals to testbench
always_ff @(posedge clk) begin : mailbox_ctl_writes
    if (mb_halt_event) begin
        // check return value
        if (mem.dmem_hwdata == 32'b0)
            $finish; // success
        else
            $fatal(1, "Test failed with return value %0d", mem.dmem_hwdata);
    end

    if (mb_putc_event) begin
        $write("%c", mem.dmem_hwdata[7:0]);
    end
end

always_comb begin : mailbox_ctl_reads
    if (mb_getc_event) begin
        dmem_hrdata_to_core = $fgetc(STDIN_FD);
    end else begin
        dmem_hrdata_to_core = dmem_hrdata_from_mem;
    end
end

final begin : print_perf_stats
    longint final_inst_ret;

    if (cycles > 0) begin
        $display("Simulated cycles: %0d", cycles - 1);

        // also include packet that caused halt (not retired yet)
        final_inst_ret = i1_next_inst_ret;
        // if halt was performed from i0, i1 should not be considered executed
        if (core.exu0.r_wb_i0_valid && core.exu0.r_wb_i1_valid && core.exu0.r_wb_i0_lsu_en)
            final_inst_ret--;

        $display("Executed instructions: %0d", final_inst_ret);
    end
end

// TODO: add header + footer?
// TODO: add disassembly
// TODO: print to file
// TODO: make it possible to disable
// TODO: sync all timing (and solve off-by-ones) in this TB
// TODO: consider moving this to a separate file
`ifdef EXEC_TRACE_SUPPORT
function automatic string get_trace_string(
    int issue_slot,
    longint cur_inst_ret,
    longint cur_cycle,
    trace_pkt_t trace_p
);
    string msg;
    string event_msg;

    msg = $sformatf(
        "|   i%0d | %10d | %10d | 0x%h | 0x%h |",
        issue_slot,
        cur_inst_ret,
        cur_cycle,
        trace_p.addr,
        trace_p.inst
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
`endif

endmodule
