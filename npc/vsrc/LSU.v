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

	output reqValid,
	input reqReady,
	output [ADDR_WIDTH-1:0] mem_addr,
	output mem_wen,
	output [DATA_WIDTH-1:0] mem_wdata,
	output [3:0] mem_wmask,
	input respValid,
	input [DATA_WIDTH-1:0] mem_rdata
);

reg state, next_state;
localparam IDLE = 1'b0, WAIT = 1'b1;

assign ready_out = (state==WAIT & respValid) | (state==IDLE & ~reqValid);
wire req_handshaked;
assign req_handshaked = reqValid & reqReady;
always @(posedge clk) begin
	if (rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	case (state)
		IDLE: begin
			next_state =  req_handshaked ? WAIT : IDLE;
		end
		WAIT: begin
			next_state = respValid ? IDLE : WAIT;
		end
	endcase
end

reg lsu_en_r;
assign reqValid = lsu_en|lsu_en_r & (state==IDLE);
always @(posedge clk) begin
	if (rst)
		lsu_en_r <= 0;
	else if(lsu_en & (state==IDLE) & ~reqReady)
		lsu_en_r <= lsu_en;
	else if(req_handshaked)
		lsu_en_r <= 0;
end

reg [DATA_WIDTH-1:0] rdata_word;
reg [DATA_WIDTH-1:0] rdata_word_n;
//assign mem_wen = wen;
assign rdata_word = mem_rdata;
//assign mem_addr = addr;

always @(*) begin
	if(lsu_en&wen) begin
		mem_addr = addr;
		mem_wen = wen;
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
					mem_wmask = 4'b110;
					mem_wdata = wdata<<8;
				end
				2'b10: begin
					mem_wmask = 4'b1100;
					mem_wdata = wdata<<16;
				end
				2'b11: begin
					$finish;
					// mem_wmask = 4'b1000;
					// mem_wdata = wdata<<24;
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

reg [2:0] lsu_ctrl_r;
reg [1:0] addr_r;
reg wen_r;

always @(posedge clk) begin //latch the info
	if (rst) begin
		lsu_ctrl_r <= 0;
		wen_r <= 0;
		addr_r <= 0;
	end
	else if (reqValid & state==IDLE) begin
		lsu_ctrl_r <= lsu_ctrl;
		wen_r <= wen;
		addr_r <= addr[1:0];
	end
end
always @(*) begin
	rdata = 32'b0;
	if (respValid & ~wen_r) begin // write enable : store data
		case (lsu_ctrl_r)
			3'b100: rdata = addr_r==2'b00 ? {24'b0, rdata_word[7:0]} :
											addr_r==2'b01 ? {24'b0, rdata_word[15:8]} :
											addr_r==2'b10 ? {24'b0, rdata_word[23:16]} :
											addr_r==2'b11 ? {24'b0, rdata_word[31:24]} : 32'b0; //lbu 
			3'b000: rdata = addr_r==2'b00 ? {{24{rdata_word[7]}}, rdata_word[7:0]} :
											addr_r==2'b01 ? {{24{rdata_word[15]}}, rdata_word[15:8]} :
											addr_r==2'b10 ? {{24{rdata_word[23]}}, rdata_word[23:16]} :
											addr_r==2'b11 ? {{24{rdata_word[31]}}, rdata_word[31:24]} : 32'b0; //lb 
			3'b010: begin //lw
				rdata = addr_r==2'b00 ? rdata_word : 
								addr_r==2'b01 ? {rdata_word_n[7:0], rdata_word[31:8]} :
								addr_r==2'b10 ? {rdata_word_n[15:0], rdata_word[31:16]} :
								addr_r==2'b11 ? {rdata_word_n[23:0], rdata_word[31:24]} : 32'b0;
			end
			3'b101: begin //lhu 
				rdata = addr_r==2'b00 ? {16'b0, rdata_word[15:0]} :
								addr_r==2'b01 ? {16'b0, rdata_word[23:8]} :
								addr_r==2'b10 ? {16'b0, rdata_word[31:16]} :
								addr_r==2'b11 ? {16'b0, rdata_word_n[7:0], rdata_word[31:24]} : 32'b0;  
			end
			3'b001: begin //lh 
				rdata = addr_r==2'b00 ? {{16{rdata_word[15]}}, rdata_word[15:0]} :
								addr_r==2'b01 ? {{16{rdata_word[23]}}, rdata_word[23:8]} :
								addr_r==2'b10 ? {{16{rdata_word[31]}}, rdata_word[31:16]} :
								addr_r==2'b11 ? {{16{rdata_word_n[7]}},rdata_word_n[7:0], rdata_word[31:24]} : 32'b0;  
			end
			default: $finish;
		endcase
	end
end


endmodule
