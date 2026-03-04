module LSU #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input lsu_en,
	input clk,
	input wen,
	input [2:0] lsu_ctrl,
	input [DATA_WIDTH-1:0] wdata,
	input [ADDR_WIDTH-1:0] waddr,
	input [ADDR_WIDTH-1:0] raddr,
	output reg [DATA_WIDTH-1:0] rdata
);
import "DPI-C" function int pmem_read(int raddr);
import "DPI-C" function void pmem_write(int waddr, int wdata, byte wmask);

reg [DATA_WIDTH-1:0] rdata_word;
reg [DATA_WIDTH-1:0] rdata_word_n;

always @(posedge clk) begin
	if(lsu_en) begin
		if (wen) begin // write enable : store data
			case (lsu_ctrl)
				3'b000: begin //sb
					case (waddr[1:0])
						2'b00: pmem_write(waddr, wdata, 8'b1); 
						2'b01: pmem_write(waddr, wdata<<8, 8'b10); 
						2'b10: pmem_write(waddr, wdata<<16, 8'b100); 
						2'b11: pmem_write(waddr, wdata<<24, 8'b1000); 
					endcase
				end
				3'b001: begin //sj
					case (waddr[1:0])
						2'b00: pmem_write(waddr, wdata, 8'b11); 
						2'b01: pmem_write(waddr, wdata<<8, 8'b110); 
						2'b10: pmem_write(waddr, wdata<<16, 8'b1100); 
						2'b11: begin
							pmem_write(waddr, wdata<<24, 8'b1000); 
							pmem_write(waddr, wdata>>8, 8'b0001); 
						end
					endcase
				end
				3'b010: begin //sw
					case (waddr[1:0])
						2'b00: pmem_write(waddr, wdata, 8'b1111); 
						2'b01: begin
							pmem_write(waddr, wdata<<8, 8'b1110); 
							pmem_write(waddr, wdata>>24, 8'b0001); 
						end
						2'b10: begin
							pmem_write(waddr, wdata<<16, 8'b1100); 
							pmem_write(waddr, wdata>>16, 8'b0011); 
						end
						2'b11: begin
							pmem_write(waddr, wdata<<24, 8'b1000); 
							pmem_write(waddr, wdata>>8, 8'b0111); 
						end
					endcase
				end
				default: $finish;
			endcase
		end
	end
end

always @(*) begin
	rdata = 32'b0;
	rdata_word = 32'b0;
	rdata_word_n = 32'b0;
	if(lsu_en) begin
		if (~wen) begin // write enable : store data
			rdata_word = pmem_read(raddr);
			case (lsu_ctrl)
				3'b100: rdata = raddr[1:0]==2'b00 ? {24'b0, rdata_word[7:0]} :
												raddr[1:0]==2'b01 ? {24'b0, rdata_word[15:8]} :
												raddr[1:0]==2'b10 ? {24'b0, rdata_word[23:16]} :
												raddr[1:0]==2'b11 ? {24'b0, rdata_word[31:24]} : 32'b0; //lbu 
				3'b000: rdata = raddr[1:0]==2'b00 ? {{24{rdata_word[7]}}, rdata_word[7:0]} :
												raddr[1:0]==2'b01 ? {{24{rdata_word[15]}}, rdata_word[15:8]} :
												raddr[1:0]==2'b10 ? {{24{rdata_word[23]}}, rdata_word[23:16]} :
												raddr[1:0]==2'b11 ? {{24{rdata_word[31]}}, rdata_word[31:24]} : 32'b0; //lb 
				3'b010: begin //lw
					rdata_word_n = pmem_read(raddr);
					rdata = raddr[1:0]==2'b00 ? rdata_word : 
									raddr[1:0]==2'b01 ? {rdata_word_n[7:0], rdata_word[31:8]} :
									raddr[1:0]==2'b10 ? {rdata_word_n[15:0], rdata_word[31:16]} :
									raddr[1:0]==2'b11 ? {rdata_word_n[23:0], rdata_word[31:24]} : 32'b0;
							end
				3'b101: begin //lhu 
					rdata_word_n = pmem_read(raddr); 
					rdata = raddr[1:0]==2'b00 ? {16'b0, rdata_word[15:0]} :
									raddr[1:0]==2'b01 ? {16'b0, rdata_word[23:8]} :
									raddr[1:0]==2'b10 ? {16'b0, rdata_word[31:16]} :
									raddr[1:0]==2'b11 ? {16'b0, rdata_word_n[7:0], rdata_word[31:24]} : 32'b0;  
							end
				3'b001: begin //lh 
					rdata_word_n = pmem_read(raddr); 
					rdata = raddr[1:0]==2'b00 ? {{16{rdata_word[15]}}, rdata_word[15:0]} :
									raddr[1:0]==2'b01 ? {{16{rdata_word[23]}}, rdata_word[23:8]} :
									raddr[1:0]==2'b10 ? {{16{rdata_word[31]}}, rdata_word[31:16]} :
									raddr[1:0]==2'b11 ? {{16{rdata_word_n[7]}},rdata_word_n[7:0], rdata_word[31:24]} : 32'b0;  
								end
				default: $finish;
			endcase
		end
	end
end


endmodule
