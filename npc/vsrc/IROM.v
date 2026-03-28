module IROM #(DATA_WIDTH = 32, ADDR_WIDTH=32, SHIFT_LEN=2) (
	input clk,
    input rst,
    input reqValid,
    input [ADDR_WIDTH-1:0] addr,
	output reg [DATA_WIDTH-1:0] rdata,
	output respValid
);

import "DPI-C" function int pmem_read(int raddr);

// always @(posedge clock) begin
//   rdata <= reqValid ? pmem_read(addr) : 32'b0;
//   respValid <= reqValid;
// end

always @(posedge clk) begin
    if (reqValid)
        rdata <= pmem_read(addr);
    // else if(respValid)
    //     rdata <= 0;
end

always @(posedge clk) begin
    respValid <= shift_reg[0];
end
reg [SHIFT_LEN-1:0] shift_reg;
always @(posedge clk) begin
    if (rst) begin
        shift_reg <= 0;
    end
    else if (reqValid) begin
        shift_reg <= {reqValid,shift_reg[SHIFT_LEN-1:1]};
    end
    else
        shift_reg <= {1'b0,shift_reg[SHIFT_LEN-1:1]};
end

endmodule