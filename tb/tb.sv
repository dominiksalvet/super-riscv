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
    import exec_trace_pkg::*;
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
logic past_rst = 1'b0;

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

    past_rst <= rst;
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
longint cycles = 0;
longint max_cycles;
bit     exec_trace_enabled = 0;
integer exec_trace_fd = 0;
integer ret_val_fd = 0;

initial begin : sim_init
    string  mem_image_path;
    integer mem_image_fd;
    string  exec_trace_path;
    string  ret_val_path;

    // argument processing
    if (!$value$plusargs("max+cycles=%d", max_cycles))
        max_cycles = DEFAULT_MAX_CYCLES;

    if (!$value$plusargs("test+path=%s", mem_image_path))
        $fatal(1, "No test path specified");

    if ($test$plusargs("trace")) begin
        if (!$value$plusargs("trace+file=%s", exec_trace_path))
            exec_trace_path = "trace.log";

        exec_trace_enabled = 1;
    end

    if (!$value$plusargs("ret+val+file=%s", ret_val_path))
        ret_val_path = "ret_val.txt";

    // initial file operations
    mem_image_fd = $fopen(mem_image_path, "r");
    if (mem_image_fd == 0)
        $fatal(1, {"Unable to read test memory image file: ", mem_image_path});
    $fclose(mem_image_fd);

    $readmemh(mem_image_path, mem.r_mem);

    if (exec_trace_enabled) begin
        exec_trace_fd = $fopen(exec_trace_path, "w");
        if (exec_trace_fd == 0)
            $fatal(1, {"Unable to create file for trace: ", exec_trace_path});

        $fdisplay(exec_trace_fd, get_trace_header());
    end

    ret_val_fd = $fopen(ret_val_path, "w");
    if (ret_val_fd == 0)
        $fatal(1, {"Unable to use file for test return value: ", ret_val_path});

    // signal init
    rst_vec = DEFAULT_RST_VEC;
end

// active for RESET_CYCLES rising edges of clock
assign rst = cycles < RESET_CYCLES;

// basic performance monitoring
longint inst_ret = 0; // number of retired instructions
longint i0_next_inst_ret;
longint i1_next_inst_ret;

assign i0_next_inst_ret = inst_ret + longint'(core.exu0.r_wb_i0_valid);
assign i1_next_inst_ret = i0_next_inst_ret + longint'(core.exu0.r_wb_i1_valid);

// TODO: sync all timing (and solve off-by-ones) in this TB
// TODO: think about the trace/header print placement
always_ff @(posedge clk) begin : sim_ctl
    // max cycles timeout, if not halting the same cycle
    if (max_cycles != 0 && cycles >= max_cycles && !mb_halt_event) begin
        $display("[TIMEOUT] Maximum cycles limit (%0d) reached", max_cycles);
        $finish;
    end

`ifdef EXEC_TRACE_SUPPORT
    // CPU execution trace
    if (exec_trace_enabled) begin 
        if (core.exu0.r_wb_i0_valid)
            $fdisplay(exec_trace_fd, get_trace_string(0, i0_next_inst_ret, cycles, core.exu0.wb_i0_final_trace_p));

        if (core.exu0.r_wb_i1_valid)
            $fdisplay(exec_trace_fd, get_trace_string(1, i1_next_inst_ret, cycles, core.exu0.wb_i1_final_trace_p));
    end
`endif

    cycles <= cycles + 1;

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
        // store return value
        $fdisplay(ret_val_fd, "%0d", signed'(mem.dmem_hwdata));
        $finish;
    end

    if (mb_putc_event) begin
        $write("%c", mem.dmem_hwdata[7:0]);
    end
end

always_comb begin : mailbox_ctl_reads
    if (mb_getc_event) begin
        // TODO: meta events in always_comb are not a good idea (may trigger multiple times)
        dmem_hrdata_to_core = $fgetc(STDIN_FD);
    end else begin
        dmem_hrdata_to_core = dmem_hrdata_from_mem;
    end
end

final begin : finish_sim
    // TODO: align these values with real program architectural state
    $display("Simulated cycles: %0d", cycles);
    $display("Retired instructions: %0d", inst_ret);

    if (ret_val_fd != 0)
        $fclose(ret_val_fd);

    if (exec_trace_fd != 0)
        $fclose(exec_trace_fd);
end

endmodule
