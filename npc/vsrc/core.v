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

wire exu_j_pc, j_en, wb_en, ebreak_flag, inst_valid, lsu_en, lsu_wen, csr_wen, lsu_ready, wb_valid;
wire [INST_WIDTH-1:0] pc;
wire [DATA_WIDTH-1:0] exu_out;
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

wire exu_lsu_en;
wire exu_lsu_wen;
wire [2:0] exu_lsu_ctrl;

wire [DATA_WIDTH-1:0] wb_data;
wire [DATA_WIDTH-1:0] rs1_data;
wire [DATA_WIDTH-1:0] rs2_data;
wire [DATA_WIDTH-1:0] exu_lsu_wdata;

wire exu_valid;

wire [DATA_WIDTH-1:0] csr_rdata;
wire [11:0] csr_addr;
wire csr_event;

wire ifu_AWVALID, ifu_AWREADY, ifu_WVALID, ifu_WREADY, 
ifu_BVALID, ifu_BREADY, ifu_ARVALID, ifu_ARREADY, ifu_RVALID,ifu_RREADY;
wire [DATA_WIDTH-1:0] ifu_AWADDR, ifu_WDATA, ifu_ARADDR, ifu_RDATA;
wire [3:0] ifu_WSTRB;
wire [1:0] ifu_BRESP, ifu_RRESP;

wire ifu_WLAST, ifu_RLAST;
wire [3:0] ifu_AWID, ifu_ARID, ifu_BID, ifu_RID;
wire [7:0] ifu_AWLEN, ifu_ARLEN;
wire [2:0] ifu_AWSIZE, ifu_ARSIZE;
wire [1:0] ifu_AWBURST, ifu_ARBURST;

wire lsu_AWVALID, lsu_AWREADY, lsu_WVALID, lsu_WREADY, 
lsu_BVALID, lsu_BREADY, lsu_ARVALID, lsu_ARREADY, lsu_RVALID,lsu_RREADY;
wire [DATA_WIDTH-1:0] lsu_AWADDR, lsu_WDATA, lsu_ARADDR, lsu_RDATA;
wire [3:0] lsu_WSTRB;
wire [1:0] lsu_BRESP, lsu_RRESP;

wire lsu_WLAST, lsu_RLAST;
wire [3:0] lsu_AWID, lsu_ARID, lsu_BID, lsu_RID;
wire [7:0] lsu_AWLEN, lsu_ARLEN;
wire [2:0] lsu_AWSIZE, lsu_ARSIZE;
wire [1:0] lsu_AWBURST, lsu_ARBURST;

wire clint_AWVALID, clint_AWREADY, clint_WVALID, clint_WREADY, 
clint_BVALID, clint_BREADY, clint_ARVALID, clint_ARREADY, clint_RVALID,clint_RREADY;
wire [DATA_WIDTH-1:0] clint_AWADDR, clint_WDATA, clint_ARADDR, clint_RDATA;
wire [3:0] clint_WSTRB;
wire [1:0] clint_BRESP, clint_RRESP;

// ifu_icache signal
wire [DATA_WIDTH-1:0] ifu_icache_raddr, icache_ifu_rdata;
wire ifu_icache_avalid, icache_ifu_aready, icache_ifu_rvalid, ifu_icache_rready;

wire icache_flush;
	IFU u_IFU (
		.clk(clk),
		.rst(rst),
		.exu_j_pc(exu_j_pc),
		.j_pc_addr(exu_out),
		.ready_npc_in(~idu_valid & lsu_ready),
		.pc(pc),
		.inst_valid(inst_valid),
		.inst_fetch(inst_fetch),
		.wb_valid(wb_valid),

		.raddr(ifu_icache_raddr),
		.avalid(ifu_icache_avalid),
		.aready(icache_ifu_aready),

		.rdata(icache_ifu_rdata),
		.rvalid(icache_ifu_rvalid),
		.rready(ifu_icache_rready)

		// .AWVALID(ifu_AWVALID),
		// .AWREADY(ifu_AWREADY),
		// .AWADDR(ifu_AWADDR),

		// .WVALID(ifu_WVALID),
		// .WREADY(ifu_WREADY),
		// .WDATA(ifu_WDATA),
		// .WSTRB(ifu_WSTRB),

		// .BVALID(ifu_BVALID),
		// .BREADY(ifu_BREADY),
		// .BRESP(ifu_BRESP),

		// .ARVALID(ifu_ARVALID),
		// .ARREADY(ifu_ARREADY),
		// .ARADDR(ifu_ARADDR),

		// .RVALID(ifu_RVALID),
		// .RREADY(ifu_RREADY),
		// .RDATA(ifu_RDATA),
		// .RRESP(ifu_RRESP)
	);

	icache u_icache (
		.clk(clk),
		.rst(rst),
		
		.raddr(ifu_icache_raddr),
		.avalid(ifu_icache_avalid),
		.aready(icache_ifu_aready),
		.rdata(icache_ifu_rdata),
		.rvalid(icache_ifu_rvalid),
		.rready(ifu_icache_rready),
		.icache_flush(icache_flush),

		.AWVALID(ifu_AWVALID),
		.AWREADY(ifu_AWREADY),
		.AWADDR(ifu_AWADDR),
		.AWID(ifu_AWID),
		.AWLEN(ifu_AWLEN),
		.AWSIZE(ifu_AWSIZE),
		.AWBURST(ifu_AWBURST),

		.WVALID(ifu_WVALID),
		.WREADY(ifu_WREADY),
		.WDATA(ifu_WDATA),
		.WSTRB(ifu_WSTRB),
		.WLAST(ifu_WLAST),

		.BVALID(ifu_BVALID),
		.BREADY(ifu_BREADY),
		.BRESP(ifu_BRESP),
		.BID(ifu_BID),

		.ARVALID(ifu_ARVALID),
		.ARREADY(ifu_ARREADY),
		.ARADDR(ifu_ARADDR),
		.ARID(ifu_ARID),
		.ARLEN(ifu_ARLEN),
		.ARSIZE(ifu_ARSIZE),
		.ARBURST(ifu_ARBURST),

		.RVALID(ifu_RVALID),
		.RREADY(ifu_RREADY),
		.RDATA(ifu_RDATA),
		.RRESP(ifu_RRESP),
		.RLAST(ifu_RLAST),
		.RID(ifu_RID)
	);

	wire idu_valid;
	IDU u_IDU (
		.clk(clk),
		.rst(rst),
		.inst_fetch(inst_fetch),
		.inst_valid(inst_valid),
		.idu_valid(idu_valid),
		.idu_imm(imm),
		.idu_rd(rd),
		.idu_rs1(rs1),
		.idu_rs2(rs2),
		.idu_alu_ctrl(alu_ctrl),
		.idu_alu_op_ctrl(alu_op_ctrl),
		.idu_wb_ctrl(wb_ctrl),
		.idu_wb_en(wb_en),
		.idu_lsu_en(lsu_en),
		.idu_lsu_wen(lsu_wen),
		.idu_lsu_ctrl(lsu_ctrl),
		.idu_ebreak_flag(ebreak_flag),
		.idu_j_en(j_en),
		.idu_j_cond(j_cond),
		.icache_flush(icache_flush),
		.idu_csr_wen(csr_wen),
		.idu_csr_event(csr_event),
		.idu_csr_addr(csr_addr)
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
		.clk(clk),
		.rst(rst),
		.idu_valid(idu_valid),
		.idu_alu_op_ctrl(alu_op_ctrl),
		.idu_alu_ctrl(alu_ctrl),
		.idu_j_en(j_en),
		.idu_j_cond(j_cond),
		.pc(pc),
		.csr(csr_rdata),
		.rs1_data(rs1_data),
		.rs2_data(rs2_data),
		.idu_imm(imm),
		.idu_lsu_en(lsu_en),
		.idu_lsu_wen(lsu_wen),
		.idu_lsu_ctrl(lsu_ctrl),
		.exu_lsu_en(exu_lsu_en),
		.exu_lsu_wen(exu_lsu_wen),
		.exu_lsu_ctrl(exu_lsu_ctrl),
		.exu_lsu_wdata(exu_lsu_wdata),
		.exu_valid(exu_valid),
		.exu_out(exu_out),
		.exu_j_pc(exu_j_pc)
	);

	LSU u_LSU (
		.clk(clk),
		.rst(rst),
		.exu_lsu_en(exu_lsu_en),
		.exu_lsu_wen(exu_lsu_wen),
		.exu_lsu_ctrl(exu_lsu_ctrl),
		.exu_lsu_addr(exu_out),
		.exu_lsu_wdata(exu_lsu_wdata),
		.rdata(lsu_rdata),
		.ready_out(lsu_ready),

		.AWVALID(lsu_AWVALID),
		.AWREADY(lsu_AWREADY),
		.AWADDR(lsu_AWADDR),
		.AWID(lsu_AWID),
		.AWLEN(lsu_AWLEN),
		.AWSIZE(lsu_AWSIZE),
		.AWBURST(lsu_AWBURST),

		.WVALID(lsu_WVALID),
		.WREADY(lsu_WREADY),
		.WDATA(lsu_WDATA),
		.WSTRB(lsu_WSTRB),
		.WLAST(lsu_WLAST),

		.BVALID(lsu_BVALID),
		.BREADY(lsu_BREADY),
		.BRESP(lsu_BRESP),
		.BID(lsu_BID),

		.ARVALID(lsu_ARVALID),
		.ARREADY(lsu_ARREADY),
		.ARADDR(lsu_ARADDR),
		.ARID(lsu_ARID),
		.ARLEN(lsu_ARLEN),
		.ARSIZE(lsu_ARSIZE),
		.ARBURST(lsu_ARBURST),

		.RVALID(lsu_RVALID),
		.RREADY(lsu_RREADY),
		.RDATA(lsu_RDATA),
		.RRESP(lsu_RRESP),
		.RLAST(lsu_RLAST),
		.RID(lsu_RID)
	);

	WBU u_WBU (
		.exu_out(exu_out),
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
`ifndef CONFIG_TARGET_SOC

wire uart_AWVALID, uart_AWREADY, uart_WVALID, uart_WREADY, 
uart_BVALID, uart_BREADY, uart_ARVALID, uart_ARREADY, uart_RVALID,uart_RREADY;
wire [DATA_WIDTH-1:0] uart_AWADDR, uart_WDATA, uart_ARADDR, uart_RDATA;
wire [3:0] uart_WSTRB;
wire [1:0] uart_BRESP, uart_RRESP;

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
`else
	Xbar_2x2 u_Xbar_2x2(
		.clk(clk),
		.rst(rst),
		.m1_AWVALID(ifu_AWVALID),
		.m1_AWREADY(ifu_AWREADY),
		.m1_AWADDR(ifu_AWADDR),
		.m1_AWID(ifu_AWID),
		.m1_AWLEN(ifu_AWLEN),
		.m1_AWSIZE(ifu_AWSIZE),
		.m1_AWBURST(ifu_AWBURST),

		.m1_WVALID(ifu_WVALID),
		.m1_WREADY(ifu_WREADY),
		.m1_WDATA(ifu_WDATA),
		.m1_WSTRB(ifu_WSTRB),
		.m1_WLAST(ifu_WLAST),

		.m1_BVALID(ifu_BVALID),
		.m1_BREADY(ifu_BREADY),
		.m1_BRESP(ifu_BRESP),
		.m1_BID(ifu_BID),

		.m1_ARVALID(ifu_ARVALID),
		.m1_ARREADY(ifu_ARREADY),
		.m1_ARADDR(ifu_ARADDR),
		.m1_ARID(ifu_ARID),
		.m1_ARLEN(ifu_ARLEN),
		.m1_ARSIZE(ifu_ARSIZE),
		.m1_ARBURST(ifu_ARBURST),

		.m1_RVALID(ifu_RVALID),
		.m1_RREADY(ifu_RREADY),
		.m1_RDATA(ifu_RDATA),
		.m1_RRESP(ifu_RRESP),
		.m1_RLAST(ifu_RLAST),
		.m1_RID(ifu_RID),
		//lsu
		.m2_AWVALID(lsu_AWVALID),
		.m2_AWREADY(lsu_AWREADY),
		.m2_AWADDR(lsu_AWADDR),
		.m2_AWID(lsu_AWID),
		.m2_AWLEN(lsu_AWLEN),
		.m2_AWSIZE(lsu_AWSIZE),
		.m2_AWBURST(lsu_AWBURST),

		.m2_WVALID(lsu_WVALID),
		.m2_WREADY(lsu_WREADY),
		.m2_WDATA(lsu_WDATA),
		.m2_WSTRB(lsu_WSTRB),
		.m2_WLAST(lsu_WLAST),

		.m2_BVALID(lsu_BVALID),
		.m2_BREADY(lsu_BREADY),
		.m2_BRESP(lsu_BRESP),
		.m2_BID(lsu_BID),

		.m2_ARVALID(lsu_ARVALID),
		.m2_ARREADY(lsu_ARREADY),
		.m2_ARADDR(lsu_ARADDR),
		.m2_ARID(lsu_ARID),
		.m2_ARLEN(lsu_ARLEN),
		.m2_ARSIZE(lsu_ARSIZE),
		.m2_ARBURST(lsu_ARBURST),

		.m2_RVALID(lsu_RVALID),
		.m2_RREADY(lsu_RREADY),
		.m2_RDATA(lsu_RDATA),
		.m2_RRESP(lsu_RRESP),
		.m2_RLAST(lsu_RLAST),
		.m2_RID(lsu_RID),
		// mem
		.s1_AWVALID(mem_AWVALID),
		.s1_AWREADY(mem_AWREADY),
		.s1_AWADDR(mem_AWADDR),
		.s1_AWID(mem_AWID),
		.s1_AWLEN(mem_AWLEN),
		.s1_AWSIZE(mem_AWSIZE),
		.s1_AWBURST(mem_AWBURST),

		.s1_WVALID(mem_WVALID),
		.s1_WREADY(mem_WREADY),
		.s1_WDATA(mem_WDATA),
		.s1_WSTRB(mem_WSTRB),
		.s1_WLAST(mem_WLAST),

		.s1_BVALID(mem_BVALID),
		.s1_BREADY(mem_BREADY),
		.s1_BRESP(mem_BRESP),
		.s1_BID(mem_BID),

		.s1_ARVALID(mem_ARVALID),
		.s1_ARREADY(mem_ARREADY),
		.s1_ARADDR(mem_ARADDR),
		.s1_ARID(mem_ARID),
		.s1_ARLEN(mem_ARLEN),
		.s1_ARSIZE(mem_ARSIZE),
		.s1_ARBURST(mem_ARBURST),

		.s1_RVALID(mem_RVALID),
		.s1_RREADY(mem_RREADY),
		.s1_RDATA(mem_RDATA),
		.s1_RRESP(mem_RRESP),
		.s1_RLAST(mem_RLAST),
		.s1_RID(mem_RID),

		// uart
		.s2_AWVALID(clint_AWVALID),
		.s2_AWREADY(clint_AWREADY),
		.s2_AWADDR(clint_AWADDR),

		.s2_WVALID(clint_WVALID),
		.s2_WREADY(clint_WREADY),
		.s2_WDATA(clint_WDATA),
		.s2_WSTRB(clint_WSTRB),

		.s2_BVALID(clint_BVALID),
		.s2_BREADY(clint_BREADY),
		.s2_BRESP(clint_BRESP),

		.s2_ARVALID(clint_ARVALID),
		.s2_ARREADY(clint_ARREADY),
		.s2_ARADDR(clint_ARADDR),

		.s2_RVALID(clint_RVALID),
		.s2_RREADY(clint_RREADY),
		.s2_RDATA(clint_RDATA),
		.s2_RRESP(clint_RRESP)
	);
`endif

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
	

endmodule

