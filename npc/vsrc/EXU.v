`include "alu_opcodes.v"
module EXU #(DATA_WIDTH = 32) (
	input [1:0] op_ctrl,
	input j_en,
	input [2:0] j_cond,
	input [DATA_WIDTH-1:0] pc,
	input [DATA_WIDTH-1:0] csr,
	input [3:0] alu_ctrl,
	input [DATA_WIDTH-1:0] rs1_data,
	input [DATA_WIDTH-1:0] rs2_data,
	input [DATA_WIDTH-1:0] immval,
	output reg [DATA_WIDTH-1:0] alu_out,
	output j_pc
);
wire [DATA_WIDTH-1:0] op1;
wire [DATA_WIDTH-1:0] op2;
assign op1 = (op_ctrl==`OP_PC_IMM) ? pc : rs1_data;
assign op2 = (op_ctrl==`OP_RS1_IMM | op_ctrl==`OP_PC_IMM) ? immval : 
	(op_ctrl==`OP_RS1_CSR) ? csr : rs2_data;

wire [DATA_WIDTH-1:0] sub_out;
assign sub_out = op1 - op2;
always @(*) begin
	case (alu_ctrl)
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
	if (j_en) begin
		case (j_cond)
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

endmodule

