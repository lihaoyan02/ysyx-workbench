module CSR_group #(CSR_ADDR_WIDTH = 12, DATA_WIDTH = 32, CSR_NUM = 8) (
	input clk,
	input rst,
	input wen,
	input [CSR_ADDR_WIDTH-1:0] addr,
	input [DATA_WIDTH-1:0] wdata,
	output reg [DATA_WIDTH-1:0] rdata
);

reg [DATA_WIDTH-1:0] csr [CSR_NUM-1:0];
integer i = 0;

import "DPI-C" function void unknow_inst();

always @(posedge clk) begin
	if(rst) begin
		csr[0] <= 32'h1800; //mestatus 0x300
		csr[6] <= 32'h79737978; //mvendorid ysyx
		csr[7] <= 32'd25120308; //marchid
		for (i=1; i<CSR_NUM-2; i = i+1) begin
			csr[i] <= {DATA_WIDTH{1'b0}};
		end
	end
	else begin
		if(wen != 1 | ~(addr == 12'hb00 | addr == 12'hb80)) begin
			{csr[5],csr[4]} <= {csr[5],csr[4]} + 1;
		end
		if(wen) begin
			case (addr)
				12'h300: //mestatus
					csr[0] <= wdata; 
				12'h305: //mtvec
					csr[1] <= wdata; 
				12'h341: //mepc
					csr[2] <= wdata;
				12'h342: //mecause
					csr[3] <= wdata;
				12'hb00: //mcycle
					csr[4] <= wdata;
				12'hb80: //mcycleh
					csr[5] <= wdata;
				default: unknow_inst();
			endcase
		end
	end
end

always @(*) begin
	case (addr)
		12'h300:
			rdata = csr[0];
		12'h305:
			rdata = csr[1];
		12'h341:
			rdata = csr[2];
		12'h342:
			rdata = csr[3];
		12'hb00:
			rdata = csr[4];
		12'hb80:
			rdata = csr[5];
		12'hf11:
			rdata = csr[6];
		12'hf12:
			rdata = csr[7];
		default:
			rdata = 32'b0;
	endcase
end

endmodule
