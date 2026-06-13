module icache #(XLEN=32, BLOCK_SIZE=16, BLOCK_NUM=16) (
    input clk,
    input rst,
    input [XLEN-1:0] raddr,
    input avalid,
    output aready,

    output reg [XLEN-1:0] rdata,
    output reg rvalid,
    input rready,
    input icache_flush,
    
    output AWVALID,
	input AWREADY,
	output [XLEN-1:0] AWADDR,
	output [3:0] AWID,
	output [7:0] AWLEN,
	output [2:0] AWSIZE,
	output [1:0] AWBURST,

	output WVALID,
	input WREADY,
	output [XLEN-1:0] WDATA,
	output [3:0] WSTRB,
	output WLAST,

	input BVALID,
	output BREADY,
	input [1:0] BRESP,
	input [3:0] BID,

	output reg ARVALID,
	input ARREADY,
	output reg [XLEN-1:0] ARADDR,
	output [3:0] ARID,
	output reg [7:0] ARLEN,
	output [2:0] ARSIZE,
	output reg [1:0] ARBURST,

	input RVALID,
	output RREADY,
	input [XLEN-1:0] RDATA,
	input [1:0] RRESP,
	input RLAST,
	input [3:0] RID
);
//
localparam SRAM_ADDR_DOWN = 32'h0f000000;
localparam SRAM_ADDR_UP = SRAM_ADDR_DOWN + 32'h2000;
localparam SDRAM_ADDR_DOWN = 32'ha0000000;
localparam SDRAM_ADDR_UP = SDRAM_ADDR_DOWN + 32'h4000000;
// parameter
localparam IDLE=0, FETCH_BURST=1, FETCH_SIGLE=2, WAIT_BUS_BURST=3, 
WAIT_BUS_SIGLE=4, WAIT_IFU=5, FETCH_SRAM=6, WAIT_BUS_SRAM=7;
localparam OFFSET_LEN       = $clog2(BLOCK_SIZE);
localparam INDEX_LEN        = $clog2(BLOCK_NUM);
localparam TAG_LEN          = XLEN - OFFSET_LEN - INDEX_LEN;
localparam OFFSET_BIT_H     = OFFSET_LEN;
localparam INDEX_BIT_H      = OFFSET_BIT_H + $clog2(BLOCK_NUM);

// cache data
// reg [BLOCK_SIZE*8-1:0] cache_rf [BLOCK_NUM-1:0];
reg [7:0] cache_rf [BLOCK_NUM-1:0][BLOCK_SIZE-1:0];
reg [TAG_LEN-1:0] cache_tag [BLOCK_NUM-1:0];
reg cache_valid [BLOCK_NUM-1:0];

reg cache_hit;
reg [2:0] state;

assign AWVALID=0;
assign AWADDR=0;
assign WVALID=0;
assign WDATA=0;
assign WSTRB=0;
assign BREADY=0;
assign WLAST = 0;
assign AWID = 0;
assign AWLEN = 0;
assign AWBURST = 0;
assign AWSIZE = 0;

assign ARID = 0;
// assign ARLEN = BLOCK_SIZE/4-1;
assign ARSIZE = 3'b10;
// assign ARBURST = 2'b01;

reg [XLEN-1:0]  araddr_r;
assign aready = (state==IDLE);
// assign ARADDR = ARVALID ? araddr_r : 0;
assign RREADY = (state==WAIT_BUS_BURST) | (state==WAIT_BUS_SIGLE) | (state==WAIT_BUS_SRAM);

wire [INDEX_LEN-1:0]    araddr_r_indx = araddr_r[INDEX_BIT_H-1:OFFSET_BIT_H];
wire [TAG_LEN-1:0]      araddr_r_tag = araddr_r[XLEN-1:INDEX_BIT_H];
wire [OFFSET_LEN-1:0]    araddr_r_off = araddr_r[OFFSET_BIT_H-1:0];

wire [INDEX_LEN-1:0]    raddr_indx = raddr[INDEX_BIT_H-1:OFFSET_BIT_H];
wire [TAG_LEN-1:0]      raddr_tag = raddr[XLEN-1:INDEX_BIT_H];
wire [OFFSET_LEN-1:0]    raddr_off = raddr[OFFSET_BIT_H-1:0];

reg [31:0] cnt;
reg [7:0] ptr;
wire [7:0] n_ptr = ptr + 4;
import "DPI-C" function void icache_access_rcd(byte hit, int access_time); 

always @(posedge clk) begin
    if (rst) begin
        for (integer i=0; i<BLOCK_NUM ; i=i+1) begin
            // cache_rf[i] <= 0;
            cache_tag[i] <= 0;
            cache_valid[i] <= 0;
        end
        state <= IDLE;
        rdata <= 0;
        rvalid <= 0;
        araddr_r <= 0;
        ARVALID <= 0;
        ARADDR <= 0;
        ARLEN = 0;
        ARBURST = 2'b0;
        cnt <= 0;
        ptr <= 0;
    end
    else begin
        case (state)
            IDLE: begin
                if (icache_flush) begin
                    for (integer i=0; i<BLOCK_NUM ; i=i+1) begin
                        cache_valid[i] <= 0;
                    end
                end
                if (avalid) begin
                    if (cache_hit) begin
                        icache_access_rcd(1,1);
                        state <= WAIT_IFU;
                        rdata <= {cache_rf[raddr_indx][raddr_off+3],
                            cache_rf[raddr_indx][raddr_off+2],
                            cache_rf[raddr_indx][raddr_off+1],
                            cache_rf[raddr_indx][raddr_off]};
                        rvalid <= 1;
                    end
                    else if (((raddr>=SRAM_ADDR_DOWN) && (raddr<SRAM_ADDR_UP))) begin
                        cnt <= cnt + 1;
                        state <= FETCH_SRAM;
                        araddr_r <= raddr;
                        ARLEN <= 0;
                        ARBURST <= 2'b0;
                        ARVALID <= 1;
                        ARADDR <= raddr;
                    end
                    else begin
                        cnt <= cnt + 1;
                        `ifdef CONFIG_TARGET_SOC
                        if (((raddr>=SDRAM_ADDR_DOWN) && (raddr<SDRAM_ADDR_UP))) begin
                            state <= FETCH_BURST;
                            ARLEN <= BLOCK_SIZE/4-1;
                            ARBURST <= 2'b01;
                        end
                        else begin
                            state <= FETCH_SIGLE;
                            ARLEN <= 0;
                            ARBURST <= 2'b0;
                            ptr <= 0;
                        end
                        `else
                        state <= FETCH_SIGLE;
                        ARLEN <= 0;
                        ARBURST <= 2'b0;
                        ptr <= 0;
                        `endif
                        araddr_r <= raddr;
                        ARVALID <= 1;
                        ARADDR <= {raddr[XLEN-1:OFFSET_BIT_H],{OFFSET_LEN{1'b0}}};
                    end
                end
                else begin
                    state <= IDLE;
                    cnt <= 0;
                end
            end
            FETCH_BURST: begin
                cnt <= cnt + 1;
                if (ARREADY) begin
                    state <= WAIT_BUS_BURST;
                    ARVALID <= 0;
                    ptr <= 0;
                end
            end
            FETCH_SIGLE: begin
                cnt <= cnt + 1;
                if (ARREADY) begin
                    state <= WAIT_BUS_SIGLE;
                    ARVALID <= 0;
                end
            end
            FETCH_SRAM: begin
                cnt <= cnt + 1;
                if (ARREADY) begin
                    state <= WAIT_BUS_SRAM;
                    ARVALID <= 0;
                end
            end
            WAIT_BUS_SRAM: begin
                cnt <= cnt + 1;
                if (RVALID) begin
                    icache_access_rcd(0,cnt+1);
                    state <= WAIT_IFU;
                    rdata <= RDATA;
                    rvalid <= 1;
                end
            end
            WAIT_BUS_SIGLE: begin
                cnt <= cnt + 1;
                if (RVALID) begin
                    if (n_ptr==BLOCK_SIZE) begin
                        icache_access_rcd(0,cnt+1);
                        state <= WAIT_IFU;
                        cache_valid[araddr_r_indx] <= 1;
                        cache_tag[araddr_r_indx] <= araddr_r_tag;
                        rvalid <= 1;
                    end
                    else begin
                        state <= FETCH_SIGLE;
                        ARVALID <= 1;
                        ARADDR <= {raddr[XLEN-1:OFFSET_BIT_H],n_ptr[OFFSET_LEN-1:0]};
                    end
                    {cache_rf[araddr_r_indx][ptr[OFFSET_LEN-1:0]+3],
                    cache_rf[araddr_r_indx][ptr[OFFSET_LEN-1:0]+2],
                    cache_rf[araddr_r_indx][ptr[OFFSET_LEN-1:0]+1],
                    cache_rf[araddr_r_indx][ptr[OFFSET_LEN-1:0]]} <= RDATA;
                    ptr <= n_ptr;
                    if (araddr_r_off==ptr[OFFSET_LEN-1:0]) begin
                        rdata <= RDATA;
                    end
                end
            end
            WAIT_BUS_BURST: begin
                cnt <= cnt + 1;
                if (RVALID) begin
                    if (RLAST) begin
                        icache_access_rcd(0,cnt+1);
                        state <= WAIT_IFU;
                        cache_valid[araddr_r_indx] <= 1;
                        cache_tag[araddr_r_indx] <= araddr_r_tag;
                        rvalid <= 1;
                    end
                    else begin
                        state <= WAIT_BUS_BURST;
                    end
                    // if (!((araddr_r>=SRAM_ADDR_DOWN) && (araddr_r<SRAM_ADDR_UP))) begin
                    {cache_rf[araddr_r_indx][ptr[OFFSET_LEN-1:0]+3],
                    cache_rf[araddr_r_indx][ptr[OFFSET_LEN-1:0]+2],
                    cache_rf[araddr_r_indx][ptr[OFFSET_LEN-1:0]+1],
                    cache_rf[araddr_r_indx][ptr[OFFSET_LEN-1:0]]} <= RDATA;
                    ptr <= n_ptr;
                    if (araddr_r_off==ptr[OFFSET_LEN-1:0]) begin
                        rdata <= RDATA;
                    end
                    // end
                    
                end
            end
            WAIT_IFU: begin
                cnt <= 0;
                ARADDR <= 0;
                if (icache_flush) begin
                    for (integer i=0; i<BLOCK_NUM ; i=i+1) begin
                        cache_valid[i] <= 0;
                    end
                end
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