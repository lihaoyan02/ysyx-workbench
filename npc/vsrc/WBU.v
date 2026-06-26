`include "alu_opcodes.v"
module WBU #(XLEN = 32) (
	input clk,
	input rst,
	input ls_wb_valid,
	output ls_wb_ready,
	input [XLEN-1:0] ls_wb_pc,
	input [XLEN-1:0] ls_wb_npc,
	input [XLEN-1:0] ls_wb_inst,
	input [XLEN-1:0] ls_wb_imm,
	input [4:0] ls_wb_rd,
	input [2:0] ls_wb_ctrl,
	input ls_wb_en,
	input ls_wb_ebreak,
	input [XLEN-1:0] ls_wb_exu_data,
	input [XLEN-1:0] ls_wb_rdata,

	input ls_wb_csr_exvalid,
	input [XLEN-1:0] ls_wb_csr_cause,
	input ls_wb_csr_wvalid,
	input [11:0] ls_wb_csr_waddr,
	input [XLEN-1:0] ls_wb_csr_wdata,

	output wb_rf_valid,
	output wb_rf_wen,
	output [4:0] wb_rf_rd,
	output [XLEN-1:0] wb_rf_data,

	output wb_csr_exvalid,
	output [XLEN-1:0] wb_csr_cause,
	output [XLEN-1:0] wb_csr_pc,
	output wb_csr_wvalid,
	output [11:0] wb_csr_waddr,
	output [XLEN-1:0] wb_csr_wdata,

	output ebreak_flag
);

// localparam WB_IDLE = 3'b000, WB_ALU = 3'b001, 
// 	WB_PC = 3'b010, WB_IMM = 3'b011, WB_MEM = 3'b100;

reg [XLEN-1:0] wb_data;
always @(*) begin
	case (ls_wb_ctrl)
		`WB_IDLE: wb_data = {XLEN{1'b0}};
		`WB_ALU: wb_data =  ls_wb_exu_data;
		`WB_PC: wb_data = ls_wb_pc + 4;
		`WB_IMM: wb_data = ls_wb_imm;
		`WB_MEM: wb_data = ls_wb_rdata;
		default: wb_data = {XLEN{1'b0}};
	endcase
end

assign wb_rf_valid = ls_wb_valid & ls_wb_ready;
assign ls_wb_ready = 1;
assign wb_rf_wen = wb_rf_valid ? ls_wb_en : 0;
assign wb_rf_rd =  wb_rf_valid ? ls_wb_rd : 0;
assign wb_rf_data =  wb_rf_valid ? wb_data : 0;
assign ebreak_flag =  wb_rf_valid ? ls_wb_ebreak : 0;

assign wb_csr_exvalid =  wb_rf_valid ? ls_wb_csr_exvalid : 0;
assign wb_csr_cause =  wb_rf_valid ? ls_wb_csr_cause : 0;
assign wb_csr_pc =  wb_rf_valid ? ls_wb_pc : 0;
assign wb_csr_wvalid =  wb_rf_valid ? ls_wb_csr_wvalid : 0;
assign wb_csr_waddr =  wb_rf_valid ? ls_wb_csr_waddr : 0;
assign wb_csr_wdata =  wb_rf_valid ? ls_wb_csr_wdata : 0;

reg [XLEN-1:0] commit_pc, commit_npc, commit_inst, commit;
always @(posedge clk) begin
	if (rst) begin
		commit_pc <= 0;
		commit_npc <= 0;
		commit_inst <= 0;
		commit <= 0;
	end
	else if (wb_rf_valid) begin
		commit_pc <= ls_wb_pc;
		commit_npc <= ls_wb_npc;
		commit_inst <= ls_wb_inst;
		commit <= 1;
	end
	else begin
		commit <= 0;
	end
end

function int read_inst();
	return commit_inst;
endfunction

export "DPI-C" function read_inst;

function int read_pc();
	return commit_pc;
endfunction

export "DPI-C" function read_pc;

function int read_dnpc();
	return commit_npc;
endfunction

export "DPI-C" function read_dnpc;

function int read_state();
	return commit;
endfunction

export "DPI-C" function read_state;

endmodule
