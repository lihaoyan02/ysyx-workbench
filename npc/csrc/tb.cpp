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

static void eval_dump(Vtop* top, VerilatedVcdC* tfp) {
	static int time_step = 0;
	top->eval();
	tfp->dump(time_step++);
}

static void single_cycle(Vtop * top, VerilatedVcdC* tfp) { 
	top->clk = 0; eval_dump(top, tfp);
	top->clk = 1; eval_dump(top, tfp);
}

extern void npctrap() {
	end_flag = 1;
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
	int cnt=0;
	top->rst = 1;
	single_cycle(top, tfp);
	top->rst = 0;
	while(cnt<=10 && end_flag == 0){
		top->inst = pmem_read(top->pc, 4);
		single_cycle(top, tfp);
		cnt++; 
		printf("pc = %x \n",top->pc);
	}
	printf("finished at pc = %x \n",top->pc);
	tfp->close();
	//delete top
	return 0;
}
