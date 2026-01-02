module WBU #(DATA_WIDTH = 32, ADDR_WIDTH = 32) (
	input [DATA_WIDTH-1:0] alu_out,
	input [2:0] wb_ctrl,
	input [ADDR_WIDTH-1:0] pc,
	output reg [DATA_WIDTH-1:0] wb_data
);

localparam WB_IDLE = 3'b000, WB_ALU = 3'b001, WB_PC = 3'b010;

always @(*) begin
	case (wb_ctrl)
		WB_IDLE: wb_data = {DATA_WIDTH{1'b0}};
		WB_ALU: wb_data =  alu_out;
		WB_PC: wb_data = pc + 1;
		default: wb_data = {DATA_WIDTH{1'b0}};
	endcase
end

endmodule
