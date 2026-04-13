module top #(INST_WIDTH = 32, DATA_WIDTH = 32) (
    input clk,
	input rst
  	// output [INST_WIDTH-1:0] pc
);

wire mem_AWVALID, mem_AWREADY, mem_WVALID, mem_WREADY, 
mem_BVALID, mem_BREADY, mem_ARVALID, mem_ARREADY, mem_RVALID,mem_RREADY;
wire [DATA_WIDTH-1:0] mem_AWADDR, mem_WDATA, mem_ARADDR, mem_RDATA;
wire [3:0] mem_WSTRB;
wire [1:0] mem_BRESP, mem_RRESP;
wire [3:0] mem_AWID, mem_ARID, mem_BID, mem_RID;
wire [7:0] mem_AWLEN, mem_ARLEN;
wire [2:0] mem_AWSIZE, mem_ARSIZE;
wire [1:0] mem_AWBURST, mem_ARBURST;
wire mem_WLAST, mem_RLAST;
    core u_core (
        .clk(clk),
		.rst(rst),
        .mem_AWVALID(mem_AWVALID),
        .mem_AWREADY(mem_AWREADY),
        .mem_AWADDR(mem_AWADDR),
        .mem_AWID(mem_AWID),
        .mem_AWLEN(mem_AWLEN),
        .mem_AWSIZE(mem_AWSIZE),
        .mem_AWBURST(mem_AWBURST),

        .mem_WVALID(mem_WVALID),
        .mem_WREADY(mem_WREADY),
        .mem_WDATA(mem_WDATA),
        .mem_WSTRB(mem_WSTRB),
        .mem_WLAST(mem_WLAST),

        .mem_BVALID(mem_BVALID),
        .mem_BREADY(mem_BREADY),
        .mem_BRESP(mem_BRESP),
        .mem_BID(mem_BID),

        .mem_ARVALID(mem_ARVALID),
        .mem_ARREADY(mem_ARREADY),
        .mem_ARADDR(mem_ARADDR),
        .mem_ARID(mem_ARID),
        .mem_ARLEN(mem_ARLEN),
        .mem_ARSIZE(mem_ARSIZE),
        .mem_ARBURST(mem_ARBURST),

        .mem_RVALID(mem_RVALID),
        .mem_RREADY(mem_RREADY),
        .mem_RDATA(mem_RDATA),
        .mem_RRESP(mem_RRESP),
        .mem_RLAST(mem_RLAST),
        .mem_RID(mem_RID)
    );

    MEM u_mem (
		.clk(clk),
		.rst(rst),

		.AWVALID(mem_AWVALID),
		.AWREADY(mem_AWREADY),
		.AWADDR(mem_AWADDR),

		.WVALID(mem_WVALID),
		.WREADY(mem_WREADY),
		.WDATA(mem_WDATA),
		.WSTRB(mem_WSTRB),

		.BVALID(mem_BVALID),
		.BREADY(mem_BREADY),
		.BRESP(mem_BRESP),

		.ARVALID(mem_ARVALID),
		.ARREADY(mem_ARREADY),
		.ARADDR(mem_ARADDR),

		.RVALID(mem_RVALID),
		.RREADY(mem_RREADY),
		.RDATA(mem_RDATA),
		.RRESP(mem_RRESP)
	);
endmodule