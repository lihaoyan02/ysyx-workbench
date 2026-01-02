module IFU #(INST_WIDTH = 32, ADDR_WIDTH = 32)(
	input clk,
	input rst,
	input [INST_WIDTH-1:0] inst,
	input j_pc,
	input [ADDR_WIDTH-1:0] j_pc_addr,
	output reg [ADDR_WIDTH-1:0] pc,
	output [INST_WIDTH-1:0] inst_fetch
);
always @(posedge clk) begin
	if (rst) pc <= {ADDR_WIDTH{1'b0}}; 
	else if(j_pc)
		pc <= j_pc_addr;
	else
		pc <= pc + 4;
end

assign inst_fetch = inst;

endmodule
