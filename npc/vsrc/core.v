module core #(INST_WIDTH = 32, DATA_WIDTH = 32) (
	input clk,
	input rst,

  	output mem_AWVALID,
	input mem_AWREADY,
	output [DATA_WIDTH-1:0] mem_AWADDR,
	output [3:0] mem_AWID,
	output [7:0] mem_AWLEN,
	output [2:0] mem_AWSIZE,
	output [1:0] mem_AWBURST,

	output mem_WVALID,
	input mem_WREADY,
	output [DATA_WIDTH-1:0] mem_WDATA,
	output [3:0] mem_WSTRB,
	output mem_WLAST,

	input mem_BVALID,
	output mem_BREADY,
	input [1:0] mem_BRESP,
	input [3:0] mem_BID,

	output mem_ARVALID,
	input mem_ARREADY,
	output [DATA_WIDTH-1:0] mem_ARADDR,
	output [3:0] mem_ARID,
	output [7:0] mem_ARLEN,
	output [2:0] mem_ARSIZE,
	output [1:0] mem_ARBURST,

	input mem_RVALID,
	output mem_RREADY,
	input [DATA_WIDTH-1:0] mem_RDATA,
	input [1:0] mem_RRESP,
	input mem_RLAST,
	input [3:0] mem_RID
);

import "DPI-C" function void npctrap(int a0, int c_pc);

wire j_pc, j_en, wb_en, ebreak_flag, inst_valid, lsu_en, lsu_wen, csr_wen, lsu_ready, wb_valid;
wire [INST_WIDTH-1:0] pc;
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

wire uart_AWVALID, uart_AWREADY, uart_WVALID, uart_WREADY, 
uart_BVALID, uart_BREADY, uart_ARVALID, uart_ARREADY, uart_RVALID,uart_RREADY;
wire [DATA_WIDTH-1:0] uart_AWADDR, uart_WDATA, uart_ARADDR, uart_RDATA;
wire [3:0] uart_WSTRB;
wire [1:0] uart_BRESP, uart_RRESP;

wire clint_AWVALID, clint_AWREADY, clint_WVALID, clint_WREADY, 
clint_BVALID, clint_BREADY, clint_ARVALID, clint_ARREADY, clint_RVALID,clint_RREADY;
wire [DATA_WIDTH-1:0] clint_AWADDR, clint_WDATA, clint_ARADDR, clint_RDATA;
wire [3:0] clint_WSTRB;
wire [1:0] clint_BRESP, clint_RRESP;

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
		.mem_AWID(mem_AWID),
		.mem_AWLEN(mem_AWLEN),
		.mem_AWSIZE(mem_AWSIZE),
		.mem_AWBURST(mem_AWBURST),

		.mem_WVALID(mem_WVALID),
		.mem_WREADY(mem_WREADY),
		.mem_WDATA(mem_WDATA),
		.mem_WSTRB(mem_WSTRB),
		.mem_WLAST(mem_WLAST),

		.mem_BVALID(mem_BVALID),
		.mem_BREADY(mem_BREADY),
		.mem_BRESP(mem_BRESP),
		.mem_BID(mem_BID),

		.mem_ARVALID(mem_ARVALID),
		.mem_ARREADY(mem_ARREADY),
		.mem_ARADDR(mem_ARADDR),
		.mem_ARID(mem_ARID),
		.mem_ARLEN(mem_ARLEN),
		.mem_ARSIZE(mem_ARSIZE),
		.mem_ARBURST(mem_ARBURST),

		.mem_RVALID(mem_RVALID),
		.mem_RREADY(mem_RREADY),
		.mem_RDATA(mem_RDATA),
		.mem_RRESP(mem_RRESP),
		.mem_RLAST(mem_RLAST),
		.mem_RID(mem_RID),

		// uart
		.uart_AWVALID(uart_AWVALID),
		.uart_AWREADY(uart_AWREADY),
		.uart_AWADDR(uart_AWADDR),

		.uart_WVALID(uart_WVALID),
		.uart_WREADY(uart_WREADY),
		.uart_WDATA(uart_WDATA),
		.uart_WSTRB(uart_WSTRB),

		.uart_BVALID(uart_BVALID),
		.uart_BREADY(uart_BREADY),
		.uart_BRESP(uart_BRESP),

		.uart_ARVALID(uart_ARVALID),
		.uart_ARREADY(uart_ARREADY),
		.uart_ARADDR(uart_ARADDR),

		.uart_RVALID(uart_RVALID),
		.uart_RREADY(uart_RREADY),
		.uart_RDATA(uart_RDATA),
		.uart_RRESP(uart_RRESP),

		// clint
		.clint_AWVALID(clint_AWVALID),
		.clint_AWREADY(clint_AWREADY),
		.clint_AWADDR(clint_AWADDR),

		.clint_WVALID(clint_WVALID),
		.clint_WREADY(clint_WREADY),
		.clint_WDATA(clint_WDATA),
		.clint_WSTRB(clint_WSTRB),

		.clint_BVALID(clint_BVALID),
		.clint_BREADY(clint_BREADY),
		.clint_BRESP(clint_BRESP),

		.clint_ARVALID(clint_ARVALID),
		.clint_ARREADY(clint_ARREADY),
		.clint_ARADDR(clint_ARADDR),

		.clint_RVALID(clint_RVALID),
		.clint_RREADY(clint_RREADY),
		.clint_RDATA(clint_RDATA),
		.clint_RRESP(clint_RRESP)
	);

	UART u_uart (
		.clk(clk),
		.rst(rst),

		.AWVALID(uart_AWVALID),
		.AWREADY(uart_AWREADY),
		.AWADDR(uart_AWADDR),

		.WVALID(uart_WVALID),
		.WREADY(uart_WREADY),
		.WDATA(uart_WDATA),
		.WSTRB(uart_WSTRB),

		.BVALID(uart_BVALID),
		.BREADY(uart_BREADY),
		.BRESP(uart_BRESP),

		.ARVALID(uart_ARVALID),
		.ARREADY(uart_ARREADY),
		.ARADDR(uart_ARADDR),

		.RVALID(uart_RVALID),
		.RREADY(uart_RREADY),
		.RDATA(uart_RDATA),
		.RRESP(uart_RRESP)
	);

	CLINT u_clint (
		.clk(clk),
		.rst(rst),

		.AWVALID(clint_AWVALID),
		.AWREADY(clint_AWREADY),
		.AWADDR(clint_AWADDR),

		.WVALID(clint_WVALID),
		.WREADY(clint_WREADY),
		.WDATA(clint_WDATA),
		.WSTRB(clint_WSTRB),

		.BVALID(clint_BVALID),
		.BREADY(clint_BREADY),
		.BRESP(clint_BRESP),

		.ARVALID(clint_ARVALID),
		.ARREADY(clint_ARREADY),
		.ARADDR(clint_ARADDR),

		.RVALID(clint_RVALID),
		.RREADY(clint_RREADY),
		.RDATA(clint_RDATA),
		.RRESP(clint_RRESP)
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
		npctrap(u_gpr.rf[10], pc);
end

endmodule

