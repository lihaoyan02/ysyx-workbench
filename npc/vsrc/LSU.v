module LSU #(XLEN = 32) (
	input clk,
	input rst,
	input ex_ls_valid,
	output ls_ex_ready,
	input ex_ls_en,
	input ex_ls_wen,
	input [2:0] ex_ls_ctrl,
	input [XLEN-1:0] ex_ls_wdata,
	input [XLEN-1:0] ex_ls_addr,
	input [XLEN-1:0] ex_ls_data,
	input [XLEN-1:0] ex_ls_pc,
	input [XLNE-1:0] ex_ls_inst,
	input [XLNE-1:0] ex_ls_imm,

	input ex_ls_wb_en,
	input [2:0] ex_ls_wb_ctrl,
	input [4:0] ex_ls_rd,
	input ex_ls_ebreak_flag,

	output ls_wb_valid,
	input ls_wb_ready,
	output [XLEN-1:0] ls_wb_pc,
	output [XLNE-1:0] ls_wb_inst,
	output [XLNE-1:0] ls_wb_imm,
	output [4:0] ls_wb_rd,
	output [2:0] ls_wb_ctrl,
	output ls_wb_en,
	output ls_wb_ebreak,
	output [XLEN-1:0] ls_wb_exu_data,
	output [XLEN-1:0] ls_wb_rdata,
	// output ready_out,

	output AWVALID,
	input AWREADY,
	output [XLEN-1:0] AWADDR,
	output [3:0] AWID,
	output [7:0] AWLEN,
	output [2:0] AWSIZE,
	output [1:0] AWBURST,

	output WVALID,
	input WREADY,
	output [XLEN-1:0] WDATA,
	output [3:0] WSTRB,
	output WLAST,

	input BVALID,
	output BREADY,
	input [1:0] BRESP,
	input [3:0] BID,

	output ARVALID,
	input ARREADY,
	output [XLEN-1:0] ARADDR,
	output [3:0] ARID,
	output [7:0] ARLEN,
	output reg [2:0] ARSIZE,
	output [1:0] ARBURST,

	input RVALID,
	output RREADY,
	input [XLEN-1:0] RDATA,
	input [1:0] RRESP,
	input RLAST,
	input [3:0] RID
);
import "DPI-C" function void AXI_Access_Falt(); 
import "DPI-C" function void performance_counter(int category);
/*------------------------output-----------------------------*/
assign ls_ex_ready = (wstate==WIDLE) & (rstate==IDLE) & (bus_awvalid==0)& (bus_arvalid==0);
assign ls_wb_valid = lsu_valid;
assign ls_wb_pc = lsu_pc;
assign ls_wb_inst = lsu_inst;
assign ls_wb_imm = lsu_imm;
assign ls_wb_rd = lsu_rd;
assign ls_wb_ctrl = lsu_wbu_ctrl;
assign ls_wb_en = lsu_wbu_en;
assign ls_wb_ebreak = lsu_wbu_ebreak;
assign ls_wb_exu_data = exu_data;
assign ls_wb_rdata = lsu_rdata;
/*-----------------sequential logic for output-----------------*/
reg lsu_valid;
always @(posedge clk) begin
	if (rst) begin
		lsu_valid <= 0;
	end
	else if (ex_ls_valid & ls_ex_ready) begin
		if (!ex_ls_en) begin
			lsu_valid <= 1;
		end
	end
	else if (B_handshaked) begin
		lsu_valid <= 1;
	end
	else if (R_handshaked) begin
		lsu_valid <= 1;
	end
	else if (ls_wb_valid & ls_wb_ready) begin
		lsu_valid <= 0;
	end
end

reg [4:0] lsu_rd;
reg [2:0] lsu_wbu_ctrl;
reg lsu_wbu_en, lsu_wbu_ebreak;
reg [XLEN-1:0] lsu_pc, lsu_inst, lsu_imm, exu_data, lsu_rdata;
always @(posedge clk) begin
	if (rst) begin
		lsu_wbu_en <= 0;
		lsu_wbu_ctrl <= 0;
		lsu_pc <= 0;
		lsu_inst <= 0;
		lsu_imm <= 0;
		exu_data <= 0;
		lsu_rdata <= 0;
		lsu_rd <= 0;
		lsu_wbu_ebreak <= 0;
	end
	else if (ls_wb_valid & ls_wb_ready) begin
		lsu_wbu_en <= ex_ls_wb_en;
		lsu_wbu_ctrl <= ex_ls_wb_ctrl;
		lsu_pc <= ex_ls_pc;
		lsu_inst <= ex_ls_inst;
		lsu_imm <= ex_ls_imm;
		exu_data <= ex_ls_data;
		lsu_rdata <= rdata;
		lsu_rd <= ex_ls_rd;
		lsu_wbu_ebreak <= ex_ls_ebreak_flag;
	end
	else if (R_handshaked) begin
		lsu_rdata <= rdata;
	end
end

localparam WIDLE = 2'b0, ASHAK=2'b01, DSHAK=2'b10, WWAIT = 2'b11;
localparam IDLE = 1'b0, WAIT = 1'b1;

assign AWID = 0;
assign AWLEN = 0;
assign AWBURST = 0;
assign ARID = 0;
assign ARLEN = 0;
assign ARBURST = 0;

// assign ready_out = (rstate==WAIT & R_handshaked & wstate==WIDLE) |  // read finished
// 	(wstate==WWAIT & B_handshaked & rstate==IDLE) | // write finished
// 	((rstate==IDLE & ~ARVALID) & (wstate==WIDLE & ~AWVALID & ~WVALID));// no mem request

wire AW_handshaked, W_handshaked, AR_handshaked, R_handshaked, B_handshaked;
assign AW_handshaked = AWVALID & AWREADY;
assign W_handshaked = WVALID & WREADY;
assign AR_handshaked = ARVALID & ARREADY;
assign R_handshaked = RVALID & RREADY;
assign B_handshaked = BVALID & BREADY;

/*--------Write state machine---------*/
reg [1:0] wstate;
reg [1:0] next_wstate;
always @(posedge clk) begin
	if (rst)
		wstate <= WIDLE;
	else
		wstate <= next_wstate;
end
always @(*) begin
	case (wstate)
		WIDLE: begin
			next_wstate =  AW_handshaked ? (W_handshaked ? WWAIT : ASHAK) : (W_handshaked ? DSHAK : WIDLE);
		end
		ASHAK: next_wstate = W_handshaked ? WWAIT : ASHAK;
		DSHAK: next_wstate = AW_handshaked ? WWAIT : DSHAK;
		WWAIT: begin
			next_wstate = B_handshaked ? WIDLE : WWAIT;
		end
	endcase
end

/*--------Read state machine---------*/
reg rstate;
reg next_rstate;
always @(posedge clk) begin
	if (rst)
		rstate <= IDLE;
	else
		rstate <= next_rstate;
end
always @(*) begin
	case (rstate)
		IDLE: begin
			next_rstate =  AR_handshaked ? WAIT : IDLE;
		end
		WAIT: begin
			next_rstate = R_handshaked ? IDLE : WAIT;
		end
	endcase
end
/*-------------------------------------Write control------------------------------------*/
reg [3:0] wstrb;
reg [3:0] wstrb_r;
reg [2:0] awsize;
reg [2:0] awsize_r;
reg [XLEN-1:0] mem_wdata;
reg [XLEN-1:0] mem_wdata_r;
reg [XLEN-1:0] waddr_r;
assign AWVALID = bus_awvalid & (wstate==WIDLE | wstate==DSHAK);
assign WVALID = bus_wvalid & (wstate==WIDLE | wstate==ASHAK);
assign WLAST = WVALID;
assign WDATA = mem_wdata_r;
assign WSTRB = wstrb_r;
assign AWSIZE = awsize_r;
assign AWADDR = waddr_r;
assign BREADY = wstate==WWAIT & BVALID;


always @(*) begin //decode for wdata
	if(ex_ls_valid & ex_ls_en & ex_ls_wen) begin
		case (ex_ls_ctrl)
			3'b000: begin
				awsize = 3'b0;
				case (ex_ls_addr[1:0])
				2'b00: begin
					wstrb = 4'b1;
					mem_wdata = ex_ls_wdata;
				end
				2'b01: begin
					wstrb = 4'b10;
					mem_wdata = ex_ls_wdata<<8;
				end
				2'b10: begin
					wstrb = 4'b100;
					mem_wdata = ex_ls_wdata<<16;
				end
				2'b11: begin
					wstrb = 4'b1000;
					mem_wdata = ex_ls_wdata<<24;
				end
				endcase
			end
			3'b001: begin
				awsize = 3'b1;
				case (ex_ls_addr[1:0])
				2'b00: begin
					wstrb = 4'b11;
					mem_wdata = ex_ls_wdata;
				end
				2'b01: begin
					$finish;
				end
				2'b10: begin
					wstrb = 4'b1100;
					mem_wdata = ex_ls_wdata<<16;
				end
				2'b11: begin
					$finish;
				end
				endcase
			end
			3'b010: begin
				awsize = 3'b10;
				if(ex_ls_addr[1:0]!=2'b00)
					$finish;
				wstrb = 4'b1111;
				mem_wdata = ex_ls_wdata;
			end
			default: $finish;
		endcase
	end
end
/*------------------sequential logic for write-----------------------*/
reg bus_awvalid, bus_wvalid;
always @(posedge clk) begin
	if (rst) begin
		bus_awvalid <= 0;
		bus_wvalid <= 0;
	end
	else if (ex_ls_valid & ls_ex_ready & ex_ls_en & ex_ls_wen) begin
		bus_awvalid <= 1;
		bus_wvalid <= 1;
	end
	else begin
		if (AW_handshaked) begin
			bus_awvalid <= 0;
		end
		if (W_handshaked) begin
			bus_wvalid <= 0;
		end
	end
end

always @(posedge clk) begin
	if (rst) begin
		wstrb_r <= 0;
		awsize_r <= 3'b10;
		waddr_r <= 0;
		mem_wdata_r <= 0;
	end
	else if (ex_ls_valid & ls_ex_ready) begin // save(latch) the message
		wstrb_r <= wstrb;
		awsize_r <= awsize;
		waddr_r <= ex_ls_addr;
		mem_wdata_r <= mem_wdata;
	end
	if (AW_handshaked) begin
		waddr_r <= 0;
		awsize_r <= 3'b10;
	end
	if (W_handshaked) begin
		wstrb_r <= 0;
		mem_wdata_r <= 0;
	end
	else if (B_handshaked) begin	
		performance_counter(7);
		if(BRESP != 0)
			AXI_Access_Falt();
	end
end

/*--------------------------------read control-------------------------------------*/
reg rreq;
reg [2:0] rlsu_ctrl_r;
reg [XLEN-1:0] raddr_r;
wire [2:0] arsize = (ex_ls_ctrl==3'b010) ? 3'b10 : (ex_ls_ctrl[0] ? 3'b1 : 3'b0);
reg [2:0] arsize_r;
reg [XLEN-1:0] rdata;
assign ARVALID = bus_arvalid & rstate==IDLE;
assign ARADDR = raddr_r;
assign ARSIZE = arsize_r;
assign RREADY = rstate==WAIT & RVALID;

always @(*) begin
	rdata = 32'b0;
	if (R_handshaked) begin // write enable : store data
		case (rlsu_ctrl_r)
			3'b100: begin
				case (raddr_r[1:0])
					2'b00: rdata = {24'b0, RDATA[7:0]};
					2'b01: rdata = {24'b0, RDATA[15:8]};
					2'b10: rdata = {24'b0, RDATA[23:16]};
					2'b11: rdata = {24'b0, RDATA[31:24]}; 
				endcase
			end
			3'b000: begin
				case (raddr_r[1:0])
					2'b00: rdata = {{24{RDATA[7]}}, RDATA[7:0]};
					2'b01: rdata = {{24{RDATA[15]}}, RDATA[15:8]};
					2'b10: rdata = {{24{RDATA[23]}}, RDATA[23:16]};
					2'b11: rdata = {{24{RDATA[31]}}, RDATA[31:24]}; 
				endcase
			end
			3'b010: begin //lw
				case (raddr_r[1:0])
					2'b00: rdata = RDATA;
					2'b01: $finish;
					2'b10: $finish;
					2'b11: $finish;
				endcase
			end
			3'b101: begin //lhu 
				case (raddr_r[1:0])
					2'b00: rdata = {16'b0, RDATA[15:0]};
					2'b01: $finish;
					2'b10: rdata = {16'b0, RDATA[31:16]};
					2'b11: $finish;
				endcase
			end
			3'b001: begin //lh 
				case (raddr_r[1:0])
					2'b00: rdata = {{16{RDATA[15]}}, RDATA[15:0]};
					2'b01: $finish;
					2'b10: rdata = {{16{RDATA[31]}}, RDATA[31:16]};
					2'b11: $finish;
				endcase
			end
			default: $finish;
		endcase
	end
end

/*-------------------------sequential logic for read------------------------*/
reg bus_arvalid;
always @(posedge clk) begin
	if (rst) begin
		bus_arvalid <= 0;
	end
	else if (ex_ls_valid & ls_ex_ready & ex_ls_en & ~ex_ls_wen) begin
		bus_arvalid <= 1;
	end
	else begin
		if (AR_handshaked) begin
			bus_arvalid <= 0;
		end
	end
end

always @(posedge clk) begin
	if (rst) begin
		rlsu_ctrl_r <= 0;
		raddr_r <= 0;
		arsize_r <= 3'b10;
	end
	else if (ex_ls_valid & ls_ex_ready) begin
		rlsu_ctrl_r <= ex_ls_ctrl;
		arsize_r <= arsize;
		raddr_r <= ex_ls_addr;
	end
	if (R_handshaked) begin
		performance_counter(2);
		rlsu_ctrl_r <= 0;
		arsize_r <= 3'b10;
		raddr_r <= 0;
		if(RRESP != 0)
			AXI_Access_Falt();
	end
end

endmodule
