module MEM #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input clk,
	input wen,
    input reqValid,
    input [ADDR_WIDTH-1:0] addr,
	input [DATA_WIDTH-1:0] wdata,
	input [3:0] wmask,
	output reg [DATA_WIDTH-1:0] rdata,
	output respValid
);

import "DPI-C" function int pmem_read(int raddr);
import "DPI-C" function void pmem_write(int waddr, int wdata, byte wmask);

always @(posedge clk) begin
    rdata <= (reqValid && !wen) ? pmem_read(addr) : 32'b0;
    if (reqValid && wen) begin
        pmem_write(addr, wdata, {4'b0,wmask});
    end
    respValid <= reqValid;
end
endmodule