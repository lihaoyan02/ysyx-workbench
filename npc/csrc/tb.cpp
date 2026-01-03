#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>

#include <verilated.h>
#include <Vtop.h>
#include <Vtop__Dpi.h>
#include "verilated_vcd_c.h"

#define MEM_MAX_2_28 1<<30

static uint8_t pmem[MEM_MAX_2_28];
static int end_flag = 0;
static const uint32_t img[] = {
	0x01400513, 0x010000e7, 0x00c000e7, 0x00100073,
	0x00a50513, 0xff410113, 0x00008067 //0x00008067
};

extern "C" int pmem_read(int raddr, int len) {
	uint8_t* paddr = pmem + ((unsigned)raddr & ~0x3u);
	switch (len) {
		case 1: return *(uint8_t  *)paddr;
		case 2: return *(uint16_t *)paddr;
		case 4: return *(uint32_t *)paddr;
		default: assert(0);
	}
}	

extern "C" void pmem_write(int waddr, int wdata, char wmask) {
	uint8_t* paddr = pmem + ((unsigned)waddr & ~0x3u);
	uint8_t byte_addr = (unsigned)waddr & 0x3u;
	switch (wmask) {
		case 0x1: *(uint32_t *)paddr = (uint8_t)(wdata >> (byte_addr << 3)); break;
		case 0x3: *(uint32_t *)paddr = (uint16_t)(wdata >> (byte_addr << 3)); break;
		case 0xf: *(uint32_t *)paddr = wdata; break;
		default: assert(0);
	}
}

void test_fun() {
	pmem_write(0,0x01400513u,0b1111u);
	printf("0x01400513=0x%08x\n 0x0513=0x%08x\n 0x13=0x%08x\n",pmem_read(0,4), pmem_read(0,2), pmem_read(0,1));
	pmem_write(0,0x0513u,0b11u);
	printf("0x01400513=0x%08x\n 0x0513=0x%08x\n 0x13=0x%08x\n",pmem_read(0,4), pmem_read(0,2), pmem_read(0,1));
	pmem_write(0,0x13u,0b1u);
	printf("0x01400513=0x%08x\n 0x0513=0x%08x\n 0x13=0x%08x\n",pmem_read(0,4), pmem_read(0,2), pmem_read(0,1));
}

static void eval_dump(Vtop* top, VerilatedVcdC* tfp) {
	static int time_step = 0;
	top->eval();
	tfp->dump(time_step++);
}

static void single_cycle(Vtop * top, VerilatedVcdC* tfp) { 
	top->clk = 0; eval_dump(top, tfp);
	top->clk = 1; eval_dump(top, tfp);
	//top->clk = 0; top->eval();
	//top->clk = 1; top->eval();
}

extern void npctrap(int a0) {
	end_flag = 1;
	if(a0==0) {
		printf("\033[32mGOOD TRAP\033[0m\n");
	} else {
		printf("\033[31mBAD TRAP a0 = %d\033[0m\n",a0);
	}
}

int load_mem(){
	FILE *file;
	file = fopen("./logisim-bin/sum.bin","rb");
	if(file==NULL){
		printf("fail to open the file\n");
		return 1;
	}
	//obtain the file size
	fseek(file, 0, SEEK_END);
	long file_size = ftell(file);
	fseek(file, 0, SEEK_SET);
	int count = file_size / sizeof(uint8_t);
	//read to the memory
	size_t n = fread(pmem, sizeof(uint8_t), MEM_MAX_2_28, file);
	if(n != count){
		printf("read error or file truncated!\n"); 
	}
	fclose(file);
	pmem_write(0x228, 0x00100073, 0b1111);
	//pmem_write(0x1220, 0x00100073, 0b1111);
	//printf("0x1220 = %08x\n",pmem_read(0x1220,4)); 
	return 0;
}

int main(int argc, char **argv){

	VerilatedContext* const contextp = new VerilatedContext;
	contextp->commandArgs(argc, argv);
	Vtop* const top= new Vtop{contextp};
	
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	top->trace(tfp, 99);
	tfp->open("build/wave.vcd");

	//memcpy(pmem, img, sizeof(img));	
	int result =0;
	result = load_mem();
	if(result!=0){
		printf("fail to load mem\n");
		return 1;
	}

	top->rst = 1;
	single_cycle(top, tfp);
	top->rst = 0;
//	test_fun();
	while(!contextp->gotFinish() && end_flag == 0){
		top->inst = pmem_read(top->pc, 4);
		printf("pc = %x \n",top->pc);
		single_cycle(top, tfp);
	}
	printf("finished at pc = %x \n",top->pc-4);
	tfp->close();
	//delete top
	return 0;
}
