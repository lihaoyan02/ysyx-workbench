#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <memory.h>

#include <verilated.h>
#include <Vtop.h>
#include "verilated_vcd_c.h"

static int end_flag = 0;
static const uint32_t img[] = {
	0x01400513, 0x010000e7, 0x00c000e7, 0x00100073,
	0x00a50513, 0xff410113, 0x00008067 //0x00008067
};



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

extern "C" void npctrap(int a0) {
	end_flag = 1;
	if(a0==0) {
		printf("\033[32mGOOD TRAP\033[0m\n");
	} else {
		printf("\033[31mBAD TRAP a0 = %d\033[0m\n",a0);
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
	//	top->inst = pmem_read(top->pc, 4);
		printf("pc = %x \n",top->pc);
		single_cycle(top, tfp);
	}
	printf("finished at pc = %x \n",top->pc-4);
	tfp->close();
	//delete top
	delete top;
	delete contextp;
	return 0;
}
