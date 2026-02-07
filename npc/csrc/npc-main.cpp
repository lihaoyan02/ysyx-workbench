#include <common.h>
#include <memory.h>

#include <verilated.h>
#include <Vtop.h>
#include "verilated_vcd_c.h"

void init_monitor(int, char *[]); 
int is_exit_status_bad();
void sdb_mainloop();

/*
static void eval_dump(Vtop* top, VerilatedVcdC* tfp) {
	static int time_step = 0;
	top->eval();
	tfp->dump(time_step++);
}

static void single_cycle(Vtop * top, VerilatedVcdC* tfp) { 
	//top->clk = 0; eval_dump(top, tfp);
	//top->clk = 1; eval_dump(top, tfp);
	top->clk = 0; top->eval();
	top->clk = 1; top->eval();
}

extern "C" void npctrap(int a0) {
	npc_state.state = NPC_END;
	npc_state.halt_ret = a0;
	npc_state.halt_pc = top->pc;
}
*/

int main(int argc, char **argv){

	init_monitor(argc, argv);
/*
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
	while(!contextp->gotFinish() && npc_state.state == NPC_RUNNING){
	//	printf("pc = %x \n",top->pc);
		single_cycle(top, tfp);
	}
	printf("finished at pc = %x \n",top->pc-4);
	if(npc_state.halt_ret==0) {
		printf("\033[32mHIT GOOD TRAP\033[0m\n");
	} else {
		printf("\033[31mHIT BAD TRAP a0 = %d\033[0m\n",npc_state.halt_ret);
	}
	tfp->close();
	//delete top
	delete top;
	delete contextp;
	*/
	sdb_mainloop();
	return is_exit_status_bad();
}
