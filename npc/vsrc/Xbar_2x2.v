// `define SINGLE_CYCLE_ABT
module Xbar_2x2 #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input clk,
    input rst,
//m1
    input m1_AWVALID,
	output reg m1_AWREADY,
	input [ADDR_WIDTH-1:0] m1_AWADDR,

	input m1_WVALID,
	output reg m1_WREADY,
	input [DATA_WIDTH-1:0] m1_WDATA,
	input [3:0] m1_WSTRB,

	output reg m1_BVALID,
	input m1_BREADY,
	output reg [1:0] m1_BRESP,

	input m1_ARVALID,
	output reg m1_ARREADY,
	input [ADDR_WIDTH-1:0] m1_ARADDR,

	output reg m1_RVALID,
	input m1_RREADY,
	output reg [DATA_WIDTH-1:0] m1_RDATA,
	output reg [1:0] m1_RRESP,
// m2 AXI4
    input m2_AWVALID,
	output reg m2_AWREADY,
	input [ADDR_WIDTH-1:0] m2_AWADDR,
	input [3:0] m2_AWID,
	input [7:0] m2_AWLEN,
	input [2:0] m2_AWSIZE,
	input [1:0] m2_AWBURST,

	input m2_WVALID,
	output reg m2_WREADY,
	input [DATA_WIDTH-1:0] m2_WDATA,
	input [3:0] m2_WSTRB,
	input m2_WLAST,

	output reg m2_BVALID,
	input m2_BREADY,
	output reg [1:0] m2_BRESP,
	output reg [3:0] m2_BID,

	input m2_ARVALID,
	output reg m2_ARREADY,
	input [ADDR_WIDTH-1:0] m2_ARADDR,
	input [3:0] m2_ARID,
	input [7:0] m2_ARLEN,
	input [2:0] m2_ARSIZE,
	input [1:0] m2_ARBURST,

	output reg m2_RVALID,
	input m2_RREADY,
	output reg [DATA_WIDTH-1:0] m2_RDATA,
	output reg [1:0] m2_RRESP,
	output reg m2_RLAST,
	output reg [3:0] m2_RID,
//s1 AXI4
    output reg s1_AWVALID,
	input s1_AWREADY,
	output reg [ADDR_WIDTH-1:0] s1_AWADDR,
	output reg [3:0] s1_AWID,
	output reg [7:0] s1_AWLEN,
	output reg [2:0] s1_AWSIZE,
	output reg [1:0] s1_AWBURST,

	output reg s1_WVALID,
	input s1_WREADY,
	output reg [ADDR_WIDTH-1:0] s1_WDATA,
	output reg [3:0] s1_WSTRB,
	output reg s1_WLAST,

	input s1_BVALID,
	output reg s1_BREADY,
	input [1:0] s1_BRESP,
	input [3:0] s1_BID,

	output reg s1_ARVALID,
	input s1_ARREADY,
	output reg [ADDR_WIDTH-1:0] s1_ARADDR,
	output reg [3:0] s1_ARID,
	output reg [7:0] s1_ARLEN,
	output reg [2:0] s1_ARSIZE,
	output reg [1:0] s1_ARBURST,

	input s1_RVALID,
	output reg s1_RREADY,
	input [ADDR_WIDTH-1:0] s1_RDATA,
	input [1:0] s1_RRESP,
	input s1_RLAST,
	input [3:0] s1_RID,
//s2
    output reg s2_AWVALID,
	input s2_AWREADY,
	output reg [ADDR_WIDTH-1:0] s2_AWADDR,

	output reg s2_WVALID,
	input s2_WREADY,
	output reg [ADDR_WIDTH-1:0] s2_WDATA,
	output reg [3:0] s2_WSTRB,

	input s2_BVALID,
	output reg s2_BREADY,
	input [1:0] s2_BRESP,

	output reg s2_ARVALID,
	input s2_ARREADY,
	output reg [ADDR_WIDTH-1:0] s2_ARADDR,

	input s2_RVALID,
	output reg s2_RREADY,
	input [ADDR_WIDTH-1:0] s2_RDATA,
	input [1:0] s2_RRESP
);
localparam s2_REG_ADDR=32'h0200_0000, s2_MASK=~32'hbfff;
localparam IDLE=2'b00, GRANT_m1=2'b01, GRANT_m2=2'b10;
localparam GRANT_s2=2'b01, GRANT_s1=2'b10;
reg [1:0] mstate, next_mstate;
reg [1:0] sstate, next_sstate;

wire m1_req = m1_AWVALID| m1_ARVALID;
wire m2_req = m2_AWVALID| m2_ARVALID;

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
            if (m1_req) begin
                next_mstate = GRANT_m1;
            end
            else if (m2_req) begin
                next_mstate = GRANT_m2;
            end
            else begin
                next_mstate = IDLE;
			end
        end 
        GRANT_m1: begin
			if(m1_RVALID & m1_RREADY & m2_req) begin
                next_mstate = GRANT_m2;
			end
            else if (m1_BVALID & m1_BREADY & m2_req) begin
                next_mstate = GRANT_m2;
			end
            else if(m1_RVALID & m1_RREADY) begin
                next_mstate = IDLE;
			end
            else if (m1_BVALID & m1_BREADY) begin
                next_mstate = IDLE;
			end
            else begin
                next_mstate = GRANT_m1;
			end
        end
        GRANT_m2: begin
            if(m2_RVALID & m2_RREADY & m1_req) begin
                next_mstate = GRANT_m1;
			end
            else if (m2_BVALID & m2_BREADY & m1_req) begin
                next_mstate = GRANT_m1;
			end
            else if(m2_RVALID & m2_RREADY) begin
                next_mstate = IDLE;
			end
            else if (m2_BVALID & m2_BREADY) begin
                next_mstate = IDLE;
			end
            else begin
                next_mstate = GRANT_m2;
			end
        end
        default: begin
			next_mstate = IDLE;
		end
    endcase
end
/*----------single cycle (less time)--------------*/
`ifdef SINGLE_CYCLE_ABT
always @(*) begin
	case (sstate)
		IDLE: begin
			if (next_mstate==GRANT_m1) begin
				if (m1_AWVALID) begin
					if ((m1_AWADDR & s2_MASK) == s2_REG_ADDR) begin //s2
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end
				else begin
					if ((m1_ARADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end				
			end
			else if (next_mstate==GRANT_m2) begin
				if (m2_AWVALID) begin
					if ((m2_AWADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end 
				else begin
					if ((m2_ARADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end
			end		
			else
				next_sstate = IDLE;
		end
		GRANT_s1: begin
			if (mstate==GRANT_m1 & next_mstate==GRANT_m2) begin
				if (m2_AWVALID) begin	
					if ((m2_AWADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end
				else begin
					if ((m2_ARADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end
			end
			else if (mstate==GRANT_m2 & next_mstate==GRANT_m1) begin
				if (m1_AWVALID) begin
					if ((m1_AWADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end
				else begin
					if ((m1_ARADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end
			end
			else if (next_mstate == IDLE)
				next_sstate = IDLE;
			else
				next_sstate = GRANT_s1;
		end
		GRANT_s2: begin
			if (mstate==GRANT_m1 & next_mstate==GRANT_m2) begin
				if (m2_AWVALID) begin
					if ((m2_AWADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end
				else begin
					if ((m2_ARADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end
			end
			else if (mstate==GRANT_m2 & next_mstate==GRANT_m1) begin
				if (m1_AWVALID) begin
					if ((m1_AWADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end
				else begin
					if ((m1_ARADDR & s2_MASK) == s2_REG_ADDR) begin
						next_sstate = GRANT_s2;
					end
					else begin // s1
						next_sstate = GRANT_s1;
					end
				end
			end
			else if (next_mstate == IDLE) begin
				next_sstate = IDLE;
			end
			else
				next_sstate = GRANT_s2;
		end
		default: next_sstate = IDLE;
	endcase
end

`else
/*----------muti cycle (sequential and more stable)--------------*/
always @(*) begin
	case (sstate)
		IDLE: begin
			if (inter_AWVALID) begin
				if ((inter_AWADDR & s2_MASK) == s2_REG_ADDR) begin
					next_sstate = GRANT_s2;
				end
				else begin // s1
					next_sstate = GRANT_s1;
				end
			end
			else if(inter_ARVALID) begin
				if ((inter_ARADDR & s2_MASK) == s2_REG_ADDR) begin
					next_sstate = GRANT_s2;
				end
				else begin
					next_sstate = GRANT_s1;
				end
			end		
			else
				next_sstate = IDLE;
		end
		GRANT_s1: begin
			if (s1_BVALID & s1_BREADY) begin
				next_sstate = IDLE;
			end
			else if (s1_RVALID & s1_RREADY) begin
				next_sstate = IDLE;
			end
			else
				next_sstate = GRANT_s1;
		end
		GRANT_s2: begin
			if (s2_BVALID & s2_BREADY) begin
				next_sstate = IDLE;
			end
			else if (s2_RVALID & s2_RREADY) begin
				next_sstate = IDLE;
			end
			else
				next_sstate = GRANT_s2;
		end	
		default: next_sstate = IDLE;
	endcase
end
`endif

reg inter_AWVALID, inter_AWREADY, inter_WVALID, inter_WREADY, 
inter_BVALID, inter_BREADY, inter_ARVALID, inter_ARREADY, inter_RVALID,inter_RREADY;
reg [DATA_WIDTH-1:0] inter_AWADDR, inter_WDATA, inter_ARADDR, inter_RDATA;
reg [3:0] inter_WSTRB;
reg [1:0] inter_BRESP, inter_RRESP;
// for AXI4
reg [3:0] inter_AWID, inter_ARID, inter_BID, inter_RID;
reg [7:0] inter_AWLEN, inter_ARLEN;
reg [2:0] inter_AWSIZE, inter_ARSIZE;
reg [1:0] inter_AWBURST, inter_ARBURST;
reg inter_WLAST, inter_RLAST;

always @(*) begin
	case (mstate)
		GRANT_m1: begin
			inter_AWVALID = m1_AWVALID;
			inter_AWADDR = m1_AWADDR;
			inter_WVALID = m1_WVALID;
			inter_WDATA = m1_WDATA;
			inter_WSTRB = m1_WSTRB;
			inter_BREADY = m1_BREADY;
			inter_ARVALID = m1_ARVALID;
			inter_ARADDR = m1_ARADDR;
			inter_RREADY = m1_RREADY;
			inter_AWID = 0;
			inter_ARID = 0;
			inter_AWLEN = 0;
			inter_ARLEN = 0;
			inter_AWSIZE = 3'b10;
			inter_ARSIZE = 3'b10;
			inter_AWBURST = 0;
			inter_ARBURST = 0;
			inter_WLAST = m1_WVALID;

			m1_AWREADY = inter_AWREADY;
			m1_WREADY = inter_WREADY;
			m1_BVALID = inter_BVALID;
			m1_BRESP = inter_BRESP;
			m1_ARREADY = inter_ARREADY;
			m1_RVALID = inter_RVALID;
			m1_RDATA = inter_RDATA;
			m1_RRESP = inter_RRESP;

			m2_AWREADY = 0;
			m2_WREADY = 0;
			m2_BVALID = 0;
			m2_BRESP = 0;
			m2_ARREADY = 0;
			m2_RVALID = 0;
			m2_RDATA = 0;
			m2_RRESP = 0;
			m2_BID = 0;
			m2_RID = 0;
		end
		GRANT_m2: begin
			inter_AWVALID = m2_AWVALID;
			inter_AWADDR = m2_AWADDR;
			inter_WVALID = m2_WVALID;
			inter_WDATA = m2_WDATA;
			inter_WSTRB = m2_WSTRB;
			inter_BREADY = m2_BREADY;
			inter_ARVALID = m2_ARVALID;
			inter_ARADDR = m2_ARADDR;
			inter_RREADY = m2_RREADY;
			inter_AWID = m2_AWID;
			inter_ARID = m2_ARID;
			inter_AWLEN = m2_AWLEN;
			inter_ARLEN = m2_ARLEN;
			inter_AWSIZE = m2_AWSIZE;
			inter_ARSIZE = m2_ARSIZE;
			inter_AWBURST = m2_AWBURST;
			inter_ARBURST = m2_ARBURST;
			inter_WLAST = m2_WLAST;

			m2_AWREADY = inter_AWREADY;
			m2_WREADY = inter_WREADY;
			m2_BVALID = inter_BVALID;
			m2_BRESP = inter_BRESP;
			m2_ARREADY = inter_ARREADY;
			m2_RVALID = inter_RVALID;
			m2_RDATA = inter_RDATA;
			m2_RRESP = inter_RRESP;		
			m2_BID = inter_BID;
			m2_RID = inter_RID;
			m2_RLAST = inter_RLAST;

			m1_AWREADY = 0;
			m1_WREADY = 0;
			m1_BVALID = 0;
			m1_BRESP = 0;
			m1_ARREADY = 0;
			m1_RVALID = 0;
			m1_RDATA = 0;
			m1_RRESP = 0;
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
			inter_AWID = 0;
			inter_ARID = 0;
			inter_AWLEN = 0;
			inter_ARLEN = 0;
			inter_AWSIZE = 3'b10; // default 4 bytes
			inter_ARSIZE = 3'b10; // default 4 bytes
			inter_AWBURST = 0;
			inter_ARBURST = 0;
			inter_WLAST = 0;

			m1_AWREADY = 0;
			m1_WREADY = 0;
			m1_BVALID = 0;
			m1_BRESP = 0;
			m1_ARREADY = 0;
			m1_RVALID = 0;
			m1_RDATA = 0;
			m1_RRESP = 0;

			m2_AWREADY = 0;
			m2_WREADY = 0;
			m2_BVALID = 0;
			m2_BRESP = 0;
			m2_ARREADY = 0;
			m2_RVALID = 0;
			m2_RDATA = 0;
			m2_RRESP = 0;
			m2_BID = 0;
			m2_RID = 0;
			m2_RLAST = 0;
		end
	endcase
end

always @(*) begin
	case (sstate)
		GRANT_s1: begin
			inter_AWREADY = s1_AWREADY;
			inter_WREADY = s1_WREADY;
			inter_BVALID = s1_BVALID; 
			inter_BRESP = s1_BRESP;
			inter_ARREADY = s1_ARREADY;
			inter_RVALID = s1_RVALID;
			inter_RDATA = s1_RDATA;
			inter_RRESP = s1_RRESP;
			inter_RLAST = s1_RLAST;
			inter_BID = s1_BID;
			inter_RID = s1_RID;

			s1_AWVALID = inter_AWVALID;
			s1_AWADDR = inter_AWADDR;
			s1_WVALID = inter_WVALID;
			s1_WDATA = inter_WDATA;
			s1_WSTRB = inter_WSTRB;
			s1_BREADY = inter_BREADY;
			s1_ARVALID = inter_ARVALID;
			s1_ARADDR = inter_ARADDR;
			s1_RREADY = inter_RREADY;

			//burst default
			s1_AWID = inter_AWID;
			s1_AWLEN = inter_AWLEN;
			s1_AWSIZE = inter_AWSIZE;
			s1_AWBURST = inter_AWBURST;
			s1_WLAST = inter_WLAST;
			s1_ARID = inter_ARID;
			s1_ARLEN = inter_ARLEN;
			s1_ARSIZE = inter_ARSIZE;
			s1_ARBURST = inter_ARBURST;

			s2_AWVALID = 0;
			s2_AWADDR = 0;
			s2_WVALID = 0;
			s2_WDATA = 0;
			s2_WSTRB = 0;
			s2_BREADY = 0;
			s2_ARVALID = 0;
			s2_ARADDR = 0;
			s2_RREADY = 0;
		end
		GRANT_s2: begin
			inter_AWREADY = s2_AWREADY;
			inter_WREADY = s2_WREADY;
			inter_BVALID = s2_BVALID; 
			inter_BRESP = s2_BRESP;
			inter_ARREADY = s2_ARREADY;
			inter_RVALID = s2_RVALID;
			inter_RDATA = s2_RDATA;
			inter_RRESP = s2_RRESP;
			inter_RLAST = inter_RVALID;
			inter_BID = 0;
			inter_RID = 0;

			s2_AWVALID = inter_AWVALID;
			s2_AWADDR = inter_AWADDR;
			s2_WVALID = inter_WVALID;
			s2_WDATA = inter_WDATA;
			s2_WSTRB = inter_WSTRB;
			s2_BREADY = inter_BREADY;
			s2_ARVALID = inter_ARVALID;
			s2_ARADDR = inter_ARADDR;
			s2_RREADY = inter_RREADY;

			s1_AWVALID = 0;
			s1_AWADDR = 0;
			s1_WVALID = 0;
			s1_WDATA = 0;
			s1_WSTRB = 0;
			s1_BREADY = 0;
			s1_ARVALID = 0;
			s1_ARADDR = 0;
			s1_RREADY = 0;
			//burst default
			s1_AWID = 0;
			s1_AWLEN = 0;
			s1_AWSIZE = 0;
			s1_AWBURST = 0;
			s1_WLAST = 0;
			s1_ARID = 0;
			s1_ARLEN = 0;
			s1_ARSIZE = 0;
			s1_ARBURST = 0;
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
			inter_RLAST = 0;
			inter_BID = 0;
			inter_RID = 0;

			s2_AWVALID = 0;
			s2_AWADDR = 0;
			s2_WVALID = 0;
			s2_WDATA = 0;
			s2_WSTRB = 0;
			s2_BREADY = 0;
			s2_ARVALID = 0;
			s2_ARADDR = 0;
			s2_RREADY = 0;

			s1_AWVALID = 0;
			s1_AWADDR = 0;
			s1_WVALID = 0;
			s1_WDATA = 0;
			s1_WSTRB = 0;
			s1_BREADY = 0;
			s1_ARVALID = 0;
			s1_ARADDR = 0;
			s1_RREADY = 0;
			//burst default
			s1_AWID = 0;
			s1_AWLEN = 0;
			s1_AWSIZE = 0;
			s1_AWBURST = 0;
			s1_WLAST = 0;
			s1_ARID = 0;
			s1_ARLEN = 0;
			s1_ARSIZE = 0;
			s1_ARBURST = 0;
		end
	endcase
end

endmodule