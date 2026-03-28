module IROM #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input clk,
    input rst,
    input reqValid,
    input [ADDR_WIDTH-1:0] addr,
	output reg [DATA_WIDTH-1:0] rdata,
	output respValid
);

import "DPI-C" function int pmem_read(int raddr);

// always @(posedge clk) begin
//   rdata <= reqValid ? pmem_read(addr) : 32'b0;
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
        IDLE: next_state = reqValid ? WAIT : IDLE;
        WAIT: next_state = respValid ? IDLE : WAIT;
    endcase
end
// save mem access info

reg [2:0] cnt;
reg [3:0] lfsr;
wire [2:0] rand_val;
assign rand_val = lfsr[2:0];
reg [ADDR_WIDTH-1:0] saved_addr;
always @(posedge clk) begin
    if (rst)
        lfsr <= 4'b1;
    else if (state==IDLE & reqValid) begin
        lfsr <= {lfsr[0] ^ lfsr[2],lfsr[3:1]};
    end
end

always @(posedge clk) begin
    if (state==IDLE & reqValid) begin
        cnt <= rand_val==0 ? 0 : rand_val - 1;
    end
    else if(cnt != 0)
        cnt <= cnt - 1;
end

always @(posedge clk) begin
    rdata <= 32'b0;
    respValid <= 0;
    if (state==IDLE & reqValid & rand_val==0) begin // cnt==0 direct out
        rdata <= pmem_read(addr);
        respValid <= 1;
    end
    else if (state==IDLE & reqValid & rand_val !=0) begin // save mem access info and init cnt
        cnt <= rand_val - 1;
        saved_addr <= addr;      
    end
    else if (state==WAIT & cnt == 0 & ~respValid) begin //cnt == 0    
        rdata <= pmem_read(saved_addr);
        respValid <= 1;
    end
    else if (state==WAIT & cnt!=0) begin
        cnt <= cnt -1;
    end
end

endmodule