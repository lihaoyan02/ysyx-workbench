module arbiter #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input clk,
    input rst,
//ifu
    input ifu_AWVALID,
	output reg ifu_AWREADY,
	input [ADDR_WIDTH-1:0] ifu_AWADDR,

	input ifu_WVALID,
	output reg ifu_WREADY,
	input [DATA_WIDTH-1:0] ifu_WDATA,
	input [3:0] ifu_WSTRB,

	output reg ifu_BVALID,
	input ifu_BREADY,
	output reg [1:0] ifu_BRESP,

	input ifu_ARVALID,
	output reg ifu_ARREADY,
	input [ADDR_WIDTH-1:0] ifu_ARADDR,

	output reg ifu_RVALID,
	input ifu_RREADY,
	output reg [DATA_WIDTH-1:0] ifu_RDATA,
	output reg [1:0] ifu_RRESP,
// lsu
    input lsu_AWVALID,
	output reg lsu_AWREADY,
	input [ADDR_WIDTH-1:0] lsu_AWADDR,

	input lsu_WVALID,
	output reg lsu_WREADY,
	input [DATA_WIDTH-1:0] lsu_WDATA,
	input [3:0] lsu_WSTRB,

	output reg lsu_BVALID,
	input lsu_BREADY,
	output reg [1:0] lsu_BRESP,

	input lsu_ARVALID,
	output reg lsu_ARREADY,
	input [ADDR_WIDTH-1:0] lsu_ARADDR,

	output reg lsu_RVALID,
	input lsu_RREADY,
	output reg [DATA_WIDTH-1:0] lsu_RDATA,
	output reg [1:0] lsu_RRESP,
//mem
    output reg mem_AWVALID,
	input mem_AWREADY,
	output reg [ADDR_WIDTH-1:0] mem_AWADDR,

	output reg mem_WVALID,
	input mem_WREADY,
	output reg [ADDR_WIDTH-1:0] mem_WDATA,
	output reg [3:0] mem_WSTRB,

	input mem_BVALID,
	output reg mem_BREADY,
	input [1:0] mem_BRESP,

	output reg mem_ARVALID,
	input mem_ARREADY,
	output reg [ADDR_WIDTH-1:0] mem_ARADDR,

	input mem_RVALID,
	output reg mem_RREADY,
	input [ADDR_WIDTH-1:0] mem_RDATA,
	input [1:0] mem_RRESP,
//uart
    output reg uart_AWVALID,
	input uart_AWREADY,
	output reg [ADDR_WIDTH-1:0] uart_AWADDR,

	output reg uart_WVALID,
	input uart_WREADY,
	output reg [ADDR_WIDTH-1:0] uart_WDATA,
	output reg [3:0] uart_WSTRB,

	input uart_BVALID,
	output reg uart_BREADY,
	input [1:0] uart_BRESP,

	output reg uart_ARVALID,
	input uart_ARREADY,
	output reg [ADDR_WIDTH-1:0] uart_ARADDR,

	input uart_RVALID,
	output reg uart_RREADY,
	input [ADDR_WIDTH-1:0] uart_RDATA,
	input [1:0] uart_RRESP,
//clint
    output reg clint_AWVALID,
	input clint_AWREADY,
	output reg [ADDR_WIDTH-1:0] clint_AWADDR,

	output reg clint_WVALID,
	input clint_WREADY,
	output reg [ADDR_WIDTH-1:0] clint_WDATA,
	output reg [3:0] clint_WSTRB,

	input clint_BVALID,
	output reg clint_BREADY,
	input [1:0] clint_BRESP,

	output reg clint_ARVALID,
	input clint_ARREADY,
	output reg [ADDR_WIDTH-1:0] clint_ARADDR,

	input clint_RVALID,
	output reg clint_RREADY,
	input [ADDR_WIDTH-1:0] clint_RDATA,
	input [1:0] clint_RRESP
);
localparam UART_REG_ADDR=32'h1000_0000, UART_MUSK=~32'hfff;
localparam CLINT_ADDR=32'h0200_0000, CLINT_MASK=~32'hbfff;
localparam IDLE=2'b00, GRANT_IFU=2'b01, GRANT_LSU=2'b10;
localparam GRANT_UART=2'b01, GRANT_MEM=2'b10, GRANT_CLINT=2'b11;
reg [1:0] mstate, next_mstate;
reg [1:0] sstate, next_sstate;

wire ifu_req = ifu_AWVALID| ifu_ARVALID;
wire lsu_req = lsu_AWVALID| lsu_ARVALID;

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
            end
            else if (lsu_req) begin
                next_mstate = GRANT_LSU;
            end
            else begin
                next_mstate = IDLE;
			end
        end 
        GRANT_IFU: begin
			if(ifu_RVALID & ifu_RREADY & lsu_req) begin
                next_mstate = GRANT_LSU;
			end
            else if (ifu_BVALID & ifu_BREADY & lsu_req) begin
                next_mstate = GRANT_LSU;
			end
            else if(ifu_RVALID & ifu_RREADY) begin
                next_mstate = IDLE;
			end
            else if (ifu_BVALID & ifu_BREADY) begin
                next_mstate = IDLE;
			end
            else begin
                next_mstate = GRANT_IFU;
			end
        end
        GRANT_LSU: begin
            if(lsu_RVALID & lsu_RREADY & ifu_req) begin
                next_mstate = GRANT_IFU;
			end
            else if (lsu_BVALID & lsu_BREADY & ifu_req) begin
                next_mstate = GRANT_IFU;
			end
            else if(lsu_RVALID & lsu_RREADY) begin
                next_mstate = IDLE;
			end
            else if (lsu_BVALID & lsu_BREADY) begin
                next_mstate = IDLE;
			end
            else begin
                next_mstate = GRANT_LSU;
			end
        end
        default: begin
			next_mstate = IDLE;
		end
    endcase
end
// single cycle (less time)
always @(*) begin
	case (sstate)
		IDLE: begin
			if (next_mstate==GRANT_IFU) begin
				if (ifu_AWVALID) begin
					if (ifu_AWADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((ifu_AWADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
				end
				else begin
					if (ifu_ARADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((ifu_ARADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					//next_sstate = ifu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end				
			end
			else if (next_mstate==GRANT_LSU) begin
				if (lsu_AWVALID) begin
					if (lsu_AWADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((lsu_AWADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = lsu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end 
				else begin
					if (lsu_ARADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((lsu_ARADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = lsu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
			end		
			else
				next_sstate = IDLE;
		end
		GRANT_UART: begin
			if (mstate==GRANT_IFU & next_mstate==GRANT_LSU) begin
				if (lsu_AWVALID) begin
					if (lsu_AWADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((lsu_AWADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = lsu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
				else begin
					if (lsu_ARADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((lsu_ARADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = lsu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
			end
			else if (mstate==GRANT_LSU & next_mstate==GRANT_IFU) begin
				if (ifu_AWVALID) begin
					if (ifu_AWADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((ifu_AWADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = ifu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
				else begin
					if (ifu_ARADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((ifu_ARADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = ifu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
			end
			else if (next_mstate == IDLE) begin
				next_sstate = IDLE;
			end
			else
				next_sstate = GRANT_UART;
		end
		GRANT_MEM: begin
			if (mstate==GRANT_IFU & next_mstate==GRANT_LSU) begin
				if (lsu_AWVALID) begin	
					if (lsu_AWADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((lsu_AWADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = lsu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
				else begin
					if (lsu_ARADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((lsu_ARADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = lsu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
			end
			else if (mstate==GRANT_LSU & next_mstate==GRANT_IFU) begin
				if (ifu_AWVALID) begin
					if (ifu_AWADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((ifu_AWADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = ifu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
				else begin
					if (ifu_ARADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((ifu_ARADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = ifu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
			end
			else if (next_mstate == IDLE)
				next_sstate = IDLE;
			else
				next_sstate = GRANT_MEM;
		end
		GRANT_CLINT: begin
			if (mstate==GRANT_IFU & next_mstate==GRANT_LSU) begin
				if (lsu_AWVALID) begin	
					if (lsu_AWADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((lsu_AWADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = lsu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
				else begin
					if (lsu_ARADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((lsu_ARADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = lsu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
			end
			else if (mstate==GRANT_LSU & next_mstate==GRANT_IFU) begin
				if (ifu_AWVALID) begin
					if (ifu_AWADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((ifu_AWADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = ifu_AWADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
				else begin
					if (ifu_ARADDR[31:12]==20'h1000_0) begin //uart
						next_sstate = GRANT_UART;
					end
					else if ((ifu_ARADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
						next_sstate = GRANT_CLINT;
					end
					else begin // mem
						next_sstate = GRANT_MEM;
					end
					// next_sstate = ifu_ARADDR[31:12]==20'h1000_0 ? GRANT_UART : GRANT_MEM;
				end
			end
			else if (next_mstate == IDLE)
				next_sstate = IDLE;
			else
				next_sstate = GRANT_CLINT;
		end
		default: next_sstate = IDLE;
	endcase
end

// two cycle (more time)
// always @(*) begin
// 	case (sstate)
// 		IDLE: begin
// 			if (inter_AWVALID) begin
// 				if (inter_AWADDR[31:12]==20'h1000_0) begin //uart
// 					next_sstate = GRANT_UART;
// 				end
// 				else if ((inter_AWADDR & CLINT_MASK) == CLINT_ADDR) begin //clint
// 					next_sstate = GRANT_CLINT;
// 				end
// 				else begin // mem
// 					next_sstate = GRANT_MEM;
// 				end
// 			end
// 			else if(inter_ARVALID) begin
// 				if (inter_ARADDR[31:12]==20'h1000_0) begin
// 					next_sstate = GRANT_UART;
// 				end
// 				else if ((inter_ARADDR & CLINT_MASK) == CLINT_ADDR) begin
// 					next_sstate = GRANT_CLINT;
// 				end
// 				else begin
// 					next_sstate = GRANT_MEM;
// 				end
// 			end		
// 			else
// 				next_sstate = IDLE;
// 		end
// 		GRANT_UART: begin
// 			if (uart_BVALID & uart_BREADY) begin
// 				next_sstate = IDLE;
// 			end
// 			else if (uart_RVALID & uart_RREADY) begin
// 				next_sstate = IDLE;
// 			end
// 			else
// 				next_sstate = GRANT_UART;
// 		end
// 		GRANT_MEM: begin
// 			if (mem_BVALID & mem_BREADY) begin
// 				next_sstate = IDLE;
// 			end
// 			else if (mem_RVALID & mem_RREADY) begin
// 				next_sstate = IDLE;
// 			end
// 			else
// 				next_sstate = GRANT_MEM;
// 		end
// 		GRANT_CLINT: begin
// 			if (clint_BVALID & clint_BREADY) begin
// 				next_sstate = IDLE;
// 			end
// 			else if (clint_RVALID & clint_RREADY) begin
// 				next_sstate = IDLE;
// 			end
// 			else
// 				next_sstate = GRANT_CLINT;
// 		end
// 		default: next_sstate = IDLE;
// 	endcase
// end

reg inter_AWVALID, inter_AWREADY, inter_WVALID, inter_WREADY, 
inter_BVALID, inter_BREADY, inter_ARVALID, inter_ARREADY, inter_RVALID,inter_RREADY;
reg [DATA_WIDTH-1:0] inter_AWADDR, inter_WDATA, inter_ARADDR, inter_RDATA;
reg [3:0] inter_WSTRB;
reg [1:0] inter_BRESP, inter_RRESP;

always @(*) begin
	case (mstate)
		GRANT_IFU: begin
			inter_AWVALID = ifu_AWVALID;
			inter_AWADDR = ifu_AWADDR;
			inter_WVALID = ifu_WVALID;
			inter_WDATA = ifu_WDATA;
			inter_WSTRB = ifu_WSTRB;
			inter_BREADY = ifu_BREADY;
			inter_ARVALID = ifu_ARVALID;
			inter_ARADDR = ifu_ARADDR;
			inter_RREADY = ifu_RREADY;

			ifu_AWREADY = inter_AWREADY;
			ifu_WREADY = inter_WREADY;
			ifu_BVALID = inter_BVALID;
			ifu_BRESP = inter_BRESP;
			ifu_ARREADY = inter_ARREADY;
			ifu_RVALID = inter_RVALID;
			ifu_RDATA = inter_RDATA;
			ifu_RRESP = inter_RRESP;
		end
		GRANT_LSU: begin
			inter_AWVALID = lsu_AWVALID;
			inter_AWADDR = lsu_AWADDR;
			inter_WVALID = lsu_WVALID;
			inter_WDATA = lsu_WDATA;
			inter_WSTRB = lsu_WSTRB;
			inter_BREADY = lsu_BREADY;
			inter_ARVALID = lsu_ARVALID;
			inter_ARADDR = lsu_ARADDR;
			inter_RREADY = lsu_RREADY;

			lsu_AWREADY = inter_AWREADY;
			lsu_WREADY = inter_WREADY;
			lsu_BVALID = inter_BVALID;
			lsu_BRESP = inter_BRESP;
			lsu_ARREADY = inter_ARREADY;
			lsu_RVALID = inter_RVALID;
			lsu_RDATA = inter_RDATA;
			lsu_RRESP = inter_RRESP;		
		end
		default: begin
			inter_AWVALID = 0;
			inter_AWADDR = 0;
			inter_WVALID = 0;
			inter_WDATA = 0;
			inter_WSTRB = 0;
			inter_BREADY = 0;
			inter_ARVALID = 0;
			inter_ARADDR = 0;
			inter_RREADY = 0;

			ifu_AWREADY = 0;
			ifu_WREADY = 0;
			ifu_BVALID = 0;
			ifu_BRESP = 0;
			ifu_ARREADY = 0;
			ifu_RVALID = 0;
			ifu_RDATA = 0;
			ifu_RRESP = 0;

			lsu_AWREADY = 0;
			lsu_WREADY = 0;
			lsu_BVALID = 0;
			lsu_BRESP = 0;
			lsu_ARREADY = 0;
			lsu_RVALID = 0;
			lsu_RDATA = 0;
			lsu_RRESP = 0;
		end
	endcase
end

always @(*) begin
	case (sstate)
		GRANT_UART: begin
			inter_AWREADY = uart_AWREADY;
			inter_WREADY = uart_WREADY;
			inter_BVALID = uart_BVALID; 
			inter_BRESP = uart_BRESP;
			inter_ARREADY = uart_ARREADY;
			inter_RVALID = uart_RVALID;
			inter_RDATA = uart_RDATA;
			inter_RRESP = uart_RRESP;

			uart_AWVALID = inter_AWVALID;
			uart_AWADDR = inter_AWADDR;
			uart_WVALID = inter_WVALID;
			uart_WDATA = inter_WDATA;
			uart_WSTRB = inter_WSTRB;
			uart_BREADY = inter_BREADY;
			uart_ARVALID = inter_ARVALID;
			uart_ARADDR = inter_ARADDR;
			uart_RREADY = inter_RREADY;
		end
		GRANT_MEM: begin
			inter_AWREADY = mem_AWREADY;
			inter_WREADY = mem_WREADY;
			inter_BVALID = mem_BVALID; 
			inter_BRESP = mem_BRESP;
			inter_ARREADY = mem_ARREADY;
			inter_RVALID = mem_RVALID;
			inter_RDATA = mem_RDATA;
			inter_RRESP = mem_RRESP;

			mem_AWVALID = inter_AWVALID;
			mem_AWADDR = inter_AWADDR;
			mem_WVALID = inter_WVALID;
			mem_WDATA = inter_WDATA;
			mem_WSTRB = inter_WSTRB;
			mem_BREADY = inter_BREADY;
			mem_ARVALID = inter_ARVALID;
			mem_ARADDR = inter_ARADDR;
			mem_RREADY = inter_RREADY;
		end
		GRANT_CLINT: begin
			inter_AWREADY = clint_AWREADY;
			inter_WREADY = clint_WREADY;
			inter_BVALID = clint_BVALID; 
			inter_BRESP = clint_BRESP;
			inter_ARREADY = clint_ARREADY;
			inter_RVALID = clint_RVALID;
			inter_RDATA = clint_RDATA;
			inter_RRESP = clint_RRESP;

			clint_AWVALID = inter_AWVALID;
			clint_AWADDR = inter_AWADDR;
			clint_WVALID = inter_WVALID;
			clint_WDATA = inter_WDATA;
			clint_WSTRB = inter_WSTRB;
			clint_BREADY = inter_BREADY;
			clint_ARVALID = inter_ARVALID;
			clint_ARADDR = inter_ARADDR;
			clint_RREADY = inter_RREADY;
		end
		default: begin
			inter_AWREADY = 0;
			inter_WREADY = 0;
			inter_BVALID = 0; 
			inter_BRESP = 0;
			inter_ARREADY = 0;
			inter_RVALID = 0;
			inter_RDATA = 0;
			inter_RRESP = 0;

			uart_AWVALID = 0;
			uart_AWADDR = 0;
			uart_WVALID = 0;
			uart_WDATA = 0;
			uart_WSTRB = 0;
			uart_BREADY = 0;
			uart_ARVALID = 0;
			uart_ARADDR = 0;
			uart_RREADY = 0;

			mem_AWVALID = 0;
			mem_AWADDR = 0;
			mem_WVALID = 0;
			mem_WDATA = 0;
			mem_WSTRB = 0;
			mem_BREADY = 0;
			mem_ARVALID = 0;
			mem_ARADDR = 0;
			mem_RREADY = 0;

			clint_AWVALID = 0;
			clint_AWADDR = 0;
			clint_WVALID = 0;
			clint_WDATA = 0;
			clint_WSTRB = 0;
			clint_BREADY = 0;
			clint_ARVALID = 0;
			clint_ARADDR = 0;
			clint_RREADY = 0;
		end
	endcase
end

endmodule