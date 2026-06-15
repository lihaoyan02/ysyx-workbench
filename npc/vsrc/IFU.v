module IFU #(XLEN = 32)(
	input clk,
	input rst,

	input ex_if_jvalid,
	output if_ex_jready,
	input [XLEN-1:0] ex_if_jpc,

	// input ready_npc_in,
	output if_id_valid,
	input id_if_ready,
	output [XLEN-1:0] if_id_pc,
	output [XLEN-1:0] if_id_inst,
	// output wb_valid,
	
	// to icache
	output [XLEN-1:0] raddr,
    output avalid,
    input aready,

    input [XLEN-1:0] rdata,
    input rvalid,
    output rready
);

import "DPI-C" function void performance_counter(int category); 

wire AR_handshaked, R_handshaked;
assign AR_handshaked = avalid & aready;
assign R_handshaked = rvalid & rready;

/*---------------------if_id-----------------------*/
reg inst_valid;
always @(posedge clk) begin
	if (rst) begin
		inst_valid <= 0;
	end
	else if (ex_if_jvalid) begin
		inst_valid <= 0;
	end
	else if (R_handshaked & ~ex_if_jvalid) begin
		inst_valid <= 1;
	end
	else if (if_id_valid & id_if_ready) begin
		inst_valid <= 0;
	end
end

reg [XLEN-1:0] inst_fetch;
always @(posedge clk) begin
	if (rst) begin
		inst_fetch <= 0;
	end
	else if (R_handshaked) begin
		inst_fetch <= rdata;
	end
end

assign if_id_valid = inst_valid;
assign if_id_inst = inst_fetch;
assign if_id_pc = if_pc;
/*--------------ICache-------------------------*/
// change pc at R_handshaked
wire [XLEN-1:0] next_pc;
assign next_pc = pc + 4; 
reg [XLEN-1:0] pc;
// assign wb_valid = state==WAIT & next_state==IDLE;
always @(posedge clk) begin
	`ifndef CONFIG_TARGET_SOC
	if (rst) pc <= 32'h8000_0000;//{XLEN{1'b0}}; 
	`else
	// if (rst) pc <= 32'h2000_0000; // MROM
	if (rst) pc <= 32'h3000_0000; // flash
	`endif
	else if (R_handshaked & ex_if_jvalid) begin
		pc <= ex_if_jpc;
	end
	else if(R_handshaked)
		pc <= next_pc;
end

reg [XLEN-1:0] if_pc;
always @(posedge clk) begin
	if (rst) begin
		if_pc <= 1; // fetch first inst
	end
	else if (R_handshaked) begin
		if_pc <= pc;
	end
end

reg if_ica_avalid;
always @(posedge clk) begin
	if (rst) begin
		if_ica_avalid <= 1; // fetch first inst
	end
	else if (AR_handshaked) begin
		if_ica_avalid <= 0;
	end
	else if (R_handshaked) begin // launch next fetch
		if_ica_avalid <= 1;
	end
end

assign if_ex_jready = R_handshaked; // handshake with exu when R_handshaked
assign avalid = if_ica_avalid;
assign raddr = pc;
assign rready = ~if_id_valid | (if_id_valid & id_if_ready); // ready when no if_id data is pending

/*---------------------DPI-C--------------------*/

function int read_ifpc();
	return pc;
endfunction

export "DPI-C" function read_ifpc;

// function int read_state();
// 	return {31'b0,state&(~next_state)};
// endfunction

// export "DPI-C" function read_state;

endmodule
