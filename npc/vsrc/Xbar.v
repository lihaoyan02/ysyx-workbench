module Xbar #(DATA_WIDTH = 32, ADDR_WIDTH=32) (
	input clk,
    input rst,
//arbiter
    input abt_AWVALID,
	output abt_AWREADY,
	input [ADDR_WIDTH-1:0] abt_AWADDR,

	input abt_WVALID,
	output abt_WREADY,
	input [DATA_WIDTH-1:0] abt_WDATA,
	input [3:0] abt_WSTRB,

	output abt_BVALID,
	input abt_BREADY,
	output [1:0] abt_BRESP,

	input abt_ARVALID,
	output abt_ARREADY,
	input [ADDR_WIDTH-1:0] abt_ARADDR,

	output abt_RVALID,
	input abt_RREADY,
	output [DATA_WIDTH-1:0] abt_RDATA,
	output [1:0] abt_RRESP,
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
// UART
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

assign mem_AWVALID = uart_sel ? lsu_AWVALID : ifu_AWVALID;
assign mem_AWADDR = uart_sel ? lsu_AWADDR : ifu_AWADDR;
assign mem_WVALID = uart_sel ? lsu_WVALID : ifu_WVALID;
assign mem_WDATA = uart_sel ? lsu_WDATA : ifu_WDATA;
assign mem_WSTRB = uart_sel ? lsu_WSTRB : ifu_WSTRB;
assign mem_BREADY = uart_sel ? lsu_BREADY : ifu_BREADY;
assign mem_ARVALID = uart_sel ? lsu_ARVALID : ifu_ARVALID;
assign mem_ARADDR = uart_sel ? lsu_ARADDR : ifu_ARADDR;
assign mem_RREADY = uart_sel ? lsu_RREADY : ifu_RREADY;

assign ifu_AWREADY = uart_sel ? 0 : mem_AWREADY;
assign ifu_WREADY = uart_sel ? 0 : mem_WREADY;
assign ifu_BVALID = uart_sel ? 0 : mem_BVALID;
assign ifu_BRESP = uart_sel ? 0 : mem_BRESP;
assign ifu_ARREADY = uart_sel ? 0 : mem_ARREADY;
assign ifu_RVALID = uart_sel ? 0 : mem_RVALID;
assign ifu_RDATA = uart_sel ? 0 : mem_RDATA;
assign ifu_RRESP = uart_sel ? 0 : mem_RRESP;

assign lsu_AWREADY = uart_sel ? mem_AWREADY : 0;
assign lsu_WREADY = uart_sel ? mem_WREADY : 0;
assign lsu_BVALID = uart_sel ? mem_BVALID : 0;
assign lsu_BRESP = uart_sel ? mem_BRESP : 0;
assign lsu_ARREADY = uart_sel ? mem_ARREADY : 0;
assign lsu_RVALID = uart_sel ? mem_RVALID : 0;
assign lsu_RDATA = uart_sel ? mem_RDATA : 0;
assign lsu_RRESP = uart_sel ? mem_RRESP : 0;

endmodule