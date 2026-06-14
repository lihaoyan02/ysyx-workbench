module WBU #(XLEN = 32) (
	input ls_wb_valid,
	output ls_wb_ready,
	input [XLEN-1:0] ls_wb_pc,
	input [XLEN-1:0] ls_wb_inst,
	input [XLEN-1:0] ls_wb_imm,
	input [4:0] ls_wb_rd,
	input [2:0] ls_wb_ctrl,
	input ls_wb_en,
	input ls_wb_ebreak,
	input [XLEN-1:0] ls_wb_exu_data,
	input [XLEN-1:0] ls_wb_rdata,

	output wb_rf_valid,
	output wb_rf_wen,
	output [4:0] wb_rf_rd,
	output [XLEN-1:0] wb_rf_data,

	output ebreak_flag
);

localparam WB_IDLE = 3'b000, WB_ALU = 3'b001, 
	WB_PC = 3'b010, WB_IMM = 3'b011, WB_MEM = 3'b100;

reg [XLEN-1:0] wb_data;
always @(*) begin
	case (ls_wb_ctrl)
		WB_IDLE: wb_data = {XLEN{1'b0}};
		WB_ALU: wb_data =  ls_wb_exu_data;
		WB_PC: wb_data = ls_wb_pc + 4;
		WB_IMM: wb_data = ls_wb_imm;
		WB_MEM: wb_data = ls_wb_rdata;
		default: wb_data = {XLEN{1'b0}};
	endcase
end

assign wb_rf_valid = ls_wb_valid & ls_wb_ready;
assign ls_wb_ready = 1;
assign wb_rf_wen = wb_rf_valid ? ls_wb_en : 0;
assign wb_rf_rd =  wb_rf_valid ? ls_wb_rd : 0;
assign wb_rf_data =  wb_rf_valid ? wb_data : 0;
assign ebreak_flag =  wb_rf_valid ? ls_wb_ebreak : 0;

endmodule
