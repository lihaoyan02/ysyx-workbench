module MEM #(DATA_WIDTH = 32, ADDR_WIDTH=32, SHIFT_LEN=4) (
	input clk,
    input rst,
	input wen,
    input reqValid,
    output reg reqReady,
    input [ADDR_WIDTH-1:0] addr,
	input [DATA_WIDTH-1:0] wdata,
	input [3:0] wmask,
	output reg [DATA_WIDTH-1:0] rdata,
	output respValid,
    input respReady
);

import "DPI-C" function int pmem_read(int raddr);
import "DPI-C" function void pmem_write(int waddr, int wdata, byte wmask);

// always @(posedge clk) begin
//   rdata <= (reqValid && !wen) ? pmem_read(addr) : 32'b0;
//   if (reqValid && wen) begin
//     pmem_write(addr, wdata, {4'b0,wmask});
//   end
//   respValid <= reqValid;
// end

reg state, next_state;
localparam IDLE=1'b0, WAIT=1'b1;

always @(posedge clk) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case (state)
        IDLE: next_state = req_handshaked ? WAIT : IDLE;
        WAIT: next_state = resp_handshaked ? IDLE : WAIT;
    endcase
end
// save mem access info

reg [2:0] cnt;

wire [2:0] rand_val;
assign rand_val = lfsr[2:0];
reg saved_wen;
reg [ADDR_WIDTH-1:0] saved_addr;
reg [DATA_WIDTH-1:0] saved_wdata;
reg [3:0] saved_wmask;
wire req_handshaked, resp_handshaked;
assign req_handshaked = reqValid & reqReady;
assign resp_handshaked = respValid & respReady;
always @(*) begin
    if (reqValid & lfsr_rdy[0])
        reqReady = 1;
    else
        reqReady = 0;
end

reg [3:0] lfsr_rdy;
always @(posedge clk) begin
    if (rst)
        lfsr_rdy <= 4'b1;
    else if (state==IDLE & reqValid) begin
        lfsr_rdy <= {lfsr_rdy[0] ^ lfsr_rdy[2],lfsr_rdy[3:1]};
    end
end

reg [3:0] lfsr;
always @(posedge clk) begin
    if (rst)
        lfsr <= 4'b1;
    else if (state==IDLE & req_handshaked) begin
        lfsr <= {lfsr[0] ^ lfsr[2],lfsr[3:1]};
    end
end

always @(posedge clk) begin
    if (state==IDLE & req_handshaked) begin
        cnt <= rand_val==0 ? 0 : rand_val - 1;
    end
    else if(cnt != 0 & state==WAIT)
        cnt <= cnt - 1;
end

always @(posedge clk) begin
    rdata <= 32'b0;
    // respValid <= 0;
    if (state==IDLE & req_handshaked & rand_val==0) begin // cnt==0 direct out
        if (wen)
            pmem_write(addr, wdata, {4'b0,wmask});    
        else
            rdata <= pmem_read(addr);
        respValid <= 1;
    end
    else if (state==IDLE & req_handshaked & rand_val !=0) begin // save mem access info and init cnt
        cnt <= rand_val - 1;
        saved_wen <= wen;
        saved_addr <= addr;
        saved_wdata <= wdata;
        saved_wmask <= wmask;        
    end
    else if (state==WAIT & cnt == 0 & ~respValid) begin //cnt == 0
        if (saved_wen) begin
            pmem_write(saved_addr, saved_wdata, {4'b0,saved_wmask});
        end     
        else
            rdata <= pmem_read(saved_addr);
        respValid <= 1;
    end
    else if (state==WAIT & cnt!=0) begin
        cnt <= cnt -1;
    end
    else if (resp_handshaked) begin
        respValid <= 0;
    end
end

endmodule