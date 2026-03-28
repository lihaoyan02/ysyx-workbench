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
	output [ADDR_WIDTH-1:0] mem_addr,
	output mem_wen,
	output [DATA_WIDTH-1:0] mem_wdata,
	output [3:0] mem_wmask,
	input respValid,
	input [DATA_WIDTH-1:0] mem_rdata
);
//import "DPI-C" function int pmem_read(int raddr);
//import "DPI-C" function void pmem_write(int waddr, int wdata, byte wmask);

reg state, next_state;
localparam IDLE = 1'b0, WAIT = 1'b1;

assign ready_out = (state==WAIT & respValid) | (state==IDLE & ~reqValid);

always @(posedge clk) begin
	if (rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	case (state)
		IDLE: begin
			next_state =  reqValid ? WAIT : IDLE;
		end
		WAIT: begin
			next_state = respValid ? IDLE : WAIT;
		end
	endcase
end

assign reqValid = lsu_en & (state==IDLE);

reg [DATA_WIDTH-1:0] rdata_word;
reg [DATA_WIDTH-1:0] rdata_word_n;
//reg read_out;

//assign reqValid = lsu_en&ready_r;
assign mem_wen = wen;
assign rdata_word = mem_rdata;
assign mem_addr = addr;
// reg ready_r;
// always @(posedge clk) begin
// 	if (lsu_en & ~wen) begin
// 		ready_r <= 0;
// 	end
// 	else if (respValid) begin
// 		ready_r <= 1;
// 	end
// 	else
// 		ready_r <= 1;
// end
// assign ready_out = ~((lsu_en & ~wen) | ~ready_r) | respValid;

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
/*
always @(posedge clk) begin
	if(lsu_en) begin
		if (wen) begin // write enable : store data
			case (lsu_ctrl)
				3'b000: begin //sb
					case (addr[1:0])
						2'b00: pmem_write(addr, wdata, 8'b1); 
						2'b01: pmem_write(addr, wdata<<8, 8'b10); 
						2'b10: pmem_write(addr, wdata<<16, 8'b100); 
						2'b11: pmem_write(addr, wdata<<24, 8'b1000); 
					endcase
				end
				3'b001: begin //sj
					case (addr[1:0])
						2'b00: pmem_write(addr, wdata, 8'b11); 
						2'b01: pmem_write(addr, wdata<<8, 8'b110); 
						2'b10: pmem_write(addr, wdata<<16, 8'b1100); 
						2'b11: begin
							pmem_write(addr, wdata<<24, 8'b1000); 
							pmem_write(addr, wdata>>8, 8'b0001); 
						end
					endcase
				end
				3'b010: begin //sw
					case (addr[1:0])
						2'b00: pmem_write(addr, wdata, 8'b1111); 
						2'b01: begin
							pmem_write(addr, wdata<<8, 8'b1110); 
							pmem_write(addr, wdata>>24, 8'b0001); 
						end
						2'b10: begin
							pmem_write(addr, wdata<<16, 8'b1100); 
							pmem_write(addr, wdata>>16, 8'b0011); 
						end
						2'b11: begin
							pmem_write(addr, wdata<<24, 8'b1000); 
							pmem_write(addr, wdata>>8, 8'b0111); 
						end
					endcase
				end
				default: $finish;
			endcase
		end
	end
end

always @(posedge clk) begin
	if(lsu_en & ~wen) begin
		read_out <= 1;
		case (lsu_ctrl)
			3'b100, 3'b000: begin
				rdata_word <= pmem_read(addr);
				rdata_word_n <= 32'b0;
			end
			3'b010, 3'b101, 3'b001: begin
				 rdata_word <= pmem_read(addr);
				 rdata_word_n <= pmem_read(addr);
			end
			default: $finish;
		endcase
	end
	else
		read_out <= 0;
end

assign ready_out = ~(lsu_en & ~wen & ~read_out);
*/
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
