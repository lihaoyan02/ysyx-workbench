`include "alu_opcodes.v"
module EXU #(XLEN = 32) (
	input clk,
	input rst,
	// from IDU
	input id_ex_valid,
	output ex_id_ready,
	input [XLEN-1:0] id_ex_pc,
	input [XLEN-1:0] id_ex_inst,

	input [3:0] id_ex_alu_ctrl,
	input [1:0] id_ex_alu_op_ctrl,
	input [XLEN-1:0] id_ex_imm,
	input [4:0] id_ex_rd,
	input [4:0] id_ex_rs1,
	input [4:0] id_ex_rs2,
	input [XLEN-1:0] id_ex_rs1_data,
	input [XLEN-1:0] id_ex_rs2_data,
	input id_ex_j_en,
	input [2:0] id_ex_j_cond,
	input [1:0] id_ex_csr_wctrl,
	input [XLEN-1:0] csr_ex_data,
	
	input id_ex_lsu_en,
	input id_ex_lsu_wen,
	input [2:0] id_ex_lsu_ctrl,

	input [2:0] id_ex_wb_ctrl,
	input id_ex_wb_en,
	input id_ex_ebreak_flag,

	input id_ex_csr_exvalid,
	input [XLEN-1:0] id_ex_csr_cause,
	input id_ex_csr_wvalid,
	input [11:0] id_ex_csr_waddr,

	input ls_wb_valid,
	input [4:0] wb_rf_rd,
	input [XLEN-1:0] wb_rf_data,

	// to LSU
	output ex_ls_valid,
	input ls_ex_ready,
	output ex_ls_en,
	output ex_ls_wen,
	output [2:0] ex_ls_ctrl,
	output [XLEN-1:0] ex_ls_wdata,
	output [XLEN-1:0] ex_ls_data_out,
	output [XLEN-1:0] ex_ls_pc,
	output [XLEN-1:0] ex_ls_npc,
	output [XLEN-1:0] ex_ls_inst,
	output [XLEN-1:0] ex_ls_imm,
	// signal for WBU
	output [4:0] ex_ls_rd,
	output [2:0] ex_ls_wb_ctrl,
	output ex_ls_wb_en,
	output ex_ls_ebreak_flag,

	output ex_ls_csr_exvalid,
	output [XLEN-1:0] ex_ls_csr_cause,
	output ex_ls_csr_wvalid,
	output [11:0] ex_ls_csr_waddr,
	output [XLEN-1:0] ex_ls_csr_wdata,

	// to IFU
	output ex_if_jvalid,
	input if_ex_jready,
	output [XLEN-1:0] ex_if_jpc,

	output ex_glb_flush
);

import "DPI-C" function void performance_counter(int category);

/*-------------------register---------------------*/
reg exu_valid;
reg exu_lsu_en;
reg exu_lsu_wen;
reg [2:0] exu_lsu_ctrl;
reg [XLEN-1:0] exu_lsu_wdata;
reg [XLEN-1:0] exu_out;
reg [XLEN-1:0] exu_pc;
reg [XLEN-1:0] exu_npc;
reg [XLEN-1:0] exu_inst;
reg [XLEN-1:0] exu_imm;
reg [4:0] exu_rd;
reg [2:0] exu_wb_ctrl;
reg exu_wb_en;
reg exu_ebreak_flag;
reg ex_ls_csr_exvalid_r;
reg [XLEN-1:0] ex_ls_csr_cause_r;
reg ex_ls_csr_wvalid_r;
reg [11:0] ex_ls_csr_waddr_r;
reg [XLEN-1:0] ex_ls_csr_wdata_r;

/*----------------output----------------------*/
assign ex_id_ready = ~ex_ls_valid | (ex_ls_valid & ls_ex_ready) & (~glb_flush);

assign ex_ls_valid = exu_valid;
assign ex_ls_en = exu_lsu_en;
assign ex_ls_wen = exu_lsu_wen;
assign ex_ls_ctrl = exu_lsu_ctrl;
assign ex_ls_wdata = exu_lsu_wdata;
assign ex_ls_data_out = exu_out;
assign ex_ls_pc = exu_pc;
assign ex_ls_npc = exu_npc;
assign ex_ls_inst = exu_inst;
assign ex_ls_imm = exu_imm;
assign ex_ls_rd = exu_rd;
assign ex_ls_wb_ctrl = exu_wb_ctrl;
assign ex_ls_wb_en = exu_wb_en;
assign ex_ls_ebreak_flag = exu_ebreak_flag;
assign ex_ls_csr_exvalid = ex_ls_csr_exvalid_r;
assign ex_ls_csr_cause = ex_ls_csr_cause_r;
assign ex_ls_csr_wvalid = ex_ls_csr_wvalid_r;
assign ex_ls_csr_waddr = ex_ls_csr_waddr_r;
assign ex_ls_csr_wdata = ex_ls_csr_wdata_r;
assign ex_if_jvalid = jump_valid;
assign ex_if_jpc = exu_out;
assign ex_glb_flush = glb_flush;

/*-------------------bypass----------------------*/
wire exu_bypass_rs1, exu_bypass_rs2, wbu_bypass_rs1, wbu_bypass_rs2;
wire [XLEN-1:0] id_ex_rs1_data_bypass, id_ex_rs2_data_bypass;
assign exu_bypass_rs1 = (id_ex_rs1 != 0 & ex_ls_valid) & ((id_ex_rs1==ex_ls_rd) & (ex_ls_wb_ctrl==`WB_ALU));
assign exu_bypass_rs2 = (id_ex_rs2 != 0 & ex_ls_valid) & ((id_ex_rs2==ex_ls_rd) & (ex_ls_wb_ctrl==`WB_ALU));
assign wbu_bypass_rs1 = (id_ex_rs1 != 0 & ls_wb_valid) & (id_ex_rs1==wb_rf_rd);
assign wbu_bypass_rs2 = (id_ex_rs2 != 0 & ls_wb_valid) & (id_ex_rs2==wb_rf_rd);
assign id_ex_rs1_data_bypass = exu_bypass_rs1 ? ex_ls_data_out : 
							wbu_bypass_rs1 ? wb_rf_data : id_ex_rs1_data;
assign id_ex_rs2_data_bypass = exu_bypass_rs2 ? ex_ls_data_out : 
							wbu_bypass_rs2 ? wb_rf_data : id_ex_rs2_data;

/*-------------------ALU----------------------*/
wire [XLEN-1:0] op1;
wire [XLEN-1:0] op2;
reg [XLEN-1:0] alu_out;
assign op1 = (id_ex_alu_op_ctrl==`OP_PC_IMM) ? id_ex_pc : id_ex_rs1_data_bypass;
assign op2 = (id_ex_alu_op_ctrl==`OP_RS1_IMM | id_ex_alu_op_ctrl==`OP_PC_IMM) ? id_ex_imm : 
	(id_ex_alu_op_ctrl==`OP_RS1_CSR) ? csr_ex_data : id_ex_rs2_data_bypass;

wire [XLEN-1:0] sub_out;
assign sub_out = op1 - op2;
always @(*) begin
	case (id_ex_alu_ctrl)
		`ALU_IDLE: alu_out = {XLEN{1'b0}};
		`ALU_ADD: alu_out = op1 + op2;
		`ALU_SUB: alu_out = sub_out;
		`ALU_OP2: alu_out = op2;
		`ALU_LESS_U: alu_out = (op1 < op2) ? {{(XLEN-1){1'b0}},1'b1} : {(XLEN){1'b0}};
		`ALU_LESS: alu_out = op1[XLEN-1]==op2[XLEN-1] ? {{(XLEN-1){1'b0}},sub_out[XLEN-1]} : {{(XLEN-1){1'b0}},op1[XLEN-1]};
		`ALU_SHIFT_LEFT: alu_out = op1 << op2[4:0];
		`ALU_SHIFT_RIGHT_U: alu_out = op1 >> op2[4:0];
		`ALU_SHIFT_RIGHT: alu_out = $signed(op1) >>> op2[4:0];
		`ALU_AND: alu_out = op1 & op2;
		`ALU_XOR: alu_out = op1 ^ op2;
		`ALU_OR: alu_out = op1 | op2;
		default: alu_out = {XLEN{1'b0}};
	endcase
end

/*-------------------BJU----------------------*/
reg j_enable;
wire [XLEN-1:0] rs1_min_rs2;
assign rs1_min_rs2 = id_ex_rs1_data_bypass - id_ex_rs2_data_bypass;
always @(*) begin
	if (id_ex_j_en) begin
		case (id_ex_j_cond)
			`J_UNCOND: j_enable = 1'b1;
			`J_BEQ: j_enable = (id_ex_rs1_data_bypass == id_ex_rs2_data_bypass);
			`J_BNE: j_enable = (id_ex_rs1_data_bypass != id_ex_rs2_data_bypass);
			`J_BGE: j_enable = (id_ex_rs1_data_bypass[XLEN-1] == id_ex_rs2_data_bypass[XLEN-1]) ?
			 	~rs1_min_rs2[XLEN-1] : id_ex_rs2_data_bypass[XLEN-1];
			`J_BGE_U: j_enable = id_ex_rs1_data_bypass >= id_ex_rs2_data_bypass; 
			`J_BLT_U: j_enable = id_ex_rs1_data_bypass < id_ex_rs2_data_bypass; 
			`J_BLT: j_enable = (id_ex_rs1_data_bypass[XLEN-1] == id_ex_rs2_data_bypass[XLEN-1]) ?
			 	rs1_min_rs2[XLEN-1] : id_ex_rs1_data_bypass[XLEN-1];
			default: j_enable = 1'b0;
		endcase
	end
	else
		j_enable = 1'b0;
end

/*-------------------CSRW----------------------*/
reg [XLEN-1:0] csr_wdata;
always @(*) begin
	if (id_ex_csr_wvalid) begin
		case (id_ex_csr_wctrl)
			`CSRW_IDLE: csr_wdata = 0;
			`CSRW_RS1: csr_wdata = id_ex_rs1_data_bypass;
			`CSRW_SRS1: csr_wdata = id_ex_rs1_data_bypass | csr_ex_data;
			default: csr_wdata = 0;
		endcase
	end
	else
		csr_wdata = 0;
end
/*-------------------sequential logic----------------------*/
always @(posedge clk) begin
	if (rst) begin
		exu_valid <= 0;
	end
	else if (id_ex_valid & ex_id_ready) begin
		exu_valid <= 1;
	end
	else if (ex_ls_valid & ls_ex_ready) begin
		exu_valid <= 0;
	end
end

reg jump_valid;
always @(posedge clk) begin
	if (rst) begin
		jump_valid <= 0;
	end
	else if (id_ex_valid & ex_id_ready) begin
		jump_valid <= j_enable;
	end
	else if (ex_if_jvalid & if_ex_jready) begin
		jump_valid <= 0;
	end
end

reg glb_flush;
always @(posedge clk) begin
	if (rst) begin
		glb_flush <= 0;
	end
	else if (id_ex_valid & ex_id_ready & j_enable) begin
		glb_flush <= 1;
	end
	else begin
		glb_flush <= 0;
	end
end

always @(posedge clk) begin
	if (rst) begin
		exu_out <= {XLEN{1'b0}};
		exu_lsu_en <= 1'b0;
		exu_lsu_wen <= 1'b0;
		exu_lsu_ctrl <= 3'b0;
		exu_lsu_wdata <= {XLEN{1'b0}};
		exu_pc <= 0;
		exu_npc <= 0;
		exu_inst <= 0;
		exu_imm <= 0;
		exu_rd <= 0;
		exu_wb_ctrl <= 3'b0;
		exu_wb_en <= 1'b0;
		exu_ebreak_flag <= 1'b0;
		ex_ls_csr_exvalid_r <= 0;
		ex_ls_csr_cause_r <= 0;
		ex_ls_csr_wvalid_r <= 0;
		ex_ls_csr_waddr_r <= 0;
		ex_ls_csr_wdata_r <= 0;
	end
	else if (id_ex_valid & ex_id_ready) begin
		if (id_ex_alu_ctrl!=`ALU_IDLE & id_ex_alu_ctrl!=`ALU_OP2) begin
			performance_counter(1);
		end
		exu_out <= alu_out; // jump addr & alu result & lsu addr
		exu_lsu_en <= id_ex_lsu_en;
		exu_lsu_wen <= id_ex_lsu_wen;
		exu_lsu_ctrl <= id_ex_lsu_ctrl;
		exu_lsu_wdata <= id_ex_rs2_data_bypass;
		exu_pc <= id_ex_pc;
		if (j_enable) begin //for debug
			exu_npc <= alu_out;
		end
		else begin
			exu_npc <= id_ex_pc+4;
		end
		exu_inst <= id_ex_inst;
		exu_imm <= id_ex_imm;
		exu_rd <= id_ex_rd;
		exu_wb_ctrl <= id_ex_wb_ctrl;
		exu_wb_en <= id_ex_wb_en;
		exu_ebreak_flag <= id_ex_ebreak_flag;

		ex_ls_csr_exvalid_r <= id_ex_csr_exvalid;
		ex_ls_csr_cause_r <= id_ex_csr_cause;
		ex_ls_csr_wvalid_r <= id_ex_csr_wvalid;
		ex_ls_csr_waddr_r <= id_ex_csr_waddr;
		ex_ls_csr_wdata_r <= csr_wdata;
	end
end
endmodule

