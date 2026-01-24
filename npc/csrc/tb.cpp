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
		printf("\033[32mHIT GOOD TRAP\033[0m\n");
	} else {
		printf("\033[31mHIT BAD TRAP a0 = %d\033[0m\n",a0);
	}
}


int main(int argc, char **argv){

	const char* imgfile = NULL;
	if(argc == 1) {
		imgfile = NULL;
	} else if(argc == 2) {
		imgfile = argv[1];
		int result =0;
		result = load_mem(imgfile);
		if(result!=0){
			printf("fail to load mem\n");
			return 1;
		}
	} else {
		printf("too many arguments\n");
		return 1;
	}

	VerilatedContext* const contextp = new VerilatedContext;
	contextp->commandArgs(argc, argv);
	Vtop* const top= new Vtop{contextp};
	
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	top->trace(tfp, 99);
	tfp->open("build/wave.vcd");

	//memcpy(pmem, img, sizeof(img));	
	

	top->rst = 1;
	single_cycle(top, tfp);
	top->rst = 0;
	while(!contextp->gotFinish() && end_flag == 0){
		//printf("pc = %x \n",top->pc);
		single_cycle(top, tfp);
	}
	printf("finished at pc = %x \n",top->pc-4);
	tfp->close();
	//delete top
	delete top;
	delete contextp;
	return 0;
}
