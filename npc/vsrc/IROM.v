//`define MEM_MUTI_CYCLE

module IROM #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input clk,
    input rst,
    // input reqValid,
    // output reg reqReady,
    // input [ADDR_WIDTH-1:0] addr,
	// output reg [DATA_WIDTH-1:0] rdata,
	// output respValid,
    // input respReady

    input AWVALID,
	output reg AWREADY,
	input [ADDR_WIDTH-1:0] AWADDR,

	input WVALID,
	output WREADY,
	input [DATA_WIDTH-1:0] WDATA,
	input [3:0] WSTRB,

	output BVALID,
	input BREADY,
	output [1:0] BRESP,

	input ARVALID,
	output ARREADY,
	input [ADDR_WIDTH-1:0] ARADDR,

	output reg RVALID,
	input RREADY,
	output reg [DATA_WIDTH-1:0] RDATA,
	output [1:0] RRESP
);

import "DPI-C" function int pmem_read(int raddr);
// wire req_handshaked, resp_handshaked;
// assign req_handshaked = reqValid & reqReady;
// assign resp_handshaked = respValid & respReady;
wire AR_handshaked, R_handshaked;
assign AR_handshaked = ARVALID & ARREADY;
assign R_handshaked = RVALID & RREADY;
assign AWREADY=0;
assign WREADY=0;
assign BVALID=0;
assign BRESP=0;
assign RRESP = 0;

localparam IDLE = 1'b0, WAIT = 1'b1;
reg rstate;
reg next_rstate;
always @(posedge clk) begin
	if (rst)
		rstate <= IDLE;
	else
		rstate <= next_rstate;
end
always @(*) begin
	case (rstate)
		IDLE: begin
			next_rstate =  AR_handshaked ? WAIT : IDLE;
		end
		WAIT: begin
			next_rstate = R_handshaked ? IDLE : WAIT;
		end
	endcase
end
wire [2:0] r_rand_val;
`ifndef MEM_MUTI_CYCLE
/*--------sigle cycle----------*/
always @(*) begin
    if (ARVALID & rstate==IDLE)
        ARREADY = 1;
    else
        ARREADY = 0;
end
assign r_rand_val = 0;

`else
/*----------multi cycle---------*/
always @(*) begin
    if (ARVALID & lfsr_rdy[0] & rstate==IDLE)
        ARREADY = 1;
    else
        ARREADY = 0;
end
reg [3:0] lfsr_rdy;
always @(posedge clk) begin // random time for awready
    if (rst)
        lfsr_rdy <= 4'b1;
    else if (rstate==IDLE & ARVALID) begin //wait for ar handshake
        lfsr_rdy <= {lfsr_rdy[0] ^ lfsr_rdy[2],lfsr_rdy[3:1]};
    end
end

/*------------read rand val generation------------*/
reg [3:0] r_lfsr;
assign r_rand_val = r_lfsr[2:0];
always @(posedge clk) begin
    if (rst)
        r_lfsr <= 4'b1;
    else if (R_handshaked) begin
        r_lfsr <= {r_lfsr[0] ^ r_lfsr[2],r_lfsr[3:1]};
    end
end

`endif

reg [2:0] r_cnt;
always @(posedge clk) begin
    if (rstate==IDLE & AR_handshaked) begin
        r_cnt <= r_rand_val==0 ? 0 : r_rand_val - 1;
    end
    else if(r_cnt != 0 & rstate==WAIT)
        r_cnt <= r_cnt - 1;
end

reg [ADDR_WIDTH-1:0] saved_raddr;

always @(posedge clk) begin
    if (rst) begin
        RDATA <= 32'b0;
        RVALID <= 0;
    end
    else if (rstate==IDLE & AR_handshaked & r_rand_val==0) begin // cnt==0 direct out
        RDATA <= pmem_read(ARADDR); 
        RVALID <= 1;
    end
    else if (rstate==WAIT & r_cnt == 0 & ~R_handshaked) begin //cnt == 0
        RDATA <= pmem_read(saved_raddr);
        RVALID <= 1;
    end
    else if (AR_handshaked) begin // save mem access info and init cnt
        saved_raddr <= ARADDR;
        RVALID <= 0;      
    end
    else if (R_handshaked) begin
        RVALID <= 0;
    end
end
// `ifndef MEM_MUTI_CYCLE
// /*--------sigle cycle----------*/
// always @(*) begin
//     reqReady = reqValid;
// end 
// always @(posedge clk) begin
//     if (rst) begin
//         rdata <= 0;
//         respValid <= 0;
//     end
//     else if (req_handshaked) begin
//         rdata <= pmem_read(addr);
//         respValid <= 1;
//     end
//     else if (resp_handshaked) begin
//         rdata <= 32'b0;
//         respValid <= 0;
//     end
// end

// `else
// /*----------multi cycle---------*/
// reg state, next_state;
// localparam IDLE=1'b0, WAIT=1'b1;

// always @(posedge clk) begin
//     if (rst)
//         state <= IDLE;
//     else
//         state <= next_state;
// end

// always @(*) begin
//     case (state)
//         IDLE: next_state = req_handshaked ? WAIT : IDLE;
//         WAIT: next_state = resp_handshaked ? IDLE : WAIT;
//     endcase
// end

// always @(*) begin
//     if (reqValid & lfsr_rdy[0] & state==IDLE)
//         reqReady = 1;
//     else
//         reqReady = 0;
// end

// reg [3:0] lfsr_rdy;
// always @(posedge clk) begin
//     if (rst)
//         lfsr_rdy <= 4'b1;
//     else if (state==IDLE & reqValid) begin
//         lfsr_rdy <= {lfsr_rdy[0] ^ lfsr_rdy[2],lfsr_rdy[3:1]};
//     end
// end

// // save mem access info

// reg [2:0] cnt;
// reg [3:0] lfsr;
// wire [2:0] rand_val;
// assign rand_val = lfsr[2:0];
// reg [ADDR_WIDTH-1:0] saved_addr;
// always @(posedge clk) begin
//     if (rst)
//         lfsr <= 4'b10;
//     else if (state==IDLE & req_handshaked) begin
//         lfsr <= {lfsr[0] ^ lfsr[2],lfsr[3:1]};
//     end
// end

// always @(posedge clk) begin
//     if (state==IDLE & req_handshaked) begin
//         cnt <= rand_val==0 ? 0 : rand_val - 1;
//     end
//     else if(cnt != 0)
//         cnt <= cnt - 1;
// end

// always @(posedge clk) begin
//     if (rst) begin
//         rdata <= 32'b0;
//         respValid <= 0;
//     end
//     if (state==IDLE & req_handshaked & rand_val==0) begin // cnt==0 direct out
//         rdata <= pmem_read(addr);
//         respValid <= 1;
//     end
//     else if (state==IDLE & req_handshaked & rand_val !=0) begin // save mem access info and init cnt
//         cnt <= rand_val - 1;
//         saved_addr <= addr;      
//     end
//     else if (state==WAIT & cnt == 0 & ~respValid) begin //cnt == 0    
//         rdata <= pmem_read(saved_addr);
//         respValid <= 1;
//     end
//     else if (state==WAIT & cnt!=0) begin
//         rdata <= 32'b0;
//         respValid <= 0;
//         cnt <= cnt -1;
//     end
//     else if (resp_handshaked) begin
//         rdata <= 0;
//         respValid <= 0;
//     end
// end
// `endif
endmodule