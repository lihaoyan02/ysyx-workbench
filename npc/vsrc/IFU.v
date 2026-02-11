module IFU #(INST_WIDTH = 32, ADDR_WIDTH = 32)(
	input clk,
	input rst,
	input j_pc,
	input [ADDR_WIDTH-1:0] j_pc_addr,
	output reg [ADDR_WIDTH-1:0] pc,
	output reg [INST_WIDTH-1:0] inst_fetch
);

import "DPI-C" function int pmem_read(int raddr);

always @(posedge clk) begin
	if (rst) pc <= 32'h80000000;//{ADDR_WIDTH{1'b0}}; 
	else if(j_pc)
		pc <= j_pc_addr;
	else
		pc <= pc + 4;
end

always @(*) begin
	//if (rst)
		//inst_fetch = 32'b0;
	//else
		inst_fetch = pmem_read(pc);
end

function int read_inst();
	return inst_fetch;
endfunction

export "DPI-C" function read_inst;

endmodule
