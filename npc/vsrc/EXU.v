`include "alu_opcodes.v"
module EXU #(DATA_WIDTH = 32) (
	input imm_sel,
	input j_en,
	input [2:0] j_cond,
	input [DATA_WIDTH-1:0] pc,
	input [3:0] alu_ctrl,
	input [DATA_WIDTH-1:0] srcval1,
	input [DATA_WIDTH-1:0] srcval2,
	input [DATA_WIDTH-1:0] immval,
	output reg [DATA_WIDTH-1:0] alu_out,
	output j_pc
);
wire [DATA_WIDTH-1:0] op1;
wire [DATA_WIDTH-1:0] op2;
assign op1 = srcval1;
assign op2 = imm_sel ? immval : srcval2;

wire [DATA_WIDTH-1:0] sub_out;
assign sub_out = op1 - op2;
always @(*) begin
	case (alu_ctrl)
		`ALU_IDLE: alu_out = {DATA_WIDTH{1'b0}};
		`ALU_ADD: alu_out = op1 + op2;
		`ALU_SUB: alu_out = sub_out;
		`ALU_ADD_PC: alu_out = pc + op2;
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
	if (j_en) begin
		case (j_cond)
			`J_UNCOND: j_pc = 1'b1;
			`J_BEQ: j_pc = (srcval1 == srcval2);
			`J_BNE: j_pc = (srcval1 != srcval2);
			`J_BGE: j_pc = (srcval1[DATA_WIDTH-1] == srcval2[DATA_WIDTH-1]) ?
			 	~{srcval1-srcval2}[DATA_WIDTH-1] : srcval2[DATA_WIDTH-1];
			`J_BGE_U: j_pc = srcval1 >= srcval2; 
			`J_BLT_U: j_pc = srcval1 < srcval2; 
			`J_BLT: j_pc = (srcval1[DATA_WIDTH-1] == srcval2[DATA_WIDTH-1]) ?
			 	{srcval1-srcval2}[DATA_WIDTH-1] : srcval1[DATA_WIDTH-1];
			default: j_pc = 1'b0;
		endcase
	end
	else
		j_pc = 1'b0;
end

endmodule

