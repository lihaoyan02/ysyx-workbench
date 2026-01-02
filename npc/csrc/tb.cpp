#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <verilated.h>
#include <Vtop.h>
//#include "verilated_fst_c.h"


static uint8_t pmem[1000];
static const uint32_t img[] = {
	0x01400513, 0x010000e7, 0x00c000e7, 0x00c00067,
	0x00a50513, 0x00008067
};

static uint32_t pmem_read(uint32_t addr, int len) {
	uint8_t* paddr = pmem + addr;
	switch (len) {
		case 1: return *(uint8_t  *)paddr;
		case 2: return *(uint16_t *)paddr;
		case 4: return *(uint32_t *)paddr;
		default: assert(0);
	}
}

static void single_cycle(Vtop * top) { 
	top->clk = 0; top->eval();
	top->clk = 1; top->eval();
}
int main(int argc, char **argv){

	VerilatedContext* const contextp = new VerilatedContext;
	contextp->commandArgs(argc, argv);
	Vtop* const top= new Vtop{contextp};
	
	//Verilated::traceEverOn(true);
	//VerilatedFstC* tfp = new VerilatedFstC;
	//top->trace(tfp, 1);
	//tfp->open("obj_dir/wave.fst");
	memcpy(pmem, img, sizeof(img));	
	int cnt=0;
	top->rst = 1;
	single_cycle(top);
	top->rst = 0;
	while(cnt<=10){
		top->inst = pmem_read(top->pc, 4);
		top->eval();
		single_cycle(top);
		top->eval();
		cnt++; 
		printf("pc = %x \n",top->pc);
	}
	//tfp->close();
	//delete top
	return 0;
}
