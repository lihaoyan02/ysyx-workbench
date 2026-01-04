module WBU #(DATA_WIDTH = 32, ADDR_WIDTH = 32) (
	input [DATA_WIDTH-1:0] alu_out,
	input [DATA_WIDTH-1:0] mem_out,
	input [2:0] wb_ctrl,
	input [ADDR_WIDTH-1:0] pc,
	input [DATA_WIDTH-1:0] imm,
	output reg [DATA_WIDTH-1:0] wb_data
);

localparam WB_IDLE = 3'b000, WB_ALU = 3'b001, 
	WB_PC = 3'b010, WB_IMM = 3'b011, WB_MEM = 3'b100;

always @(*) begin
	case (wb_ctrl)
		WB_IDLE: wb_data = {DATA_WIDTH{1'b0}};
		WB_ALU: wb_data =  alu_out;
		WB_PC: wb_data = pc + 4;
		WB_IMM: wb_data = imm;
		WB_MEM: wb_data = mem_out;
		default: wb_data = {DATA_WIDTH{1'b0}};
	endcase
end

endmodule
