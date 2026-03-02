module EXU #(DATA_WIDTH = 32) (
	input imm_sel,
	input [DATA_WIDTH-1:0] pc,
	input [2:0] alu_ctrl,
	input [DATA_WIDTH-1:0] srcval1,
	input [DATA_WIDTH-1:0] srcval2,
	input [DATA_WIDTH-1:0] immval,
	output reg [DATA_WIDTH-1:0] alu_out
);
localparam ALU_IDEL = 3'b000, ALU_ADD = 3'b001, ALU_ADD_PC = 3'b010,
	ALU_SUB = 3'b011, ALU_LESS_U = 3'b100, ALU_LESS = 3'b101;
wire [DATA_WIDTH-1:0] op1;
wire [DATA_WIDTH-1:0] op2;
assign op1 = srcval1;
assign op2 = imm_sel ? immval : srcval2;

wire [DATA_WIDTH-1:0] sub_out;
assign sub_out = op1 - op2;
always @(*) begin
	case (alu_ctrl)
		ALU_IDEL: alu_out = {DATA_WIDTH{1'b0}};
		ALU_ADD: alu_out = op1 + op2;
		ALU_SUB: alu_out = sub_out;
		ALU_ADD_PC: alu_out = pc + op2;
		ALU_LESS_U: alu_out = (op1 < op2) ? {{(DATA_WIDTH-1){1'b0}},1'b1} : {(DATA_WIDTH){1'b0}};
		ALU_LESS: alu_out = {{(DATA_WIDTH-1){1'b0}},sub_out[DATA_WIDTH-1]};
		default: alu_out = {DATA_WIDTH{1'b0}};
	endcase
end

endmodule

