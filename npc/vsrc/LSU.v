module LSU #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input lsu_en,
	input wen,
	input [2:0] lsu_ctrl,
	input [DATA_WIDTH-1:0] wdata,
	input [ADDR_WIDTH-1:0] waddr,
	input [ADDR_WIDTH-1:0] raddr,
	output [DATA_WIDTH-1:0] rdata
);
import "DPI-C" function uint32_t pmem_read(input uint32_t raddr, int len);
import "DPI-C" function void pmem_write(input uint32_t waddr, input uint32_t wdata, int len);

always @(*) begin
	rdata = 32'b0;
	if(lsu_en) begin
		if (wen) begin
			case (lsu_ctrl)
				3'b010: pmem_write(waddr, wdata, 8'b1111);
				default: $finish;
			endcase
		end
		else begin
			case (lsu_ctrl)
				3'b010: rdata = pmem_read(raddr, 4);
				default: $finish;
			endcase
		end
	end
end

endmodule
