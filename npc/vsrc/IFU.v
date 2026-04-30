module IFU #(INST_WIDTH = 32, ADDR_WIDTH = 32)(
	input clk,
	input rst,
	input j_pc,
	input [ADDR_WIDTH-1:0] j_pc_addr,
	input ready_in,
	output reg [ADDR_WIDTH-1:0] pc,
	output reg [INST_WIDTH-1:0] inst_fetch,
	output reg inst_valid,
	output wb_valid,
	
	output AWVALID,
	input AWREADY,
	output [ADDR_WIDTH-1:0] AWADDR,
	// output [3:0] AWID,
	// output [7:0] AWLEN,
	// output [2:0] AWSIZE,
	// output [1:0] AWBURST,

	output WVALID,
	input WREADY,
	output [INST_WIDTH-1:0] WDATA,
	output [3:0] WSTRB,
	// output WLAST,

	input BVALID,
	output BREADY,
	input [1:0] BRESP,
	// input [3:0] BID,

	output ARVALID,
	input ARREADY,
	output [ADDR_WIDTH-1:0] ARADDR,
	// output [3:0] ARID,
	// output [7:0] ARLEN,
	// output [2:0] ARSIZE,
	// output [1:0] ARBURST,

	input RVALID,
	output RREADY,
	input [INST_WIDTH-1:0] RDATA,
	input [1:0] RRESP
	// input RLAST,
	// input [3:0] RID
);
wire AR_handshaked, R_handshaked;
assign AR_handshaked = ARVALID & ARREADY;
assign R_handshaked = RVALID & RREADY;

assign AWVALID=0;
assign AWADDR=0;
assign WVALID=0;
assign WDATA=0;
assign WSTRB=0;
assign BREADY=0;
assign RREADY = RVALID & state==WAIT;

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
			next_state = (ready_in & R_handshaked) | (ready_in & R_handshaked_r) ? IDLE : WAIT;
	endcase
end

always @(posedge clk) begin
	if (state==WAIT & R_handshaked) begin
		R_handshaked_r <= 1;
	end
	else if (state==IDLE) begin
		R_handshaked_r <= 0;
	end
end

assign ARVALID = ~rst & state==IDLE;
assign ARADDR = pc;
assign inst_fetch = R_handshaked ? RDATA : 0;
assign inst_valid = R_handshaked;

wire [ADDR_WIDTH-1:0] next_pc;
assign next_pc = j_pc ? j_pc_addr : pc + 4; 
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
