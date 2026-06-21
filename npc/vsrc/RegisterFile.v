module RegisterFile #(ADDR_WIDTH = 5, DATA_WIDTH = 32, REG_NUM = 16) (
	input clk,
	input rst,
	input en,
	input wen,
	input [ADDR_WIDTH-1:0] waddr,
	input [DATA_WIDTH-1:0] wdata,

	input [ADDR_WIDTH-1:0] raddr1,
	input [ADDR_WIDTH-1:0] raddr2,
	output [DATA_WIDTH-1:0] rdata1,
	output [DATA_WIDTH-1:0] rdata2
);
integer i = 0;
wire write_en = en & wen;
	reg [DATA_WIDTH-1:0] rf [15:0];
	always @(posedge clk) begin
		if(rst) begin
			for (i=0; i<REG_NUM; i = i+1) begin
				rf[i] <= {DATA_WIDTH{1'b0}};
			end
		end 
		else if(write_en && waddr[3:0] != 4'b0) 
			rf[waddr[3:0]] <= wdata;
	end

assign rdata1 = (raddr1==0) ? {DATA_WIDTH{1'b0}} : ((raddr1==waddr)&write_en) ? wdata : rf[raddr1[3:0]];
assign rdata2 = (raddr2==0) ? {DATA_WIDTH{1'b0}} : ((raddr2==waddr)&write_en) ? wdata : rf[raddr2[3:0]];

function int read_reg(input int index);
	return rf[index];
endfunction

export "DPI-C" function read_reg;

endmodule
