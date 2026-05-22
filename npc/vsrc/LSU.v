module LSU #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input clk,
	input rst,
	input exu_lsu_en,
	input exu_lsu_wen,
	input [2:0] exu_lsu_ctrl,
	input [DATA_WIDTH-1:0] exu_lsu_wdata,
	input [ADDR_WIDTH-1:0] exu_lsu_addr,
	output reg [DATA_WIDTH-1:0] rdata,
	output ready_out,

	output AWVALID,
	input AWREADY,
	output [ADDR_WIDTH-1:0] AWADDR,
	output [3:0] AWID,
	output [7:0] AWLEN,
	output [2:0] AWSIZE,
	output [1:0] AWBURST,

	output WVALID,
	input WREADY,
	output [DATA_WIDTH-1:0] WDATA,
	output [3:0] WSTRB,
	output WLAST,

	input BVALID,
	output BREADY,
	input [1:0] BRESP,
	input [3:0] BID,

	output ARVALID,
	input ARREADY,
	output [ADDR_WIDTH-1:0] ARADDR,
	output [3:0] ARID,
	output [7:0] ARLEN,
	output reg [2:0] ARSIZE,
	output [1:0] ARBURST,

	input RVALID,
	output RREADY,
	input [DATA_WIDTH-1:0] RDATA,
	input [1:0] RRESP,
	input RLAST,
	input [3:0] RID
);
import "DPI-C" function void AXI_Access_Falt(); 
import "DPI-C" function void performance_counter(int category);
localparam WIDLE = 2'b0, ASHAK=2'b01, DSHAK=2'b10, WWAIT = 2'b11;
localparam IDLE = 1'b0, WAIT = 1'b1;

assign AWID = 0;
assign AWLEN = 0;
assign AWBURST = 0;
assign ARID = 0;
assign ARLEN = 0;
assign ARBURST = 0;

assign ready_out = (rstate==WAIT & R_handshaked & wstate==WIDLE) |  // read finished
	(wstate==WWAIT & B_handshaked & rstate==IDLE) | // write finished
	((rstate==IDLE & ~ARVALID) & (wstate==WIDLE & ~AWVALID & ~WVALID));// no mem request

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
/*--------Write control---------*/
reg wreq;
reg [3:0] wstrb;
reg [3:0] wstrb_r;
reg [2:0] awsize;
reg [2:0] awsize_r;
reg [DATA_WIDTH-1:0] mem_wdata;
reg [DATA_WIDTH-1:0] mem_wdata_r;
reg [ADDR_WIDTH-1:0] waddr_r;
assign AWVALID = ((exu_lsu_en & exu_lsu_wen) | wreq) & (wstate==WIDLE | wstate==DSHAK);
assign WVALID = ((exu_lsu_en & exu_lsu_wen) | wreq) & (wstate==WIDLE | wstate==ASHAK);
assign WLAST = WVALID;
assign WDATA = (exu_lsu_en & exu_lsu_wen) ? mem_wdata : mem_wdata_r;
assign WSTRB = (exu_lsu_en & exu_lsu_wen) ? wstrb : wstrb_r;
assign AWSIZE = (exu_lsu_en & exu_lsu_wen) ? awsize : awsize_r;
assign AWADDR = (exu_lsu_en & exu_lsu_wen) ? exu_lsu_addr : waddr_r;
assign BREADY = wstate==WWAIT & BVALID;


always @(*) begin //decode for wdata
	if(exu_lsu_en&exu_lsu_wen) begin
		case (exu_lsu_ctrl)
			3'b000: begin
				awsize = 3'b0;
				case (exu_lsu_addr[1:0])
				2'b00: begin
					wstrb = 4'b1;
					mem_wdata = exu_lsu_wdata;
				end
				2'b01: begin
					wstrb = 4'b10;
					mem_wdata = exu_lsu_wdata<<8;
				end
				2'b10: begin
					wstrb = 4'b100;
					mem_wdata = exu_lsu_wdata<<16;
				end
				2'b11: begin
					wstrb = 4'b1000;
					mem_wdata = exu_lsu_wdata<<24;
				end
				endcase
			end
			3'b001: begin
				awsize = 3'b1;
				case (exu_lsu_addr[1:0])
				2'b00: begin
					wstrb = 4'b11;
					mem_wdata = exu_lsu_wdata;
				end
				2'b01: begin
					$finish;
				end
				2'b10: begin
					wstrb = 4'b1100;
					mem_wdata = exu_lsu_wdata<<16;
				end
				2'b11: begin
					$finish;
				end
				endcase
			end
			3'b010: begin
				awsize = 3'b10;
				if(exu_lsu_addr[1:0]!=2'b00)
					$finish;
				wstrb = 4'b1111;
				mem_wdata = exu_lsu_wdata;
			end
			default: $finish;
		endcase
	end
end
// latch message for write
always @(posedge clk) begin
	if (rst) begin
		wstrb_r <= 0;
		awsize_r <= 3'b10;
		waddr_r <= 0;
		mem_wdata_r <= 0;
		wreq <= 0;
	end
	else if (exu_lsu_en & exu_lsu_wen) begin // save(latch) the message
		wstrb_r <= wstrb;
		awsize_r <= awsize;
		waddr_r <= exu_lsu_addr;
		mem_wdata_r <= mem_wdata;
		wreq <= 1;
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
		wreq <= 0;
		if(BRESP != 0)
			AXI_Access_Falt();
	end
end

/*--------read control---------*/
reg rreq;
reg [2:0] rlsu_ctrl_r;
reg [ADDR_WIDTH-1:0] raddr_r;
wire [2:0] arsize = exu_lsu_ctrl==3'b010 ? 3'b10 : (exu_lsu_ctrl[0] ? 3'b1 : 3'b0);
reg [2:0] arsize_r;
assign ARVALID = (exu_lsu_en & ~exu_lsu_wen) | rreq & rstate==IDLE;
assign ARADDR = (exu_lsu_en & ~exu_lsu_wen) ? exu_lsu_addr : raddr_r;
assign ARSIZE = (exu_lsu_en & ~exu_lsu_wen) ? arsize : arsize_r;
assign RREADY = rstate==WAIT & RVALID;

always @(posedge clk) begin
	if (rst) begin
		rlsu_ctrl_r <= 0;
		raddr_r <= 0;
		rreq <= 0;
		arsize_r <= 3'b10;
	end
	else if (exu_lsu_en & rstate==IDLE & ~exu_lsu_wen) begin
		rlsu_ctrl_r <= exu_lsu_ctrl;
		arsize_r <= arsize;
		raddr_r <= exu_lsu_addr;
		rreq <= 1;
	end
	if (R_handshaked) begin
		performance_counter(2);
		arsize_r <= 3'b10;
		rlsu_ctrl_r <= 0;
		raddr_r <= 0;		
		rreq <= 0;
		if(RRESP != 0)
			AXI_Access_Falt();
	end
end

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


endmodule
