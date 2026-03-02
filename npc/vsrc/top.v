module top #(INST_WIDTH = 32, DATA_WIDTH = 32) (
	input clk,
	input rst,
  output [INST_WIDTH-1:0] pc
);

import "DPI-C" function void npctrap(int a0);

wire j_pc, j_en, wb_en, imm_sel, ebreak_flag, lsu_en, lsu_wen;
wire [DATA_WIDTH-1:0] alu_out;
wire [INST_WIDTH-1:0] inst_fetch;
wire [DATA_WIDTH-1:0] imm;
wire [DATA_WIDTH-1:0] rdata;
wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;

wire [2:0] alu_ctrl;
wire [2:0] wb_ctrl;
wire [2:0] lsu_ctrl;
wire [1:0] j_cond;

wire [DATA_WIDTH-1:0] wb_data;
wire [DATA_WIDTH-1:0] srcval1;
wire [DATA_WIDTH-1:0] srcval2;


	IFU u_IFU (
		.clk(clk),
		.rst(rst),
		.j_pc(j_pc),
		.j_pc_addr(alu_out),
		.pc(pc),
		.inst_fetch(inst_fetch)
	);

	IDU u_IDU (
		.inst_fetch(inst_fetch),
		.imm(imm),
		.rd(rd),
		.rs1(rs1),
		.rs2(rs2),
		.alu_ctrl(alu_ctrl),
		.imm_sel(imm_sel),
		.wb_ctrl(wb_ctrl),
		.wb_en(wb_en),
		.lsu_en(lsu_en),
		.lsu_wen(lsu_wen),
		.lsu_ctrl(lsu_ctrl),
		.ebreak_flag(ebreak_flag),
		.j_en(j_en),
		.j_cond(j_cond)
	);

	RegisterFile u_gpr (
		.clk(clk),
		.rst(rst),
		.wen(wb_en),
		.wdata(wb_data),
		.waddr(rd),
		.raddr1(rs1),
		.raddr2(rs2),
		.rdata1(srcval1),
		.rdata2(srcval2)
	);

	EXU u_EXU (
		.imm_sel(imm_sel),
		.j_en(j_en),
		.j_cond(j_cond),
		.pc(pc),
		.alu_ctrl(alu_ctrl),
		.srcval1(srcval1),
		.srcval2(srcval2),
		.immval(imm),
		.alu_out(alu_out),
		.j_pc(j_pc)
	);

	LSU u_LSU (
		.lsu_en(lsu_en),
		.clk(clk),
		.wen(lsu_wen),
		.lsu_ctrl(lsu_ctrl),
		.wdata(srcval2),
		.waddr(alu_out),

		.raddr(alu_out),
		.rdata(rdata)
	);

	WBU u_WBU (
		.alu_out(alu_out),
		.mem_out(rdata),
		.wb_ctrl(wb_ctrl),
		.imm(imm),
		.pc(pc),
		.wb_data(wb_data)
	);
	
always @(*) begin
	if(ebreak_flag)
		npctrap(u_gpr.rf[10]);
end

endmodule

