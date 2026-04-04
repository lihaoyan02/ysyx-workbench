module arbiter #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input clk,
    input rst,
//ifu
    input ifu_AWVALID,
	output ifu_AWREADY,
	input [ADDR_WIDTH-1:0] ifu_AWADDR,

	input ifu_WVALID,
	output ifu_WREADY,
	input [DATA_WIDTH-1:0] ifu_WDATA,
	input [3:0] ifu_WSTRB,

	output ifu_BVALID,
	input ifu_BREADY,
	output [1:0] ifu_BRESP,

	input ifu_ARVALID,
	output ifu_ARREADY,
	input [ADDR_WIDTH-1:0] ifu_ARADDR,

	output ifu_RVALID,
	input ifu_RREADY,
	output [DATA_WIDTH-1:0] ifu_RDATA,
	output [1:0] ifu_RRESP,
// lsu
    input lsu_AWVALID,
	output lsu_AWREADY,
	input [ADDR_WIDTH-1:0] lsu_AWADDR,

	input lsu_WVALID,
	output lsu_WREADY,
	input [DATA_WIDTH-1:0] lsu_WDATA,
	input [3:0] lsu_WSTRB,

	output lsu_BVALID,
	input lsu_BREADY,
	output [1:0] lsu_BRESP,

	input lsu_ARVALID,
	output lsu_ARREADY,
	input [ADDR_WIDTH-1:0] lsu_ARADDR,

	output lsu_RVALID,
	input lsu_RREADY,
	output [DATA_WIDTH-1:0] lsu_RDATA,
	output [1:0] lsu_RRESP,
//mem
    output mem_AWVALID,
	input mem_AWREADY,
	output [ADDR_WIDTH-1:0] mem_AWADDR,

	output mem_WVALID,
	input mem_WREADY,
	output [ADDR_WIDTH-1:0] mem_WDATA,
	output [3:0] mem_WSTRB,

	input mem_BVALID,
	output mem_BREADY,
	input [1:0] mem_BRESP,

	output mem_ARVALID,
	input mem_ARREADY,
	output [ADDR_WIDTH-1:0] mem_ARADDR,

	input mem_RVALID,
	output mem_RREADY,
	input [ADDR_WIDTH-1:0] mem_RDATA,
	input [1:0] mem_RRESP
);

localparam IDLE=2'b00, GRANT_IFU=2'b01, GRANT_LSU=2'b10;
reg [1:0] state, next_state;

wire ifu_req = ifu_AWVALID | ifu_WVALID | ifu_ARVALID;
wire lsu_req = lsu_AWVALID | lsu_WVALID | lsu_ARVALID;

// when IDLE default grant ifu(minimise latency)
// wire grant_lsu = ((state==IDLE) & lsu_req) | state==GRANT_LSU;
wire grant_lsu = state==GRANT_LSU;

always @(posedge clk) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case (state)
        IDLE: begin
            if (ifu_req) begin
                next_state = GRANT_IFU;
            end
            else if (lsu_req) begin
                next_state = GRANT_LSU;
            end
            else
                next_state = IDLE;
        end 
        GRANT_IFU: begin
            if(ifu_RVALID & ifu_RREADY)
                next_state = IDLE;
            else if (ifu_BVALID & ifu_BREADY)
                next_state = IDLE;
            else
                next_state = GRANT_IFU;
        end
        GRANT_LSU: begin
            if(lsu_RVALID & lsu_RREADY)
                next_state = IDLE;
            else if (lsu_BVALID & lsu_BREADY)
                next_state = IDLE;
            else
                next_state = GRANT_LSU;
        end
        default: next_state = IDLE;
    endcase
end

assign mem_AWVALID = grant_lsu ? lsu_AWVALID : ifu_AWVALID;
assign mem_AWADDR = grant_lsu ? lsu_AWADDR : ifu_AWADDR;
assign mem_WVALID = grant_lsu ? lsu_WVALID : ifu_WVALID;
assign mem_WDATA = grant_lsu ? lsu_WDATA : ifu_WDATA;
assign mem_WSTRB = grant_lsu ? lsu_WSTRB : ifu_WSTRB;
assign mem_BREADY = grant_lsu ? lsu_BREADY : ifu_BREADY;
assign mem_ARVALID = grant_lsu ? lsu_ARVALID : ifu_ARVALID;
assign mem_ARADDR = grant_lsu ? lsu_ARADDR : ifu_ARADDR;
assign mem_RREADY = grant_lsu ? lsu_RREADY : ifu_RREADY;

assign ifu_AWREADY = grant_lsu ? 0 : mem_AWREADY;
assign ifu_WREADY = grant_lsu ? 0 : mem_WREADY;
assign ifu_BVALID = grant_lsu ? 0 : mem_BVALID;
assign ifu_BRESP = grant_lsu ? 0 : mem_BRESP;
assign ifu_ARREADY = grant_lsu ? 0 : mem_ARREADY;
assign ifu_RVALID = grant_lsu ? 0 : mem_RVALID;
assign ifu_RDATA = grant_lsu ? 0 : mem_RDATA;
assign ifu_RRESP = grant_lsu ? 0 : mem_RRESP;

assign lsu_AWREADY = grant_lsu ? mem_AWREADY : 0;
assign lsu_WREADY = grant_lsu ? mem_WREADY : 0;
assign lsu_BVALID = grant_lsu ? mem_BVALID : 0;
assign lsu_BRESP = grant_lsu ? mem_BRESP : 0;
assign lsu_ARREADY = grant_lsu ? mem_ARREADY : 0;
assign lsu_RVALID = grant_lsu ? mem_RVALID : 0;
assign lsu_RDATA = grant_lsu ? mem_RDATA : 0;
assign lsu_RRESP = grant_lsu ? mem_RRESP : 0;
endmodule