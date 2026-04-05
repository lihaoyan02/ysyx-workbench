//`define MEM_MUTI_CYCLE

module MEM #(DATA_WIDTH = 32, ADDR_WIDTH=32, SHIFT_LEN=4) (
	input clk,
    input rst,

    input AWVALID,
	output reg AWREADY,
	input [ADDR_WIDTH-1:0] AWADDR,

	input WVALID,
	output reg WREADY,
	input [DATA_WIDTH-1:0] WDATA,
	input [3:0] WSTRB,

	output reg BVALID,
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
import "DPI-C" function void pmem_write(int waddr, int wdata, byte wmask);

assign BRESP = 0;
assign RRESP = 0;
wire AW_handshaked, W_handshaked, AR_handshaked, R_handshaked, B_handshaked;
assign AW_handshaked = AWVALID & AWREADY;
assign W_handshaked = WVALID & WREADY;
assign AR_handshaked = ARVALID & ARREADY;
assign R_handshaked = RVALID & RREADY;
assign B_handshaked = BVALID & BREADY;

/*--------Write state machine---------*/
localparam WIDLE = 2'b0, ASHAK=2'b01, DSHAK=2'b10, WWAIT = 2'b11;
reg [1:0] wstate;
reg [1:0] next_wstate;
always @(posedge clk) begin
	if (rst)
		wstate <= WIDLE;
	else
		wstate <= next_wstate;
end
always @(*) begin
	case (wstate)
		WIDLE: begin
			next_wstate =  AW_handshaked ? (W_handshaked ? WWAIT : ASHAK) : (W_handshaked ? DSHAK : WIDLE);
		end
		ASHAK: next_wstate = W_handshaked ? WWAIT : ASHAK;
		DSHAK: next_wstate = AW_handshaked ? WWAIT : DSHAK;
		WWAIT: begin
			next_wstate = B_handshaked ? WIDLE : WWAIT;
		end
	endcase
end
/*--------Read state machine---------*/
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

/*----------------------------Write contrl---------------------------*/
/*-------------------------------------------------------------------*/
wire [2:0] w_rand_val;
`ifndef MEM_MUTI_CYCLE
/*--------sigle cycle----------*/
always @(*) begin
    if (AWVALID & (wstate==WIDLE | wstate==DSHAK))
        AWREADY = 1;
    else
        AWREADY = 0;
end
always @(*) begin
    if (WVALID & (wstate==WIDLE | wstate==ASHAK))
        WREADY = 1;
    else
        WREADY = 0;
end
assign w_rand_val = 0;

`else
/*----------multi cycle---------*/
reg [3:0] lfsr_awrdy;
always @(*) begin
    if (AWVALID & lfsr_awrdy[0] & (wstate==WIDLE | wstate==DSHAK))
        AWREADY = 1;
    else
        AWREADY = 0;
end
always @(posedge clk) begin // random time for awready
    if (rst)
        lfsr_awrdy <= 4'b1;
    else if ((wstate==WIDLE | wstate==DSHAK) & AWVALID) begin //wait for aw handshake
        lfsr_awrdy <= {lfsr_awrdy[0] ^ lfsr_awrdy[2],lfsr_awrdy[3:1]};
    end
end

reg [3:0] lfsr_wrdy;
always @(*) begin
    if (WVALID & lfsr_wrdy[0] & (wstate==WIDLE | wstate==ASHAK))
        WREADY = 1;
    else
        WREADY = 0;
end
always @(posedge clk) begin // random time for wready
    if (rst)
        lfsr_wrdy <= 4'b10;
    else if ((wstate==WIDLE | wstate==ASHAK) & WVALID) begin //wait for w handshake
        lfsr_wrdy <= {lfsr_wrdy[0] ^ lfsr_wrdy[2],lfsr_wrdy[3:1]};
    end
end

/*------------rand val generation------------*/
reg [3:0] w_lfsr;
assign w_rand_val = w_lfsr[2:0];

always @(posedge clk) begin
    if (rst)
        w_lfsr <= 4'b1;
    else if (B_handshaked) begin
        w_lfsr <= {w_lfsr[0] ^ w_lfsr[2],w_lfsr[3:1]};
    end
end

`endif

reg [2:0] w_cnt;
always @(posedge clk) begin
    if ((wstate==WIDLE | wstate==DSHAK) & AW_handshaked) begin
        w_cnt <= w_rand_val==0 ? 0 : w_rand_val - 1;
    end
    else if(w_cnt != 0 & wstate==WWAIT)
        w_cnt <= w_cnt - 1;
end
// write control
reg [ADDR_WIDTH-1:0] saved_waddr;
reg [DATA_WIDTH-1:0] saved_wdata;
reg [3:0] saved_wmask;

always @(posedge clk) begin
    if (rst) begin
        BVALID <= 0; 
        BVALID <= 0;
    end
    else if (wstate==WIDLE & AW_handshaked & W_handshaked & w_rand_val==0) begin // cnt==0 direct out
        pmem_write(AWADDR, WDATA, {4'b0,WSTRB});    
        BVALID <= 1;
    end
    else if (wstate==DSHAK & AW_handshaked & w_rand_val==0) begin // cnt==0 direct out
        pmem_write(AWADDR, saved_wdata, {4'b0,saved_wmask});    
        BVALID <= 1;
    end
    else if (wstate==ASHAK & W_handshaked & w_rand_val==0) begin // cnt==0 direct out
        pmem_write(saved_waddr, WDATA, {4'b0,WSTRB});    
        BVALID <= 1;
    end
    else if (wstate==WWAIT & w_cnt == 0 & ~BVALID) begin //cnt == 0
        pmem_write(saved_waddr, saved_wdata, {4'b0,saved_wmask});
        BVALID <= 1;
    end
    else if (AW_handshaked & W_handshaked) begin // save mem access info and init cnt
        saved_waddr <= AWADDR;
        saved_wdata <= WDATA;
        saved_wmask <= WSTRB;
        BVALID <= 0;      
    end
    else if (AW_handshaked) begin // save mem access info and init cnt
        saved_waddr <= AWADDR;
        BVALID <= 0;      
    end
    else if (W_handshaked) begin // save mem access info and init cnt
        saved_wdata <= WDATA;
        saved_wmask <= WSTRB;
        BVALID <= 0;      
    end
    else if (B_handshaked) begin
        BVALID <= 0;
    end
end

/*--------------------------Read contrl------------------------------*/
/*-------------------------------------------------------------------*/
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
    else if (rstate==WAIT & r_cnt == 0 & ~RVALID) begin //cnt == 0
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



endmodule