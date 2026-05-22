`include "alu_opcodes.v"
module EXU #(DATA_WIDTH = 32) (
	input clk,
	input rst,
	input idu_valid,
	input [1:0] idu_alu_op_ctrl,
	input [3:0] idu_alu_ctrl,
	input idu_j_en,
	input [2:0] idu_j_cond,
	input [DATA_WIDTH-1:0] pc,
	input [DATA_WIDTH-1:0] csr,
	input [DATA_WIDTH-1:0] rs1_data,
	input [DATA_WIDTH-1:0] rs2_data,
	input [DATA_WIDTH-1:0] idu_imm,

	input idu_lsu_en,
	input idu_lsu_wen,
	input [2:0] idu_lsu_ctrl,

	output reg exu_lsu_en,
	output reg exu_lsu_wen,
	output reg [2:0] exu_lsu_ctrl,
	output reg [DATA_WIDTH-1:0] exu_lsu_wdata,
	output reg exu_valid,
	output reg [DATA_WIDTH-1:0] exu_out,
	output reg exu_j_pc
);

import "DPI-C" function void performance_counter(int category);

wire [DATA_WIDTH-1:0] op1;
wire [DATA_WIDTH-1:0] op2;
reg [DATA_WIDTH-1:0] alu_out;
reg j_pc;
assign op1 = (idu_alu_op_ctrl==`OP_PC_IMM) ? pc : rs1_data;
assign op2 = (idu_alu_op_ctrl==`OP_RS1_IMM | idu_alu_op_ctrl==`OP_PC_IMM) ? idu_imm : 
	(idu_alu_op_ctrl==`OP_RS1_CSR) ? csr : rs2_data;

wire [DATA_WIDTH-1:0] sub_out;
assign sub_out = op1 - op2;
always @(*) begin
	case (idu_alu_ctrl)
		`ALU_IDLE: alu_out = {DATA_WIDTH{1'b0}};
		`ALU_ADD: alu_out = op1 + op2;
		`ALU_SUB: alu_out = sub_out;
		`ALU_OP2: alu_out = op2;
		`ALU_LESS_U: alu_out = (op1 < op2) ? {{(DATA_WIDTH-1){1'b0}},1'b1} : {(DATA_WIDTH){1'b0}};
		`ALU_LESS: alu_out = op1[DATA_WIDTH-1]==op2[DATA_WIDTH-1] ? {{(DATA_WIDTH-1){1'b0}},sub_out[DATA_WIDTH-1]} : {{(DATA_WIDTH-1){1'b0}},op1[DATA_WIDTH-1]};
		`ALU_SHIFT_LEFT: alu_out = op1 << op2[4:0];
		`ALU_SHIFT_RIGHT_U: alu_out = op1 >> op2[4:0];
		`ALU_SHIFT_RIGHT: alu_out = $signed(op1) >>> op2[4:0];
		`ALU_AND: alu_out = op1 & op2;
		`ALU_XOR: alu_out = op1 ^ op2;
		`ALU_OR: alu_out = op1 | op2;
		default: alu_out = {DATA_WIDTH{1'b0}};
	endcase
end

always @(*) begin
	if (idu_j_en) begin
		case (idu_j_cond)
			`J_UNCOND: j_pc = 1'b1;
			`J_BEQ: j_pc = (rs1_data == rs2_data);
			`J_BNE: j_pc = (rs1_data != rs2_data);
			`J_BGE: j_pc = (rs1_data[DATA_WIDTH-1] == rs2_data[DATA_WIDTH-1]) ?
			 	~{rs1_data-rs2_data}[DATA_WIDTH-1] : rs2_data[DATA_WIDTH-1];
			`J_BGE_U: j_pc = rs1_data >= rs2_data; 
			`J_BLT_U: j_pc = rs1_data < rs2_data; 
			`J_BLT: j_pc = (rs1_data[DATA_WIDTH-1] == rs2_data[DATA_WIDTH-1]) ?
			 	{rs1_data-rs2_data}[DATA_WIDTH-1] : rs1_data[DATA_WIDTH-1];
			default: j_pc = 1'b0;
		endcase
	end
	else
		j_pc = 1'b0;
end

always @(posedge clk) begin
	if (rst) begin
		exu_valid <= 1'b0;
		exu_out <= {DATA_WIDTH{1'b0}};
		exu_j_pc <= 1'b0;
		exu_lsu_en <= 1'b0;
		exu_lsu_wen <= 1'b0;
		exu_lsu_ctrl <= 3'b0;
		exu_lsu_wdata <= {DATA_WIDTH{1'b0}};
	end
	else if (idu_valid) begin
		if (idu_alu_ctrl!=`ALU_IDLE & idu_alu_ctrl!=`ALU_OP2) begin
			performance_counter(1);
		end
		exu_valid <= 1;
		exu_out <= alu_out; // jump addr & alu result & lsu addr
		exu_j_pc <= j_pc;
		exu_lsu_en <= idu_lsu_en;
		exu_lsu_wen <= idu_lsu_wen;
		exu_lsu_ctrl <= idu_lsu_ctrl;
		exu_lsu_wdata <= rs2_data;
	end else begin
		exu_valid <= 0;
		exu_out <= {DATA_WIDTH{1'b0}};
		exu_j_pc <= 1'b0;
		exu_lsu_en <= 1'b0;
		exu_lsu_wen <= 1'b0;
		exu_lsu_ctrl <= 3'b0;
		exu_lsu_wdata <= {DATA_WIDTH{1'b0}};
	end
end
endmodule

