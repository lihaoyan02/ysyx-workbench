module top #(INST_WIDTH = 32, DATA_WIDTH = 32) (
	input clk,
	input rst,
  output [INST_WIDTH-1:0] pc
);

import "DPI-C" function void npctrap(int a0);

wire j_pc, j_en, wb_en, ebreak_flag, inst_valid, lsu_en, lsu_wen, csr_wen, lsu_ready, wb_valid;
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

wire ifu_AWVALID, ifu_AWREADY, ifu_WVALID, ifu_WREADY, 
ifu_BVALID, ifu_BREADY, ifu_ARVALID, ifu_ARREADY, ifu_RVALID,ifu_RREADY;
wire [DATA_WIDTH-1:0] ifu_AWADDR, ifu_WDATA, ifu_ARADDR, ifu_RDATA;
wire [3:0] ifu_WSTRB;
wire [1:0] ifu_BRESP, ifu_RRESP;

wire lsu_AWVALID, lsu_AWREADY, lsu_WVALID, lsu_WREADY, 
lsu_BVALID, lsu_BREADY, lsu_ARVALID, lsu_ARREADY, lsu_RVALID,lsu_RREADY;
wire [DATA_WIDTH-1:0] lsu_AWADDR, lsu_WDATA, lsu_ARADDR, lsu_RDATA;
wire [3:0] lsu_WSTRB;
wire [1:0] lsu_BRESP, lsu_RRESP;

wire mem_AWVALID, mem_AWREADY, mem_WVALID, mem_WREADY, 
mem_BVALID, mem_BREADY, mem_ARVALID, mem_ARREADY, mem_RVALID,mem_RREADY;
wire [DATA_WIDTH-1:0] mem_AWADDR, mem_WDATA, mem_ARADDR, mem_RDATA;
wire [3:0] mem_WSTRB;
wire [1:0] mem_BRESP, mem_RRESP;

	IFU u_IFU (
		.clk(clk),
		.rst(rst),
		.j_pc(j_pc),
		.j_pc_addr(alu_out),
		.ready_in(lsu_ready),
		.pc(pc),
		.inst_valid(inst_valid),
		.inst_fetch(inst_fetch),
		.wb_valid(wb_valid),

		.AWVALID(ifu_AWVALID),
		.AWREADY(ifu_AWREADY),
		.AWADDR(ifu_AWADDR),

		.WVALID(ifu_WVALID),
		.WREADY(ifu_WREADY),
		.WDATA(ifu_WDATA),
		.WSTRB(ifu_WSTRB),

		.BVALID(ifu_BVALID),
		.BREADY(ifu_BREADY),
		.BRESP(ifu_BRESP),

		.ARVALID(ifu_ARVALID),
		.ARREADY(ifu_ARREADY),
		.ARADDR(ifu_ARADDR),

		.RVALID(ifu_RVALID),
		.RREADY(ifu_RREADY),
		.RDATA(ifu_RDATA),
		.RRESP(ifu_RRESP)
	);


	IDU u_IDU (
		.inst_fetch(inst_fetch),
		.inst_valid(inst_valid),
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
		.en(wb_valid),
		.wen(wb_en),
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
		.rst(rst),
		.wen(lsu_wen),
		.lsu_ctrl(lsu_ctrl),
		.wdata(rs2_data),
		.addr(alu_out),
		.rdata(lsu_rdata),
		.ready_out(lsu_ready),

		.AWVALID(lsu_AWVALID),
		.AWREADY(lsu_AWREADY),
		.AWADDR(lsu_AWADDR),

		.WVALID(lsu_WVALID),
		.WREADY(lsu_WREADY),
		.WDATA(lsu_WDATA),
		.WSTRB(lsu_WSTRB),

		.BVALID(lsu_BVALID),
		.BREADY(lsu_BREADY),
		.BRESP(lsu_BRESP),

		.ARVALID(lsu_ARVALID),
		.ARREADY(lsu_ARREADY),
		.ARADDR(lsu_ARADDR),

		.RVALID(lsu_RVALID),
		.RREADY(lsu_RREADY),
		.RDATA(lsu_RDATA),
		.RRESP(lsu_RRESP)
	);

	arbiter u_arbiter(
		.clk(clk),
		.rst(rst),
		.ifu_AWVALID(ifu_AWVALID),
		.ifu_AWREADY(ifu_AWREADY),
		.ifu_AWADDR(ifu_AWADDR),

		.ifu_WVALID(ifu_WVALID),
		.ifu_WREADY(ifu_WREADY),
		.ifu_WDATA(ifu_WDATA),
		.ifu_WSTRB(ifu_WSTRB),

		.ifu_BVALID(ifu_BVALID),
		.ifu_BREADY(ifu_BREADY),
		.ifu_BRESP(ifu_BRESP),

		.ifu_ARVALID(ifu_ARVALID),
		.ifu_ARREADY(ifu_ARREADY),
		.ifu_ARADDR(ifu_ARADDR),

		.ifu_RVALID(ifu_RVALID),
		.ifu_RREADY(ifu_RREADY),
		.ifu_RDATA(ifu_RDATA),
		.ifu_RRESP(ifu_RRESP),
		//lsu
		.lsu_AWVALID(lsu_AWVALID),
		.lsu_AWREADY(lsu_AWREADY),
		.lsu_AWADDR(lsu_AWADDR),

		.lsu_WVALID(lsu_WVALID),
		.lsu_WREADY(lsu_WREADY),
		.lsu_WDATA(lsu_WDATA),
		.lsu_WSTRB(lsu_WSTRB),

		.lsu_BVALID(lsu_BVALID),
		.lsu_BREADY(lsu_BREADY),
		.lsu_BRESP(lsu_BRESP),

		.lsu_ARVALID(lsu_ARVALID),
		.lsu_ARREADY(lsu_ARREADY),
		.lsu_ARADDR(lsu_ARADDR),

		.lsu_RVALID(lsu_RVALID),
		.lsu_RREADY(lsu_RREADY),
		.lsu_RDATA(lsu_RDATA),
		.lsu_RRESP(lsu_RRESP),
		// mem
		.mem_AWVALID(mem_AWVALID),
		.mem_AWREADY(mem_AWREADY),
		.mem_AWADDR(mem_AWADDR),

		.mem_WVALID(mem_WVALID),
		.mem_WREADY(mem_WREADY),
		.mem_WDATA(mem_WDATA),
		.mem_WSTRB(mem_WSTRB),

		.mem_BVALID(mem_BVALID),
		.mem_BREADY(mem_BREADY),
		.mem_BRESP(mem_BRESP),

		.mem_ARVALID(mem_ARVALID),
		.mem_ARREADY(mem_ARREADY),
		.mem_ARADDR(mem_ARADDR),

		.mem_RVALID(mem_RVALID),
		.mem_RREADY(mem_RREADY),
		.mem_RDATA(mem_RDATA),
		.mem_RRESP(mem_RRESP)
	);

	MEM u_mem (
		.clk(clk),
		.rst(rst),

		.AWVALID(mem_AWVALID),
		.AWREADY(mem_AWREADY),
		.AWADDR(mem_AWADDR),

		.WVALID(mem_WVALID),
		.WREADY(mem_WREADY),
		.WDATA(mem_WDATA),
		.WSTRB(mem_WSTRB),

		.BVALID(mem_BVALID),
		.BREADY(mem_BREADY),
		.BRESP(mem_BRESP),

		.ARVALID(mem_ARVALID),
		.ARREADY(mem_ARREADY),
		.ARADDR(mem_ARADDR),

		.RVALID(mem_RVALID),
		.RREADY(mem_RREADY),
		.RDATA(mem_RDATA),
		.RRESP(mem_RRESP)
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

