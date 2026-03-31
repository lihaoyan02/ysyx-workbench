`define MEM_MUTI_CYCLE

module MEM #(DATA_WIDTH = 32, ADDR_WIDTH=32, SHIFT_LEN=4) (
	input clk,
    input rst,
	// input wen,
    // input reqValid,
    // output reg reqReady,
    // input [ADDR_WIDTH-1:0] addr,
	// input [DATA_WIDTH-1:0] wdata,
	// input [3:0] wmask,
	// output reg [DATA_WIDTH-1:0] rdata,
	// output respValid,
    // input respReady

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
// wire req_handshaked, resp_handshaked;
// assign req_handshaked = reqValid & reqReady;
// assign resp_handshaked = respValid & respReady;
assign BRESP = 0;
assign RRESP =0;
wire AW_handshaked, W_handshaked, AR_handshaked, R_handshaked, B_handshaked;
assign AW_handshaked = AWVALID & AWREADY;
assign W_handshaked = WVALID & WREADY;
assign AR_handshaked = ARVALID & ARREADY;
assign R_handshaked = RVALID & RREADY;
assign B_handshaked = BVALID & BREADY;
`ifndef MEM_MUTI_CYCLE
/*--------sigle cycle----------*/
always @(*) begin
    reqReady = reqValid;
end
always @(posedge clk) begin
    if (rst) begin
        rdata <= 0;
        respValid <= 0;
    end
    else if (req_handshaked) begin
        if (wen) begin
            pmem_write(addr, wdata, {4'b0,wmask});
        end
        else begin
            rdata <= pmem_read(addr);
        end
        respValid <= 1;
    end
    else if (resp_handshaked) begin
        rdata <= 0;
        respValid <= 0;
    end
end

`else
/*----------multi cycle---------*/
localparam WIDLE = 2'b0, ASHAK=2'b01, DSHAK=2'b10, WWAIT = 2'b11;
localparam IDLE = 1'b0, WAIT = 1'b1;
reg [1:0] wstate;
reg [1:0] next_wstate;
reg rstate;
reg next_rstate;
always @(posedge clk) begin
	if (rst) begin
		wstate <= WIDLE;
		rstate <= IDLE;
	end
	else begin
		wstate <= next_wstate;
		rstate <= next_rstate;
	end
end

/*--------Write state machine---------*/
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
// save mem access info

reg [2:0] cnt;

wire [2:0] rand_val;
assign rand_val = lfsr[2:0];
// reg saved_wen;
reg [ADDR_WIDTH-1:0] saved_addr;
reg [DATA_WIDTH-1:0] saved_wdata;
reg [3:0] saved_wmask;
/*--------Write state machine---------*/
always @(*) begin
    if (AWVALID & lfsr_rdy[0] & (wstate==WIDLE | wstate==DSHAK))
        AWREADY = 1;
    else
        AWREADY = 0;
end

always @(*) begin
    if (WVALID & lfsr_rdy[0] & (wstate==WIDLE | wstate==ASHAK))
        WREADY = 1;
    else
        WREADY = 0;
end
/*--------Read state machine---------*/
always @(*) begin
    if (ARVALID & lfsr_rdy[0] & rstate==IDLE)
        ARREADY = 1;
    else
        ARREADY = 0;
end
// ready randval
reg [3:0] lfsr_rdy;
always @(posedge clk) begin
    if (rst)
        lfsr_rdy <= 4'b1;
    else if ((wstate==WIDLE | wstate==DSHAK | wstate==ASHAK) & AWVALID |
    (rstate==IDLE & ARVALID)) begin
        lfsr_rdy <= {lfsr_rdy[0] ^ lfsr_rdy[2],lfsr_rdy[3:1]};
    end
end
// req randval
reg [3:0] lfsr;
always @(posedge clk) begin
    if (rst)
        lfsr <= 4'b1;
    else if (((wstate==WIDLE | wstate==DSHAK) & AW_handshaked) | (rstate==IDLE & AR_handshaked)) begin
        lfsr <= {lfsr[0] ^ lfsr[2],lfsr[3:1]};
    end
end

always @(posedge clk) begin
    if (((wstate==WIDLE | wstate==DSHAK) & AW_handshaked) | (rstate==IDLE & AR_handshaked)) begin
        cnt <= rand_val==0 ? 0 : rand_val - 1;
    end
    else if(cnt != 0 & wstate==WWAIT)
        cnt <= cnt - 1;
end

always @(posedge clk) begin
    if (rst) begin
        BVALID <= 0; 
        BVALID <= 0;
    end
    else if (wstate==WIDLE & AW_handshaked & W_handshaked & rand_val==0) begin // cnt==0 direct out
        pmem_write(AWADDR, WDATA, {4'b0,WSTRB});    
        BVALID <= 1;
    end
    else if (wstate==DSHAK & AW_handshaked & rand_val==0) begin // cnt==0 direct out
        pmem_write(AWADDR, saved_wdata, {4'b0,saved_wmask});    
        BVALID <= 1;
    end
    else if (wstate==ASHAK & W_handshaked & cnt==0) begin // cnt==0 direct out
        pmem_write(saved_addr, WDATA, {4'b0,WSTRB});    
        BVALID <= 1;
    end
    else if (wstate==WWAIT & cnt == 0 & ~BVALID) begin //cnt == 0
        pmem_write(saved_addr, saved_wdata, {4'b0,saved_wmask});
        BVALID <= 1;
    end
    else if (AW_handshaked) begin // save mem access info and init cnt
        cnt <= rand_val - 1;
        saved_addr <= AWADDR;
        BVALID <= 0;      
    end
    else if (W_handshaked) begin // save mem access info and init cnt
        cnt <= rand_val - 1;
        saved_wdata <= WDATA;
        saved_wmask <= WSTRB;
        BVALID <= 0;      
    end
    else if (wstate==WWAIT & cnt!=0) begin
        cnt <= cnt -1;
    end
    else if (B_handshaked) begin
        BVALID <= 0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        RDATA <= 32'b0;
        RVALID <= 0;
    end
    else if (rstate==IDLE & AR_handshaked & rand_val==0) begin // cnt==0 direct out
        //RDATA <= pmem_read(ARADDR); 
        RVALID <= 1;
    end
    else if (rstate==WAIT & cnt == 0 & ~RVALID) begin //cnt == 0
        RDATA <= pmem_read(saved_addr);
        RVALID <= 1;
    end
    else if (AR_handshaked) begin // save mem access info and init cnt
        cnt <= rand_val - 1;
        saved_addr <= ARADDR;
        RVALID <= 0;      
    end
    else if (rstate==WAIT & cnt!=0) begin
        cnt <= cnt -1;
    end
    else if (R_handshaked) begin
        RVALID <= 0;
    end
end

// always @(posedge clk) begin
//     if (rst) begin
//         rdata <= 32'b0;
//         respValid <= 0; 
//     end
//     else if (state==IDLE & req_handshaked & rand_val==0) begin // cnt==0 direct out
//         if (wen)
//             pmem_write(addr, wdata, {4'b0,wmask});    
//         else
//             rdata <= pmem_read(addr);
//         respValid <= 1;
//     end
//     else if (state==IDLE & req_handshaked & rand_val !=0) begin // save mem access info and init cnt
//         cnt <= rand_val - 1;
//         saved_wen <= wen;
//         saved_addr <= addr;
//         saved_wdata <= wdata;
//         saved_wmask <= wmask;  
//         respValid <= 0;      
//     end
//     else if (state==WAIT & cnt == 0 & ~respValid) begin //cnt == 0
//         if (saved_wen) begin
//             pmem_write(saved_addr, saved_wdata, {4'b0,saved_wmask});
//         end     
//         else
//             rdata <= pmem_read(saved_addr);
//         respValid <= 1;
//     end
//     else if (state==WAIT & cnt!=0) begin
//         cnt <= cnt -1;
//     end
//     else if (resp_handshaked) begin
//         rdata <= 0;
//         respValid <= 0;
//     end
// end
`endif

endmodule