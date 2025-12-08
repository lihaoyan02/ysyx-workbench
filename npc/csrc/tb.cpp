#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <verilated.h>
#include <Vtop.h>
#include "verilated_fst_c.h"

#include <nvboard.h>

static TOP_NAME top;
void nvboard_bind_all_pins(TOPNAME* top);
int main(int argc, char **argv){

	VerilatedContext* const contextp = new VerilatedContext;
	contextp->commandArgs(argc, argv);
	Vtop* const top = new Vtop{contextp};
	
	Verilated::traceEverOn(true);
	VerilatedFstC* tfp = new VerilatedFstC;
	top->trace(tfp, 1);
	tfp->open("obj_dir/wave.fst");
	
	nvboard_blind_all_pins(&top);
	nvboard_init();
	int cnt=0;
	while(cnt<=50){
		int a = rand() & 1;
		int b = rand() & 1;
		top->a = a;
		top->b = b;
		top->eval();
		tfp->dump(cnt);
		printf("a = %d, b = %d, f = %d\n", a, b, top->f);
		assert(top->f == (a ^ b));
		cnt++;
		nvboard_update();
	}
	tfp->close();
	delete top;
	return 0;
}
