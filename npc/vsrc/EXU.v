module EXU #(DATA_WIDTH = 32) (
	input imm_sel,
	input [2:0] alu_ctrl,
	input [DATA_WIDTH-1:0] srcval1,
	input [DATA_WIDTH-1:0] srcval2,
	input [DATA_WIDTH-1:0] immval,
	output reg [DATA_WIDTH-1:0] alu_out
);
localparam ALU_IDEL = 3'b000, ALU_ADD = 3'b001;
wire [DATA_WIDTH-1:0] op1;
wire [DATA_WIDTH-1:0] op2;
assign op1 = srcval1;
assign op2 = imm_sel ? immval : srcval2;

always @(*) begin
	case (alu_ctrl)
		ALU_IDEL: alu_out = {DATA_WIDTH{1'b0}};
		ALU_ADD: alu_out = op1 + op2;
		default: alu_out = {DATA_WIDTH{1'b0}};
	endcase
end

endmodule

