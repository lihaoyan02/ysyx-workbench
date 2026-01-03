#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <verilated.h>
#include <Vtop.h>
#include <Vtop__Dpi.h>
#include "verilated_vcd_c.h"


static uint8_t pmem[1000];
static int end_flag = 0;
static const uint32_t img[] = {
	0x01400513, 0x010000e7, 0x00c000e7, 0x00100073,
	0x00a50513, 0x00008067 //0x00008067
};

extern uint32_t pmem_read(uint32_t raddr, int len) {
	uint8_t* paddr = pmem + raddr;
	switch (len) {
		case 1: return *(uint8_t  *)paddr;
		case 2: return *(uint16_t *)paddr;
		case 4: return *(uint32_t *)paddr;
		default: assert(0);
	}
}	

extern void pmem_write(uint32_t waddr, uint32_t wdata, char wmask) {
	uint8_t* paddr = pmem + (waddr & ~0x3u);
	printf("%x\n",wmask);
	switch (wmask) {
		case 0x1: *paddr = (uint8_t)wdata; break;
		case 0x3: *(uint16_t *)paddr = (uint16_t)wdata; break;
		case 0x15: *(uint32_t *)paddr = wdata; break;
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
}

extern void npctrap(int a0) {
	end_flag = 1;
	if(a0==0) {
		printf("\033[32mGOOD TRAP\033[0m\n");
	} else {
		printf("\033[31mBAD TRAP\033[0m\n");
	}
}

int main(int argc, char **argv){

	VerilatedContext* const contextp = new VerilatedContext;
	contextp->commandArgs(argc, argv);
	Vtop* const top= new Vtop{contextp};
	
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	top->trace(tfp, 99);
	tfp->open("build/wave.vcd");
	memcpy(pmem, img, sizeof(img));	
	top->rst = 1;
	single_cycle(top, tfp);
	top->rst = 0;
	test_fun();
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
