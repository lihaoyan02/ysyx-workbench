module icache #(XLEN=32, BLOCK_SIZE=4, BLOCK_NUM=16) (
    input clk,
    input rst,
    input [XLEN-1:0] raddr,
    input avalid,
    output aready,

    output reg [XLEN-1:0] rdata,
    output reg rvalid,
    input rready,
    
    output AWVALID,
	input AWREADY,
	output [XLEN-1:0] AWADDR,
	// output [3:0] AWID,
	// output [7:0] AWLEN,
	// output [2:0] AWSIZE,
	// output [1:0] AWBURST,

	output WVALID,
	input WREADY,
	output [XLEN-1:0] WDATA,
	output [3:0] WSTRB,
	// output WLAST,

	input BVALID,
	output BREADY,
	input [1:0] BRESP,
	// input [3:0] BID,

	output reg ARVALID,
	input ARREADY,
	output [XLEN-1:0] ARADDR,
	// output [3:0] ARID,
	// output [7:0] ARLEN,
	// output [2:0] ARSIZE,
	// output [1:0] ARBURST,

	input RVALID,
	output RREADY,
	input [XLEN-1:0] RDATA,
	input [1:0] RRESP
	// input RLAST,
	// input [3:0] RID
);
//
localparam SRAM_ADDR_DOWN = 32'h0f000000;
localparam SRAM_ADDR_UP = SRAM_ADDR_DOWN + 32'h2000;
// parameter
localparam IDLE=0, FETCH=1, WAIT_BUS=2, WAIT_IFU=3;
localparam OFFSET_LEN       = $clog2(BLOCK_SIZE);
localparam INDEX_LEN        = $clog2(BLOCK_NUM);
localparam TAG_LEN          = XLEN - OFFSET_LEN - INDEX_LEN;
localparam OFFSET_BIT_H     = OFFSET_LEN;
localparam INDEX_BIT_H      = OFFSET_BIT_H + $clog2(BLOCK_NUM);

// cache data
reg [BLOCK_SIZE*8-1:0] cache_rf [BLOCK_NUM-1:0];
reg [TAG_LEN-1:0] cache_tag [BLOCK_NUM-1:0];
reg cache_valid [BLOCK_NUM-1:0];

reg cache_hit;
reg [1:0] state;

assign AWVALID=0;
assign AWADDR=0;
assign WVALID=0;
assign WDATA=0;
assign WSTRB=0;
assign BREADY=0;

reg [XLEN-1:0]  araddr_r;
assign aready = (state==IDLE);
assign ARADDR = ARVALID ? araddr_r : 0;
assign RREADY = state==WAIT_BUS;

wire [INDEX_LEN-1:0]    araddr_r_indx = araddr_r[INDEX_BIT_H-1:OFFSET_BIT_H];
wire [TAG_LEN-1:0]      araddr_r_tag = araddr_r[XLEN-1:INDEX_BIT_H];

wire [INDEX_LEN-1:0]    raddr_indx = raddr[INDEX_BIT_H-1:OFFSET_BIT_H];
wire [TAG_LEN-1:0]      raddr_tag = raddr[XLEN-1:INDEX_BIT_H];

always @(posedge clk) begin
    if (rst) begin
        for (integer i=0; i<BLOCK_NUM ; i=i+1) begin
            cache_rf[i] <= 0;
            cache_tag[i] <= 0;
            cache_valid[i] <= 0;
        end
        state <= IDLE;
        rdata <= 0;
        rvalid <= 0;
        araddr_r <= 0;
        ARVALID <= 0;
    end
    else begin
        case (state)
            IDLE: begin
                if (avalid) begin
                    if (cache_hit) begin
                        state <= WAIT_IFU;
                        rdata <= cache_rf[raddr_indx];
                        rvalid <= 1;
                    end
                    else begin
                        state <= FETCH;
                        araddr_r <= raddr;
                        ARVALID <= 1;
                    end
                end
                else begin
                    state <= IDLE;
                end
            end
            FETCH: begin
                if (AWREADY) begin
                    state <= WAIT_BUS;
                    ARVALID <= 0;
                end
            end
            WAIT_BUS: begin
                if (RVALID) begin
                    state <= WAIT_IFU;
                    if ((araddr_r>=SRAM_ADDR_DOWN) && (araddr_r<SRAM_ADDR_UP)) begin
                        cache_valid[araddr_r_indx] <= 1;
                        cache_tag[araddr_r_indx] <= araddr_r_tag;
                        cache_rf[araddr_r_indx] <= RDATA;
                    end
                    rdata <= RDATA;
                    rvalid <= 1;
                end
            end
            WAIT_IFU: begin
                if (rready) begin
                    rvalid <= 0;
                    state <= IDLE;
                end
            end
        endcase
        
    end
end

always @(*) begin
    cache_hit = 0;
    if (avalid) begin
        if (cache_valid[raddr_indx]) begin
            if (cache_tag[raddr_indx]==raddr_tag) begin
                cache_hit = 1;
            end
            else begin
                cache_hit = 0;
            end
        end
        else begin
            cache_hit = 0;
        end
    end
end
endmodule