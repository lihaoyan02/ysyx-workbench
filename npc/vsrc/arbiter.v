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
	input [1:0] mem_RRESP,
//uart
    output uart_AWVALID,
	input uart_AWREADY,
	output [ADDR_WIDTH-1:0] uart_AWADDR,

	output uart_WVALID,
	input uart_WREADY,
	output [ADDR_WIDTH-1:0] uart_WDATA,
	output [3:0] uart_WSTRB,

	input uart_BVALID,
	output uart_BREADY,
	input [1:0] uart_BRESP,

	output uart_ARVALID,
	input uart_ARREADY,
	output [ADDR_WIDTH-1:0] uart_ARADDR,

	input uart_RVALID,
	output uart_RREADY,
	input [ADDR_WIDTH-1:0] uart_RDATA,
	input [1:0] uart_RRESP
);
localparam UART_REG_ADDR=32'h1000_0000;
localparam IDLE=2'b00, GRANT_IFU=2'b01, GRANT_LSU=2'b10;
localparam GRANT_UART=2'b01, GRANT_MEM=2'b10;
reg [1:0] mstate, next_mstate;
reg [1:0] sstate, next_sstate;

wire ifu_req = ifu_AWVALID| ifu_ARVALID;
wire lsu_req = lsu_AWVALID| lsu_ARVALID;

// when IDLE default grant ifu(minimise latency)
// wire grant_lsu = ((mstate==IDLE) & lsu_req) | mstate==GRANT_LSU; //combi loop
wire grant_lsu = mstate==GRANT_LSU;
wire grant_ifu = mstate==GRANT_IFU;
wire grant_uart = sstate==GRANT_UART;
wire grant_mem = sstate==GRANT_MEM;
always @(posedge clk) begin
    if (rst) begin
        mstate <= IDLE;
		sstate <= IDLE;
	end
    else begin
        mstate <= next_mstate;
		sstate <= next_sstate;
	end
end

always @(*) begin
    case (mstate)
        IDLE: begin
            if (ifu_req) begin
                next_mstate = GRANT_IFU;
				// if (ifu_AWVALID)
				// 	next_sstate = ifu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				// else
				// 	next_sstate = ifu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
            end
            else if (lsu_req) begin
                next_mstate = GRANT_LSU;
				// if (lsu_AWVALID)
				// 	next_sstate = lsu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				// else
				// 	next_sstate = lsu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
            end
            else begin
                next_mstate = IDLE;
				// next_sstate = IDLE;
			end
        end 
        GRANT_IFU: begin
			if(ifu_RVALID & ifu_RREADY & lsu_req) begin
                next_mstate = GRANT_LSU;
				// if (lsu_AWVALID)
				// 	next_sstate = lsu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				// else
				// 	next_sstate = lsu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
			end
            else if (ifu_BVALID & ifu_BREADY & lsu_req) begin
                next_mstate = GRANT_LSU;
				// if (lsu_AWVALID)
				// 	next_sstate = lsu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				// else
				// 	next_sstate = lsu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
			end
            else if(ifu_RVALID & ifu_RREADY) begin
                next_mstate = IDLE;
				// next_sstate = IDLE;
			end
            else if (ifu_BVALID & ifu_BREADY) begin
                next_mstate = IDLE;
				// next_sstate = IDLE;
			end
            else begin
                next_mstate = GRANT_IFU;
				// next_sstate = sstate==GRANT_UART ? GRANT_UART : GRANT_MEM;
			end
        end
        GRANT_LSU: begin
            if(lsu_RVALID & lsu_RREADY & ifu_req) begin
                next_mstate = GRANT_IFU;
				// if (ifu_AWVALID)
				// 	next_sstate = ifu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				// else
				// 	next_sstate = ifu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
			end
            else if (lsu_BVALID & lsu_BREADY & ifu_req) begin
                next_mstate = GRANT_IFU;
				// if (ifu_AWVALID)
				// 	next_sstate = ifu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				// else
				// 	next_sstate = ifu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
			end
            else if(lsu_RVALID & lsu_RREADY) begin
                next_mstate = IDLE;
				// next_sstate = IDLE;
			end
            else if (lsu_BVALID & lsu_BREADY) begin
                next_mstate = IDLE;
				// next_sstate = IDLE;
			end
            else begin
                next_mstate = GRANT_LSU;
				// next_sstate = sstate==GRANT_UART ? GRANT_UART : GRANT_MEM;
			end
        end
        default: begin
			next_mstate = IDLE;
			// next_sstate = IDLE;
		end
    endcase
end
// single cycle (less time)
always @(*) begin
	case (sstate)
		IDLE: begin
			if (next_mstate==GRANT_IFU) begin
				if (ifu_AWVALID)
					next_sstate = ifu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				else
					next_sstate = ifu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
			end
			else if (next_mstate==GRANT_LSU) begin
				if (lsu_AWVALID)
					next_sstate = lsu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				else
					next_sstate = lsu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
			end		
			else
				next_sstate = IDLE;
		end
		GRANT_UART: begin
			if (mstate==GRANT_IFU & next_mstate==GRANT_LSU) begin
				if (lsu_AWVALID)
					next_sstate = lsu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				else
					next_sstate = lsu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
			end
			if (mstate==GRANT_LSU & next_mstate==GRANT_IFU) begin
				if (ifu_AWVALID)
					next_sstate = ifu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				else
					next_sstate = ifu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
			end
			else if (next_mstate == IDLE) begin
				next_sstate = IDLE;
			end
			else
				next_sstate = GRANT_UART;
		end
		GRANT_MEM: begin
			// if (mstate==GRANT_IFU & next_mstate==GRANT_LSU) begin
			if(mstate==GRANT_IFU & ifu_RVALID & ifu_RREADY & lsu_req) begin
				if (lsu_AWVALID) begin			
					if (lsu_AWADDR[31:12]==20'h1000_0) begin
						$write("lsu_avalid ");
						next_sstate = GRANT_UART;
					end
					else begin
						$write("mem_avalid ");
						next_sstate = GRANT_MEM;
					end
					// next_sstate = lsu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
				else
					next_sstate = lsu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
			end
			if (mstate==GRANT_LSU & next_mstate==GRANT_IFU) begin
				if (ifu_AWVALID)
					next_sstate = ifu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				else
					next_sstate = ifu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
			end
			else if (next_mstate == IDLE) begin
				next_sstate = IDLE;
			end
			else
				next_sstate = GRANT_MEM;
		end
		default: next_sstate = IDLE;
	endcase
end
// two cycle (more time)
// always @(*) begin
// 	case (sstate)
// 		IDLE: begin
// 			if (inter_AWVALID)
// 				next_sstate = inter_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
// 			else if(inter_ARVALID)
// 				next_sstate = inter_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;			
// 			else
// 				next_sstate = IDLE;
// 		end
// 		GRANT_UART: begin
// 			if (uart_BVALID & uart_BREADY) begin
// 				next_sstate = IDLE;
// 			end
// 			if (uart_RVALID & uart_RREADY) begin
// 				next_sstate = IDLE;
// 			end
// 			else
// 				next_sstate = GRANT_UART;
// 		end
// 		GRANT_MEM: begin
// 			if (mem_BVALID & mem_BREADY) begin
// 				next_sstate = IDLE;
// 			end
// 			if (mem_RVALID & mem_RREADY) begin
// 				next_sstate = IDLE;
// 			end
// 			else
// 				next_sstate = GRANT_MEM;
// 		end
// 		default: next_sstate = IDLE;
// 	endcase
// end

wire inter_AWVALID, inter_AWREADY, inter_WVALID, inter_WREADY, 
inter_BVALID, inter_BREADY, inter_ARVALID, inter_ARREADY, inter_RVALID,inter_RREADY;
wire [DATA_WIDTH-1:0] inter_AWADDR, inter_WDATA, inter_ARADDR, inter_RDATA;
wire [3:0] inter_WSTRB;
wire [1:0] inter_BRESP, inter_RRESP;

assign inter_AWVALID = grant_lsu ? lsu_AWVALID : grant_ifu ? ifu_AWVALID : 0;
assign inter_AWADDR = grant_lsu ? lsu_AWADDR : grant_ifu ? ifu_AWADDR : 0;
assign inter_WVALID = grant_lsu ? lsu_WVALID : grant_ifu ? ifu_WVALID : 0;
assign inter_WDATA = grant_lsu ? lsu_WDATA : grant_ifu ? ifu_WDATA : 0;
assign inter_WSTRB = grant_lsu ? lsu_WSTRB : grant_ifu ? ifu_WSTRB : 0;
assign inter_BREADY = grant_lsu ? lsu_BREADY : grant_ifu ? ifu_BREADY : 0;
assign inter_ARVALID = grant_lsu ? lsu_ARVALID : grant_ifu ? ifu_ARVALID : 0;
assign inter_ARADDR = grant_lsu ? lsu_ARADDR : grant_ifu ? ifu_ARADDR : 0;
assign inter_RREADY = grant_lsu ? lsu_RREADY : grant_ifu ? ifu_RREADY : 0;

assign ifu_AWREADY = grant_lsu ? 0 : inter_AWREADY;
assign ifu_WREADY = grant_lsu ? 0 : inter_WREADY;
assign ifu_BVALID = grant_lsu ? 0 : inter_BVALID;
assign ifu_BRESP = grant_lsu ? 0 : inter_BRESP;
assign ifu_ARREADY = grant_lsu ? 0 : inter_ARREADY;
assign ifu_RVALID = grant_lsu ? 0 : inter_RVALID;
assign ifu_RDATA = grant_lsu ? 0 : inter_RDATA;
assign ifu_RRESP = grant_lsu ? 0 : inter_RRESP;

assign lsu_AWREADY = grant_lsu ? inter_AWREADY : 0;
assign lsu_WREADY = grant_lsu ? inter_WREADY : 0;
assign lsu_BVALID = grant_lsu ? inter_BVALID : 0;
assign lsu_BRESP = grant_lsu ? inter_BRESP : 0;
assign lsu_ARREADY = grant_lsu ? inter_ARREADY : 0;
assign lsu_RVALID = grant_lsu ? inter_RVALID : 0;
assign lsu_RDATA = grant_lsu ? inter_RDATA : 0;
assign lsu_RRESP = grant_lsu ? inter_RRESP : 0;

assign inter_AWREADY = grant_uart ? uart_AWREADY : grant_mem ? mem_AWREADY : 0;
assign inter_WREADY = grant_uart ? uart_WREADY : grant_mem ? mem_WREADY : 0;
assign inter_BVALID = grant_uart ? uart_BVALID : grant_mem ? mem_BVALID : 0;
assign inter_BRESP = grant_uart ? uart_BRESP : grant_mem ? mem_BRESP : 0;
assign inter_ARREADY = grant_uart ? uart_ARREADY : grant_mem ? mem_ARREADY : 0;
assign inter_RVALID = grant_uart ? uart_RVALID : grant_mem ? mem_RVALID : 0;
assign inter_RDATA = grant_uart ? uart_RDATA : grant_mem ? mem_RDATA : 0;
assign inter_RRESP = grant_uart ? uart_RRESP  : grant_mem ? mem_RRESP : 0;

assign uart_AWVALID = grant_uart ? inter_AWVALID : 0;
assign uart_AWADDR = grant_uart ? inter_AWADDR : 0;
assign uart_WVALID = grant_uart ? inter_WVALID : 0;
assign uart_WDATA = grant_uart ? inter_WDATA : 0;
assign uart_WSTRB = grant_uart ? inter_WSTRB : 0;
assign uart_BREADY = grant_uart ? inter_BREADY : 0;
assign uart_ARVALID = grant_uart ? inter_ARVALID : 0;
assign uart_ARADDR = grant_uart ? inter_ARADDR : 0;
assign uart_RREADY = grant_uart ? inter_RREADY : 0;

assign mem_AWVALID = grant_mem ? inter_AWVALID : 0;
assign mem_AWADDR = grant_mem ? inter_AWADDR : 0;
assign mem_WVALID = grant_mem ? inter_WVALID : 0;
assign mem_WDATA = grant_mem ? inter_WDATA : 0;
assign mem_WSTRB = grant_mem ? inter_WSTRB : 0;
assign mem_BREADY = grant_mem ? inter_BREADY : 0;
assign mem_ARVALID = grant_mem ? inter_ARVALID : 0;
assign mem_ARADDR = grant_mem ? inter_ARADDR : 0;
assign mem_RREADY = grant_mem ? inter_RREADY : 0;
endmodule