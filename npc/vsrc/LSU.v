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

always @(posedge clk) begin
	if(lsu_en) begin
		if (wen) begin // write enable : store data
			case (lsu_ctrl)
				3'b010: pmem_write(waddr, wdata, 8'b1111); //sw
				3'b000: pmem_write(waddr, wdata, 8'b1); //sb
				default: $finish;
			endcase
		end
	end
end

always @(*) begin
	rdata = 32'b0;
	rdata_word = 32'b0;
	if(lsu_en) begin
		if (~wen) begin // write enable : store data
			rdata_word = pmem_read(raddr); //lw
			case (lsu_ctrl)
				3'b010: rdata = rdata_word; //lw
				3'b100: rdata = raddr[1:0]==2'b00 ? {24'b0, rdata_word[7:0]} :
												raddr[1:0]==2'b01 ? {24'b0, rdata_word[15:8]} :
												raddr[1:0]==2'b10 ? {24'b0, rdata_word[23:16]} :
												raddr[1:0]==2'b11 ? {24'b0, rdata_word[31:24]} : 32'b0; //lbu 
				default: $finish;
			endcase
		end
	end
end


endmodule
