module MEM #(DATA_WIDTH = 32, ADDR_WIDTH=32, SHIFT_LEN=4) (
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

// always @(posedge clk) begin
//   rdata <= (reqValid && !wen) ? pmem_read(addr) : 32'b0;
//   if (reqValid && wen) begin
//     pmem_write(addr, wdata, {4'b0,wmask});
//   end
//   respValid <= reqValid;
// end

always @(posedge clk) begin
    if (reqValid && !wen)
        rdata <= pmem_read(addr);
    // else if(respValid)
    //     rdata <= 0;
    if (reqValid && wen) begin
        pmem_write(addr, wdata, {4'b0,wmask});
    end
end

always @(posedge clk) begin
    if (reqValid && wen) begin
        respValid <= reqValid;
    end
    else
        respValid <= shift_reg[0];
end
reg [SHIFT_LEN-1:0] shift_reg;
always @(posedge clk) begin
    if (reqValid && !wen) begin
        shift_reg <= {reqValid,shift_reg[SHIFT_LEN-1:1]};
    end
    else
        shift_reg <= {1'b0,shift_reg[SHIFT_LEN-1:1]};
end

endmodule