module top #(INST_WIDTH = 32, DATA_WIDTH = 32) (
	input clk,
	input rst,
  output [INST_WIDTH-1:0] pc
);

import "DPI-C" function void npctrap(int a0);

wire j_pc, j_en, wb_en, ebreak_flag, idu_en, lsu_en, lsu_wen, csr_wen, lsu_ready;
wire [DATA_WIDTH-1:0] alu_out;
wire [INST_WIDTH-1:0] inst_fetch;
wire [DATA_WIDTH-1:0] imm;
wire [DATA_WIDTH-1:0] lsu_rdata;
wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;

wire [3:0] alu_ctrl;
wire [1:0] alu_op_ctrl;
wire [2:0] wb_ctrl;
wire [2:0] lsu_ctrl;
wire [2:0] j_cond;

wire [DATA_WIDTH-1:0] wb_data;
wire [DATA_WIDTH-1:0] rs1_data;
wire [DATA_WIDTH-1:0] rs2_data;

wire [DATA_WIDTH-1:0] csr_rdata;
wire [11:0] csr_addr;
wire csr_event;


	IFU u_IFU (
		.clk(clk),
		.rst(rst),
		.j_pc(j_pc),
		.j_pc_addr(alu_out),
		.ready_in(lsu_ready),
		.pc(pc),
		.idu_en(idu_en),
		.inst_fetch(inst_fetch)
	);

	IDU u_IDU (
		.inst_fetch(inst_fetch),
		.en(idu_en),
		.imm(imm),
		.rd(rd),
		.rs1(rs1),
		.rs2(rs2),
		.alu_ctrl(alu_ctrl),
		.alu_op_ctrl(alu_op_ctrl),
		.wb_ctrl(wb_ctrl),
		.wb_en(wb_en),
		.lsu_en(lsu_en),
		.lsu_wen(lsu_wen),
		.lsu_ctrl(lsu_ctrl),
		.ebreak_flag(ebreak_flag),
		.j_en(j_en),
		.j_cond(j_cond),
		.csr_wen(csr_wen),
		.csr_event(csr_event),
		.csr_addr(csr_addr)
	);

	RegisterFile u_gpr (
		.clk(clk),
		.rst(rst),
		.wen(wb_en),
		.ready_in(lsu_ready),
		.wdata(wb_data),
		.waddr(rd),
		.raddr1(rs1),
		.raddr2(rs2),
		.rdata1(rs1_data),
		.rdata2(rs2_data)
	);

	CSR_group u_csr (
		.clk(clk),
		.rst(rst),
		.wen(csr_wen),
		.pc(pc),
		.csr_event(csr_event),
		.addr(csr_addr),
		.wdata(rs1_data),
		.rdata(csr_rdata)
	);

	EXU u_EXU (
		.op_ctrl(alu_op_ctrl),
		.j_en(j_en),
		.j_cond(j_cond),
		.pc(pc),
		.csr(csr_rdata),
		.alu_ctrl(alu_ctrl),
		.rs1_data(rs1_data),
		.rs2_data(rs2_data),
		.immval(imm),
		.alu_out(alu_out),
		.j_pc(j_pc)
	);

	LSU u_LSU (
		.lsu_en(lsu_en),
		.clk(clk),
		.wen(lsu_wen),
		.lsu_ctrl(lsu_ctrl),
		.wdata(rs2_data),
		.waddr(alu_out),

		.raddr(alu_out),
		.rdata(lsu_rdata),
		.ready_out(lsu_ready)
	);

	WBU u_WBU (
		.alu_out(alu_out),
		.mem_out(lsu_rdata),
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

