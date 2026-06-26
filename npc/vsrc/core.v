module core #(XLEN = 32) (
	input clk,
	input rst,

  	output mem_AWVALID,
	input mem_AWREADY,
	output [XLEN-1:0] mem_AWADDR,
	output [3:0] mem_AWID,
	output [7:0] mem_AWLEN,
	output [2:0] mem_AWSIZE,
	output [1:0] mem_AWBURST,

	output mem_WVALID,
	input mem_WREADY,
	output [XLEN-1:0] mem_WDATA,
	output [3:0] mem_WSTRB,
	output mem_WLAST,

	input mem_BVALID,
	output mem_BREADY,
	input [1:0] mem_BRESP,
	input [3:0] mem_BID,

	output mem_ARVALID,
	input mem_ARREADY,
	output [XLEN-1:0] mem_ARADDR,
	output [3:0] mem_ARID,
	output [7:0] mem_ARLEN,
	output [2:0] mem_ARSIZE,
	output [1:0] mem_ARBURST,

	input mem_RVALID,
	output mem_RREADY,
	input [XLEN-1:0] mem_RDATA,
	input [1:0] mem_RRESP,
	input mem_RLAST,
	input [3:0] mem_RID
);

import "DPI-C" function void npctrap(int a0, int c_pc);

wire ifu_AWVALID, ifu_AWREADY, ifu_WVALID, ifu_WREADY, 
ifu_BVALID, ifu_BREADY, ifu_ARVALID, ifu_ARREADY, ifu_RVALID,ifu_RREADY;
wire [XLEN-1:0] ifu_AWADDR, ifu_WDATA, ifu_ARADDR, ifu_RDATA;
wire [3:0] ifu_WSTRB;
wire [1:0] ifu_BRESP, ifu_RRESP;

wire ifu_WLAST, ifu_RLAST;
wire [3:0] ifu_AWID, ifu_ARID, ifu_BID, ifu_RID;
wire [7:0] ifu_AWLEN, ifu_ARLEN;
wire [2:0] ifu_AWSIZE, ifu_ARSIZE;
wire [1:0] ifu_AWBURST, ifu_ARBURST;

wire lsu_AWVALID, lsu_AWREADY, lsu_WVALID, lsu_WREADY, 
lsu_BVALID, lsu_BREADY, lsu_ARVALID, lsu_ARREADY, lsu_RVALID,lsu_RREADY;
wire [XLEN-1:0] lsu_AWADDR, lsu_WDATA, lsu_ARADDR, lsu_RDATA;
wire [3:0] lsu_WSTRB;
wire [1:0] lsu_BRESP, lsu_RRESP;

wire lsu_WLAST, lsu_RLAST;
wire [3:0] lsu_AWID, lsu_ARID, lsu_BID, lsu_RID;
wire [7:0] lsu_AWLEN, lsu_ARLEN;
wire [2:0] lsu_AWSIZE, lsu_ARSIZE;
wire [1:0] lsu_AWBURST, lsu_ARBURST;

wire clint_AWVALID, clint_AWREADY, clint_WVALID, clint_WREADY, 
clint_BVALID, clint_BREADY, clint_ARVALID, clint_ARREADY, clint_RVALID,clint_RREADY;
wire [XLEN-1:0] clint_AWADDR, clint_WDATA, clint_ARADDR, clint_RDATA;
wire [3:0] clint_WSTRB;
wire [1:0] clint_BRESP, clint_RRESP;

/*-----------------------------------------------*/
/*---------------IFU ICache----------------------*/
/*-----------------------------------------------*/
wire [XLEN-1:0] ifu_icache_raddr, icache_ifu_rdata;
wire ifu_icache_avalid, icache_ifu_aready, icache_ifu_rvalid, ifu_icache_rready;

/*-----------------------------------------------*/
/*----------------IFU IDU------------------------*/
/*-----------------------------------------------*/
wire if_id_valid, id_if_ready;
wire [XLEN-1:0] if_id_pc, if_id_inst;

	IFU u_IFU (
		.clk(clk),
		.rst(rst),

		.ex_if_jvalid(ex_if_jvalid),
		.if_ex_jready(if_ex_jready),
		.ex_if_jpc(ex_if_jpc),

		// .ready_npc_in(~idu_valid & lsu_ready),
		.if_id_valid(if_id_valid),
		.id_if_ready(id_if_ready),
		.if_id_pc(if_id_pc),
		.if_id_inst(if_id_inst),
		// .wb_valid(wb_valid),

		.raddr(ifu_icache_raddr),
		.avalid(ifu_icache_avalid),
		.aready(icache_ifu_aready),

		.rdata(icache_ifu_rdata),
		.rvalid(icache_ifu_rvalid),
		.rready(ifu_icache_rready)
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

/*-----------------------------------------------*/
/*----------------IDU EXU------------------------*/
/*-----------------------------------------------*/
wire id_ex_valid, ex_id_ready;
wire [XLEN-1:0] id_ex_pc;
wire [XLEN-1:0] id_ex_inst;

wire [3:0] id_ex_alu_ctrl;
wire [1:0] id_ex_alu_op_ctrl;
wire [XLEN-1:0] id_ex_imm;
wire [4:0] id_ex_rd;
wire [4:0] id_rf_rs1; // to rf
wire [4:0] id_rf_rs2; // to rf
wire [4:0] id_ex_rs1; // to ex
wire [4:0] id_ex_rs2; // to ex
wire [XLEN-1:0] id_ex_rs1_data;
wire [XLEN-1:0] id_ex_rs2_data;
wire id_ex_j_en;
wire [2:0] id_ex_j_cond;

wire id_ex_lsu_en, id_ex_lsu_wen;
wire [2:0] id_ex_lsu_ctrl;
wire [1:0] id_ex_csr_wctrl;

wire [2:0] id_ex_wb_ctrl;
wire id_ex_wb_en, id_ex_ebreak_flag;

wire id_ex_csr_exvalid;
wire [XLEN-1:0] id_ex_csr_cause;
wire id_ex_csr_wvalid;
wire [11:0] id_ex_csr_waddr;
wire [11:0] id_csr_raddr;

wire icache_flush;

	IDU u_IDU (
		.clk(clk),
		.rst(rst),
		
		.if_id_valid(if_id_valid),
		.id_if_ready(id_if_ready),
		.if_id_pc(if_id_pc),
		.if_id_inst(if_id_inst),

		.id_ex_valid(id_ex_valid),
		.ex_id_ready(ex_id_ready),
		.id_ex_pc(id_ex_pc),
		.id_ex_inst(id_ex_inst),

		.id_rf_rs1(id_rf_rs1),
		.id_rf_rs2(id_rf_rs2),
		.rf_id_rs1_data(rf_id_rs1_data),
		.rf_id_rs2_data(rf_id_rs2_data),

		.id_ex_alu_ctrl(id_ex_alu_ctrl),
		.id_ex_alu_op_ctrl(id_ex_alu_op_ctrl),
		.id_ex_imm(id_ex_imm),
		.id_ex_rd(id_ex_rd),
		.id_ex_rs1(id_ex_rs1),
		.id_ex_rs2(id_ex_rs2),
		.id_ex_rs1_data(id_ex_rs1_data),
		.id_ex_rs2_data(id_ex_rs2_data),
		.id_ex_j_en(id_ex_j_en),
		.id_ex_j_cond(id_ex_j_cond),
		.id_ex_csr_wctrl(id_ex_csr_wctrl),
		
		.id_ex_lsu_en(id_ex_lsu_en),
		.id_ex_lsu_wen(id_ex_lsu_wen),
		.id_ex_lsu_ctrl(id_ex_lsu_ctrl),

		.id_ex_wb_ctrl(id_ex_wb_ctrl),
		.id_ex_wb_en(id_ex_wb_en),
		.id_ex_ebreak_flag(id_ex_ebreak_flag),

		.id_ex_csr_exvalid(id_ex_csr_exvalid),
		.id_ex_csr_cause(id_ex_csr_cause),
		.id_ex_csr_wvalid(id_ex_csr_wvalid),
		.id_ex_csr_waddr(id_ex_csr_waddr),
		.id_csr_raddr(id_csr_raddr),
		// .icache_flush(icache_flush),

		// for data hazard
		.ex_ls_valid(ex_ls_valid),
		.ex_ls_rd(ex_ls_rd),
		.ex_ls_wb_ctrl(ex_ls_wb_ctrl),
		.ex_ls_data_out(ex_ls_data_out),
		.lsu_bussy(lsu_bussy),
		// .ls_wb_valid(ls_wb_valid),
		.ls_wb_rd(ls_wb_rd),
		// .ls_wb_ctrl(ls_wb_ctrl),
		// .ls_wb_rdata(ls_wb_rdata),
		.ex_ls_csr_wvalid(ex_ls_csr_wvalid),
		.ex_ls_csr_waddr(ex_ls_csr_waddr),
		.ls_wb_csr_wvalid(ls_wb_csr_wvalid),
		.ls_wb_csr_waddr(ls_wb_csr_waddr),

		.ex_glb_flush(ex_glb_flush)
	);
/*-----------------------------------------------*/
/*----------------register file------------------*/
/*-----------------------------------------------*/
wire wb_rf_valid, wb_rf_wen;
wire [4:0] wb_rf_rd;
wire [XLEN-1:0] wb_rf_data;

wire [XLEN-1:0] rf_id_rs1_data, rf_id_rs2_data;
	RegisterFile u_gpr (
		.clk(clk),
		.rst(rst),
		.en(wb_rf_valid),
		.wen(wb_rf_wen),
		.waddr(wb_rf_rd),
		.wdata(wb_rf_data),
		.raddr1(id_rf_rs1),
		.raddr2(id_rf_rs2),
		.rdata1(rf_id_rs1_data),
		.rdata2(rf_id_rs2_data)
	);
/*-----------------------------------------------*/
/*-------------------CSR-------------------------*/
/*-----------------------------------------------*/
wire wb_csr_valid;
wire [XLEN-1:0] wb_csr_cause;
wire [XLEN-1:0] wb_csr_pc;
wire wb_csr_wvalid;
wire [11:0] wb_csr_waddr;
wire [XLEN-1:0] wb_csr_wdata;
wire [XLEN-1:0] csr_rdata;
	CSR_group u_csr (
		.clk(clk),
		.rst(rst),
		.csr_exvalid(wb_csr_valid),
		.csr_cause(wb_csr_cause),
		.csr_pc(wb_csr_pc),
		.csr_wvalid(wb_csr_wvalid),
		.csr_waddr(wb_csr_waddr),
		.csr_wdata(wb_csr_wdata),
		.csr_raddr(id_csr_raddr),
		.csr_rdata(csr_rdata)
	);

/*-----------------------------------------------*/
/*----------------EXU LSU------------------------*/
/*-----------------------------------------------*/
wire ex_ls_valid, ls_ex_ready, ex_ls_en, ex_ls_wen;
wire [2:0] ex_ls_ctrl;
wire [XLEN-1:0] ex_ls_wdata, ex_ls_data_out, ex_ls_pc, ex_ls_npc, ex_ls_inst, ex_ls_imm, ex_if_jpc;
wire [4:0] ex_ls_rd;
wire [2:0] ex_ls_wb_ctrl;
wire ex_ls_wb_en, ex_ls_ebreak_flag;
wire ex_ls_csr_exvalid;
wire [XLEN-1:0] ex_ls_csr_cause;
wire ex_ls_csr_wvalid;
wire [11:0] ex_ls_csr_waddr;
wire [XLEN-1:0] ex_ls_csr_wdata;
wire ex_if_jvalid, if_ex_jready, ex_glb_flush;

	EXU u_EXU (
		.clk(clk),
		.rst(rst),
		.id_ex_valid(id_ex_valid),
		.ex_id_ready(ex_id_ready),
		.id_ex_pc(id_ex_pc),
		.id_ex_inst(id_ex_inst),

		.id_ex_alu_ctrl(id_ex_alu_ctrl),
		.id_ex_alu_op_ctrl(id_ex_alu_op_ctrl),
		.id_ex_imm(id_ex_imm),
		.id_ex_rd(id_ex_rd),
		.id_ex_rs1(id_ex_rs1),
		.id_ex_rs2(id_ex_rs2),
		.id_ex_rs1_data(id_ex_rs1_data),
		.id_ex_rs2_data(id_ex_rs2_data),
		.id_ex_j_en(id_ex_j_en),
		.id_ex_j_cond(id_ex_j_cond),
		.id_ex_csr_wctrl(id_ex_csr_wctrl),
		.csr_ex_data(csr_rdata),

		.id_ex_lsu_en(id_ex_lsu_en),
		.id_ex_lsu_wen(id_ex_lsu_wen),
		.id_ex_lsu_ctrl(id_ex_lsu_ctrl),
		.id_ex_wb_ctrl(id_ex_wb_ctrl),
		.id_ex_wb_en(id_ex_wb_en),
		.id_ex_ebreak_flag(id_ex_ebreak_flag),

		.id_ex_csr_exvalid(id_ex_csr_exvalid),
		.id_ex_csr_cause(id_ex_csr_cause),
		.id_ex_csr_wvalid(id_ex_csr_wvalid),
		.id_ex_csr_waddr(id_ex_csr_waddr),

		.ls_wb_valid(ls_wb_valid),
		.wb_rf_rd(wb_rf_rd),
		.wb_rf_data(wb_rf_data),

		.ex_ls_valid(ex_ls_valid),
		.ls_ex_ready(ls_ex_ready),
		.ex_ls_en(ex_ls_en),
		.ex_ls_wen(ex_ls_wen),
		.ex_ls_ctrl(ex_ls_ctrl),
		.ex_ls_wdata(ex_ls_wdata),
		.ex_ls_data_out(ex_ls_data_out),
		.ex_ls_pc(ex_ls_pc),
		.ex_ls_npc(ex_ls_npc),
		.ex_ls_inst(ex_ls_inst),
		.ex_ls_imm(ex_ls_imm),

		.ex_ls_rd(ex_ls_rd),
		.ex_ls_wb_ctrl(ex_ls_wb_ctrl),
		.ex_ls_wb_en(ex_ls_wb_en),
		.ex_ls_ebreak_flag(ex_ls_ebreak_flag),

		.ex_ls_csr_exvalid(ex_ls_csr_exvalid),
		.ex_ls_csr_cause(ex_ls_csr_cause),
		.ex_ls_csr_wvalid(ex_ls_csr_wvalid),
		.ex_ls_csr_waddr(ex_ls_csr_waddr),
		.ex_ls_csr_wdata(ex_ls_csr_wdata),

		.ex_if_jvalid(ex_if_jvalid),
		.if_ex_jready(if_ex_jready),
		.ex_if_jpc(ex_if_jpc),

		.ex_glb_flush(ex_glb_flush)
		
	);
/*-----------------------------------------------*/
/*-------------------LSU WBU---------------------*/
/*-----------------------------------------------*/
wire ls_wb_valid, ls_wb_ready;
wire [XLEN-1:0] ls_wb_pc, ls_wb_npc, ls_wb_inst, ls_wb_imm;
wire [4:0] ls_wb_rd;
wire [2:0] ls_wb_ctrl;
wire ls_wb_en, ls_wb_ebreak;
wire [XLEN-1:0] ls_wb_exu_data, ls_wb_rdata;
wire lsu_bussy;
wire ls_wb_csr_exvalid;
wire [XLEN-1:0] ls_wb_csr_cause;
wire ls_wb_csr_wvalid;
wire [11:0] ls_wb_csr_waddr;
wire [XLEN-1:0] ls_wb_csr_wdata;
	LSU u_LSU (
		.clk(clk),
		.rst(rst),

		.ex_ls_valid(ex_ls_valid),
		.ls_ex_ready(ls_ex_ready),
		.ex_ls_en(ex_ls_en),
		.ex_ls_wen(ex_ls_wen),
		.ex_ls_ctrl(ex_ls_ctrl),
		.ex_ls_wdata(ex_ls_wdata),
		.ex_ls_addr(ex_ls_data_out),
		.ex_ls_data(ex_ls_data_out),
		.ex_ls_pc(ex_ls_pc),
		.ex_ls_npc(ex_ls_npc),
		.ex_ls_inst(ex_ls_inst),
		.ex_ls_imm(ex_ls_imm),

		.ex_ls_wb_en(ex_ls_wb_en),
		.ex_ls_wb_ctrl(ex_ls_wb_ctrl),
		.ex_ls_rd(ex_ls_rd),
		.ex_ls_ebreak_flag(ex_ls_ebreak_flag),

		.ex_ls_csr_exvalid(ex_ls_csr_exvalid),
		.ex_ls_csr_cause(ex_ls_csr_cause),
		.ex_ls_csr_wvalid(ex_ls_csr_wvalid),
		.ex_ls_csr_waddr(ex_ls_csr_waddr),
		.ex_ls_csr_wdata(ex_ls_csr_wdata),

		.ls_wb_valid(ls_wb_valid),
		.ls_wb_ready(ls_wb_ready),
		.ls_wb_pc(ls_wb_pc),
		.ls_wb_npc(ls_wb_npc),
		.ls_wb_inst(ls_wb_inst),
		.ls_wb_imm(ls_wb_imm),
		.ls_wb_rd(ls_wb_rd),
		.ls_wb_ctrl(ls_wb_ctrl),
		.ls_wb_en(ls_wb_en),
		.ls_wb_ebreak(ls_wb_ebreak),
		.ls_wb_exu_data(ls_wb_exu_data),
		.ls_wb_rdata(ls_wb_rdata),
		.lsu_bussy(lsu_bussy),

		.ls_wb_csr_exvalid(ls_wb_csr_exvalid),
		.ls_wb_csr_cause(ls_wb_csr_cause),
		.ls_wb_csr_wvalid(ls_wb_csr_wvalid),
		.ls_wb_csr_waddr(ls_wb_csr_waddr),
		.ls_wb_csr_wdata(ls_wb_csr_wdata),

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
/*-----------------------------------------------*/
/*-------------------LSU WBU---------------------*/
/*-----------------------------------------------*/
wire ebreak_flag;
	WBU u_WBU (
		.clk(clk),
		.rst(rst),
		.ls_wb_valid(ls_wb_valid),
		.ls_wb_ready(ls_wb_ready),
		.ls_wb_pc(ls_wb_pc),
		.ls_wb_npc(ls_wb_npc),
		.ls_wb_inst(ls_wb_inst),
		.ls_wb_imm(ls_wb_imm),
		.ls_wb_rd(ls_wb_rd),
		.ls_wb_ctrl(ls_wb_ctrl),
		.ls_wb_en(ls_wb_en),
		.ls_wb_ebreak(ls_wb_ebreak),
		.ls_wb_exu_data(ls_wb_exu_data),
		.ls_wb_rdata(ls_wb_rdata),

		.ls_wb_csr_exvalid(ls_wb_csr_exvalid),
		.ls_wb_csr_cause(ls_wb_csr_cause),
		.ls_wb_csr_wvalid(ls_wb_csr_wvalid),
		.ls_wb_csr_waddr(ls_wb_csr_waddr),
		.ls_wb_csr_wdata(ls_wb_csr_wdata),

		.wb_rf_valid(wb_rf_valid),
		.wb_rf_wen(wb_rf_wen),
		.wb_rf_rd(wb_rf_rd),
		.wb_rf_data(wb_rf_data),

		.wb_csr_exvalid(wb_csr_valid),
		.wb_csr_cause(wb_csr_cause),
		.wb_csr_pc(wb_csr_pc),
		.wb_csr_wvalid(wb_csr_wvalid),
		.wb_csr_waddr(wb_csr_waddr),
		.wb_csr_wdata(wb_csr_wdata),
		
		.ebreak_flag(ebreak_flag)
	);
	
always @(*) begin
	if(ebreak_flag)
		npctrap(u_gpr.rf[10], ls_wb_pc);
end
`ifndef CONFIG_TARGET_SOC

wire uart_AWVALID, uart_AWREADY, uart_WVALID, uart_WREADY, 
uart_BVALID, uart_BREADY, uart_ARVALID, uart_ARREADY, uart_RVALID,uart_RREADY;
wire [XLEN-1:0] uart_AWADDR, uart_WDATA, uart_ARADDR, uart_RDATA;
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

