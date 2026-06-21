module CSR_group #(CSR_ADDR_WIDTH = 12, XLEN = 32, CSR_NUM = 8) (
	input clk,
	input rst,
	input csr_exvalid,
	input [XLEN-1:0] csr_cause,
	input [XLEN-1:0] csr_pc,
	input csr_wvalid,
	input [CSR_ADDR_WIDTH-1:0] csr_waddr,
	input [XLEN-1:0] csr_wdata,
	
	
	input [CSR_ADDR_WIDTH-1:0] csr_raddr,
	output reg [XLEN-1:0] csr_rdata
);

integer i = 0;

import "DPI-C" function void unknow_inst(int pc, int inst);

assign csr_rdata = rdata;

reg [XLEN-1:0] mestatus;
reg [XLEN-1:0] mtvec;
reg [XLEN-1:0] mepc;
reg [XLEN-1:0] mecause;
reg [XLEN-1:0] mcycle;
reg [XLEN-1:0] mcycleh;
reg [XLEN-1:0] mvendorid;
reg [XLEN-1:0] marchid;

always @(posedge clk) begin
	if(rst) begin
		mestatus <= 32'h1800; //mestatus 0x300
		mtvec <= 0;
		mepc <= 0;
		mecause <= 0;
		mcycle <= 0;
		mcycleh <= 0;
		mvendorid <= 32'h79737978; //mvendorid ysyx
		marchid <= 32'd25120308; //marchid
	end
	else begin
		if(~((csr_wvalid) & (csr_waddr == 12'hb00 | csr_waddr == 12'hb80))) begin
			{mcycleh,mcycle} <= {mcycleh,mcycle} + 1;
		end
		if(csr_exvalid) begin
			mepc <= csr_pc;
			mecause <= csr_cause;
		end
		else if (csr_wvalid) begin
				case (csr_waddr)
					12'h300: mestatus <= csr_wdata; 
					12'h305: mtvec <= csr_wdata; 
					12'h341: mepc <= csr_wdata;
					12'h342: mecause <= csr_wdata;
					12'hb00: mcycle <= csr_wdata;
					12'hb80: mcycleh <= csr_wdata;
					default: unknow_inst(csr_pc, 0);
				endcase
			
		end
	end
end

reg [XLEN-1:0] rdata;
always @(*) begin
	case (csr_raddr)
		12'h300:
			rdata = mestatus;
		12'h305:
			rdata = mtvec;
		12'h341:
			rdata = mepc;
		12'h342:
			rdata = mecause;
		12'hb00:
			rdata = mcycle;
		12'hb80:
			rdata = mcycleh;
		12'hf11:
			rdata = mvendorid;
		12'hf12:
			rdata = marchid;
		default:
			rdata = 32'b0;
	endcase
end

endmodule
