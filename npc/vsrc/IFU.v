module IFU #(INST_WIDTH = 32, ADDR_WIDTH = 32)(
	input clk,
	input rst,
	input j_pc,
	input [ADDR_WIDTH-1:0] j_pc_addr,
	input ready_in,
	output reg [ADDR_WIDTH-1:0] pc,
	output reg [INST_WIDTH-1:0] inst_fetch,
	output reg inst_valid,

	output reqValid,
	output [ADDR_WIDTH-1:0] mem_addr,
	input respValid,
	input [INST_WIDTH-1:0] mem_rdata
);
localparam IDLE = 1'b0, WAIT = 1'b1;
reg state, next_state;
always @(posedge clk) begin
	if (rst)
		state <= IDLE;
	else
		state <= next_state;
end

reg inst_r;
always @(*) begin
	case (state)
		IDLE:
			next_state = WAIT;
		WAIT:
			next_state = (ready_in & respValid) | (ready_in & inst_r) ? IDLE : WAIT;
	endcase
end

always @(posedge clk) begin
	if (state==WAIT & respValid) begin
		inst_r <= 1;
	end
	else if (state==IDLE) begin
		inst_r <= 0;
	end
end
assign reqValid = ~rst & state==IDLE;
assign mem_addr = pc;
assign inst_fetch = respValid ? mem_rdata : inst_fetch_r;
assign inst_valid = respValid;
//import "DPI-C" function int pmem_read(int raddr);
//reg rst_r;
wire [ADDR_WIDTH-1:0] next_pc;

assign next_pc = j_pc ? j_pc_addr : pc + 4; 

always @(posedge clk) begin
	if (rst) pc <= 32'h80000000;//{ADDR_WIDTH{1'b0}}; 
	//else if(rst_r)
		//pc <= 32'h80000000;
	else if(state==WAIT & next_state==IDLE)
		pc <= next_pc;
end

reg [INST_WIDTH-1:0] inst_fetch_r;
always @(posedge clk) begin
	if (rst) begin
		inst_fetch_r <= 0;
	end
	else if (respValid) begin
		inst_fetch_r <= inst_fetch;
	end
end
// always @(posedge clk) begin
// 	rst_r <= rst;
// end

// assign inst_valid = state==WAIT;
// always @(posedge clk) begin
// 	if (rst) begin
// 		inst_fetch <= 32'b0;
// 		//idu_en <= 0;
// 	end
// 	else if(state==IDLE) begin
// 		inst_fetch <= pmem_read(pc);
// 		//inst_valid <= 1;
// 	end
// 	// else
// 	// 	inst_valid <= 0;
// end

function int read_inst();
	return respValid ? inst_fetch : inst_fetch_r;
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
