module IFU #(INST_WIDTH = 32, ADDR_WIDTH = 32)(
	input clk,
	input rst,
	input j_pc,
	input [ADDR_WIDTH-1:0] j_pc_addr,
	input ready_in,
	output reg [ADDR_WIDTH-1:0] pc,
	output reg [INST_WIDTH-1:0] inst_fetch,
	output reg idu_en
);
localparam IDLE = 1'b0, WAIT = 1'b1;
reg state, next_state;
always @(posedge clk) begin
	if (rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	case (state)
		IDLE:
			next_state = WAIT;
		WAIT:
			next_state = ready_in ? IDLE : WAIT;
	endcase
end

import "DPI-C" function int pmem_read(int raddr);
reg rst_r;
wire [ADDR_WIDTH-1:0] next_pc;

assign next_pc = j_pc ? j_pc_addr : pc + 4; 

always @(posedge clk) begin
	if (rst) pc <= 32'h80000000;//{ADDR_WIDTH{1'b0}}; 
	//else if(rst_r)
		//pc <= 32'h80000000;
	else if(state==WAIT)
		pc <= next_pc;
end

always @(posedge clk) begin
	rst_r <= rst;
end

always @(posedge clk) begin
	if (rst) begin
		inst_fetch <= 32'b0;
		idu_en <= 0;
	end
	else if(state==IDLE) begin
		inst_fetch <= pmem_read(pc);
		idu_en <= 1;
	end
	else
		idu_en <= 0;
end

function int read_inst();
	return inst_fetch;
endfunction

export "DPI-C" function read_inst;

function int read_dnpc();
	return next_pc;
endfunction

export "DPI-C" function read_dnpc;

function int read_state();
	return {31'b0,state&(~next_state)};
endfunction

export "DPI-C" function read_state;

endmodule
