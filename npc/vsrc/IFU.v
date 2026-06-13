module IFU #(INST_WIDTH = 32, ADDR_WIDTH = 32)(
	input clk,
	input rst,
	input exu_j_pc,
	input [ADDR_WIDTH-1:0] j_pc_addr,
	input ready_npc_in,
	output reg [ADDR_WIDTH-1:0] pc,
	output reg [INST_WIDTH-1:0] inst_fetch,
	output reg inst_valid,
	output wb_valid,
	
	// to icache
	output [ADDR_WIDTH-1:0] raddr,
    output avalid,
    input aready,

    input [INST_WIDTH-1:0] rdata,
    input rvalid,
    output rready
);

import "DPI-C" function void performance_counter(int category); 

wire AR_handshaked, R_handshaked;
assign AR_handshaked = avalid & aready;
assign R_handshaked = rvalid & rready;
assign rready = rvalid & state==WAIT;

localparam IDLE = 1'b0, WAIT = 1'b1;
reg state, next_state;
always @(posedge clk) begin
	if (rst)
		state <= IDLE;
	else
		state <= next_state;
end


reg R_handshaked_r;
always @(*) begin
	case (state)
		IDLE:
			next_state = AR_handshaked ? WAIT : IDLE;
		WAIT:
			next_state = (ready_npc_in & R_handshaked_r) ? IDLE : WAIT; //(ready_npc_in & R_handshaked) |
	endcase
end

always @(posedge clk) begin
	if (state==WAIT & R_handshaked) begin
		R_handshaked_r <= 1;
		performance_counter(0);
	end
	else if (state==IDLE) begin
		R_handshaked_r <= 0;
	end
end

// reg if_id_valid;
// always @(posedge clk) begin
// 	if (rst) begin
// 		if_id_valid <= 0;
// 	end
// 	else if (R_handshaked) begin
// 		if_id_valid <= 0;
// 	end
// 	else if (if_id_valid & id_if_ready) begin
// 		if_id_valid <= 0;
// 	end
// 	else if (flush) begin
// 		if_id_valid <= 0;
// 	end
// 	else begin
// 		if_id_valid <= if_id_valid;
// 	end
// end

assign avalid = ~rst & state==IDLE;
assign raddr = pc;
assign inst_fetch = R_handshaked ? rdata : 0;
assign inst_valid = R_handshaked;

wire [ADDR_WIDTH-1:0] next_pc;
assign next_pc = exu_j_pc ? j_pc_addr : pc + 4; 
assign wb_valid = state==WAIT & next_state==IDLE;
always @(posedge clk) begin
	`ifndef CONFIG_TARGET_SOC
	if (rst) pc <= 32'h8000_0000;//{ADDR_WIDTH{1'b0}}; 
	`else
	// if (rst) pc <= 32'h2000_0000; // MROM
	if (rst) pc <= 32'h3000_0000; // flash
	`endif
	else if(wb_valid)
		pc <= next_pc;
end

reg [INST_WIDTH-1:0] inst_fetch_r;
always @(posedge clk) begin
	if (rst) begin
		inst_fetch_r <= 0;
	end
	else if (R_handshaked) begin
		inst_fetch_r <= inst_fetch;
	end
end

function int read_inst();
	return R_handshaked ? inst_fetch : inst_fetch_r;
endfunction

export "DPI-C" function read_inst;

function int read_pc();
	return pc;
endfunction

export "DPI-C" function read_pc;

function int read_dnpc();
	return next_pc;
endfunction

export "DPI-C" function read_dnpc;

function int read_state();
	return {31'b0,state&(~next_state)};
endfunction

export "DPI-C" function read_state;

endmodule
