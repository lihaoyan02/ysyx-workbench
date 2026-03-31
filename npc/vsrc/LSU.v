module LSU #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input lsu_en,
	input clk,
	input rst,
	input wen,
	input [2:0] lsu_ctrl,
	input [DATA_WIDTH-1:0] wdata,
	input [ADDR_WIDTH-1:0] addr,
	output reg [DATA_WIDTH-1:0] rdata,
	output ready_out,

	output AWVALID,
	input AWREADY,
	output [ADDR_WIDTH-1:0] AWADDR,

	output WVALID,
	input WREADY,
	output [DATA_WIDTH-1:0] WDATA,
	output [3:0] WSTRB,

	input BVALID,
	output BREADY,
	input [1:0] BRESP,

	output ARVALID,
	input ARREADY,
	output [ADDR_WIDTH-1:0] ARADDR,

	input RVALID,
	output RREADY,
	input [DATA_WIDTH-1:0] RDATA,
	input [1:0] RRESP

	// output mem_wen,
	// output [DATA_WIDTH-1:0] mem_wdata,
	// output [3:0] mem_wmask,
	// input respValid,
	// output reg respReady,
	// input [DATA_WIDTH-1:0] mem_rdata
);

// reg state, next_state;
localparam WIDLE = 2'b0, ASHAK=2'b01, DSHAK=2'b10, WWAIT = 2'b11;
localparam IDLE = 1'b0, WAIT = 1'b1;
//assign ready_out = (state==WAIT & resp_handshaked) | (state==IDLE & ~reqValid);

assign ready_out = (rstate==WAIT & R_handshaked & wstate==WIDLE) | 
	(wstate==WWAIT & W_handshaked & rstate==IDLE) |
	((rstate==IDLE & ~ARVALID) & (wstate==WIDLE & ~AWVALID & ~WVALID));
wire AW_handshaked, W_handshaked, AR_handshaked, R_handshaked, B_handshaked;
assign AW_handshaked = AWVALID & AWREADY;
assign W_handshaked = WVALID & WREADY;
assign AR_handshaked = ARVALID & ARREADY;
assign R_handshaked = RVALID & RREADY;
assign B_handshaked = BVALID & BREADY;

// assign req_handshaked = reqValid & reqReady;
// assign resp_handshaked = respValid & respReady;
// assign respReady = respValid & state==WAIT;
// reg [2:0] shiftval;
// always @(posedge clk) begin
// 	if (rst) begin
// 		respReady <= 0;
// 		shiftval <= 0;
// 	end
// 	else if (respValid) begin
// 		shiftval <= {1'b1,shiftval[2:1]};
// 		respReady <= shiftval[0];
// 	end
// 	else if (resp_handshaked) begin
// 		respReady <= 0;
// 		shiftval <= 0;
// 	end
// end
reg [1:0] wstate;
reg [1:0] next_wstate;
reg rstate;
reg next_rstate;
always @(posedge clk) begin
	if (rst) begin
		wstate <= WIDLE;
		rstate <= IDLE;
	end
	else begin
		wstate <= next_wstate;
		rstate <= next_rstate;
	end
end

/*--------Write state machine---------*/
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

reg [2:0] rlsu_ctrl_r;
reg [3:0] wstrb_r;
reg [ADDR_WIDTH-1:0] raddr_r;
reg [ADDR_WIDTH-1:0] waddr_r;
reg [1:0] addr2_r;
reg [DATA_WIDTH-1:0] wdata_r;
reg wreq, rreq;
reg [3:0] mem_wmask;
reg [DATA_WIDTH-1:0] mem_wdata;
always @(posedge clk) begin
	if (rst) begin
		rlsu_ctrl_r <= 0;
		wstrb_r <= 0;
		raddr_r <= 0;
		waddr_r <= 0;
		addr2_r <= 0;
		wdata_r <= 0;
		wreq <= 0;
		rreq <= 0;
	end
	else if (lsu_en & rstate==IDLE & ~wen) begin
		rlsu_ctrl_r <= lsu_ctrl;
		raddr_r <= addr;
		addr2_r <= addr[1:0];
		rreq <= 1;
	end
	else if (lsu_en & wen) begin
		wstrb_r <= mem_wmask;
		waddr_r <= addr;
		wdata_r <= mem_wdata;
		wreq <= 1;
	end
	if (AW_handshaked) begin
		waddr_r <= 0;
	end
	if (W_handshaked) begin
		wstrb_r <= 0;
		wdata_r <= 0;
	end
	if (AR_handshaked) begin
		raddr_r <= 0;
	end
	if (R_handshaked) begin
		rlsu_ctrl_r <= 0;
		addr2_r <= 0;
		rreq <= 0;
	end
	else if (B_handshaked) begin	
		wreq <= 0;
	end
end
assign AWVALID = (lsu_en & wen) | wreq & (wstate==WIDLE | wstate==DSHAK);
assign ARVALID = (lsu_en & ~wen) | rreq & rstate==IDLE;
assign WVALID = (lsu_en & wen) | wreq & (wstate==WIDLE | wstate==ASHAK);
assign WDATA = (lsu_en & wen) ? mem_wdata : wdata_r;
assign WSTRB = (lsu_en & wen) ? mem_wmask : wstrb_r;
assign AWADDR = (lsu_en & wen) ? addr : waddr_r;
assign ARADDR = (lsu_en & ~wen) ? addr : raddr_r;
assign BREADY = wstate==WWAIT & BVALID;
assign RREADY = rstate==WAIT & RVALID;

// reg lsu_en_vld, wen_vld;
// reg [ADDR_WIDTH-1:0] addr_vld;
// reg [2:0] lsu_ctrl_vld;

// reg [2:0] mem_lsu_ctrl;
// assign reqValid = lsu_en|lsu_en_vld & (state==IDLE);
// always @(posedge clk) begin
// 	if (rst) begin
// 		lsu_en_vld <= 0;
// 		addr_vld <= 0;
// 		wen_vld <= 0;
// 		lsu_ctrl_vld <= 0;
// 	end
// 	else if(lsu_en & (state==IDLE) & ~reqReady) begin
// 		lsu_en_vld <= lsu_en;
// 		addr_vld <= addr;
// 		wen_vld <= wen;
// 		lsu_ctrl_vld <= lsu_ctrl;
// 	end
// 	else if(req_handshaked) begin
// 		lsu_en_vld <= 0;
// 		addr_vld <= 0;
// 		wen_vld <= 0;
// 		lsu_ctrl_vld <= 0;
// 	end
// end

reg [DATA_WIDTH-1:0] rdata_word;
// reg [DATA_WIDTH-1:0] rdata_word_n;
// assign mem_wen = wen_vld | wen;
assign rdata_word = RDATA;
// assign mem_addr = addr_vld | addr;
// assign mem_lsu_ctrl = lsu_ctrl_vld | lsu_ctrl;

always @(*) begin
	if(lsu_en&wen) begin
		case (lsu_ctrl)
			3'b000: begin
				case (addr[1:0])
				2'b00: begin
					mem_wmask = 4'b1;
					mem_wdata = wdata;
				end
				2'b01: begin
					mem_wmask = 4'b10;
					mem_wdata = wdata<<8;
				end
				2'b10: begin
					mem_wmask = 4'b100;
					mem_wdata = wdata<<16;
				end
				2'b11: begin
					mem_wmask = 4'b1000;
					mem_wdata = wdata<<24;
				end
				endcase
			end
			3'b001: begin
				case (addr[1:0])
				2'b00: begin
					mem_wmask = 4'b11;
					mem_wdata = wdata;
				end
				2'b01: begin
					$finish;
				end
				2'b10: begin
					mem_wmask = 4'b1100;
					mem_wdata = wdata<<16;
				end
				2'b11: begin
					$finish;
				end
				endcase
			end
			3'b010: begin
				if(addr[1:0]!=2'b00)
					$finish;
				mem_wmask = 4'b1111;
				mem_wdata = wdata;
			end
			default: $finish;
		endcase
	end
end

// reg [2:0] lsu_ctrl_r;
// reg [1:0] addr2_r;
// reg wen_r;

// always @(posedge clk) begin //latch the info
// 	if (rst) begin
// 		lsu_ctrl_r <= 0;
// 		wen_r <= 0;
// 		addr2_r <= 0;
// 	end
// 	else if (reqValid & state==IDLE) begin
// 		lsu_ctrl_r <= mem_lsu_ctrl;
// 		wen_r <= mem_wen;
// 		addr2_r <= mem_addr[1:0];
// 	end
// end
always @(*) begin
	rdata = 32'b0;
	if (R_handshaked) begin // write enable : store data
		case (rlsu_ctrl_r)
			3'b100: begin
				case (addr2_r)
					2'b00: rdata = {24'b0, rdata_word[7:0]};
					2'b01: rdata = {24'b0, rdata_word[15:8]};
					2'b10: rdata = {24'b0, rdata_word[23:16]};
					2'b11: rdata = {24'b0, rdata_word[31:24]}; 
				endcase
			end
			3'b000: begin
				case (addr2_r)
					2'b00: rdata = {{24{rdata_word[7]}}, rdata_word[7:0]};
					2'b01: rdata = {{24{rdata_word[15]}}, rdata_word[15:8]};
					2'b10: rdata = {{24{rdata_word[23]}}, rdata_word[23:16]};
					2'b11: rdata = {{24{rdata_word[31]}}, rdata_word[31:24]}; 
				endcase
			end
			3'b010: begin //lw
				case (addr2_r)
					2'b00: rdata = rdata_word;
					2'b01: $finish;
					2'b10: $finish;
					2'b11: $finish;
				endcase
			end
			3'b101: begin //lhu 
				case (addr2_r)
					2'b00: rdata = {16'b0, rdata_word[15:0]};
					2'b01: $finish;
					2'b10: rdata = {16'b0, rdata_word[31:16]};
					2'b11: $finish;
				endcase
			end
			3'b001: begin //lh 
				case (addr2_r)
					2'b00: rdata = {{16{rdata_word[15]}}, rdata_word[15:0]};
					2'b01: $finish;
					2'b10: rdata = {{16{rdata_word[31]}}, rdata_word[31:16]};
					2'b11: $finish;
				endcase
			end
			default: $finish;
		endcase
	end
end


endmodule
