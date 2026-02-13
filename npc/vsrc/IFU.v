module IFU #(INST_WIDTH = 32, ADDR_WIDTH = 32)(
	input clk,
	input rst,
	input j_pc,
	input [ADDR_WIDTH-1:0] j_pc_addr,
	output reg [ADDR_WIDTH-1:0] pc,
	output reg [INST_WIDTH-1:0] inst_fetch
);

import "DPI-C" function int pmem_read(int raddr);
reg rst_r;
wire [ADDR_WIDTH-1:0] next_pc;

assign next_pc = j_pc ? j_pc_addr : pc + 4; 

always @(posedge clk) begin
	if (rst) pc <= 32'h80000000;//{ADDR_WIDTH{1'b0}}; 
	else if(rst_r)
		pc <= 32'h80000000;
	else
		pc <= next_pc;
end

always @(posedge clk) begin
	rst_r <= rst;
end

always @(*) begin
	if (rst)
		inst_fetch = 32'b0;
	else
		inst_fetch = pmem_read(pc);
end

function int read_inst();
	return inst_fetch;
endfunction

export "DPI-C" function read_inst;

endmodule
