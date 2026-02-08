#include <common.h>
#include <memory.h> 

#include <verilated.h>
#include <Vtop.h>
#include "verilated_vcd_c.h"

VerilatedContext* contextp = NULL;
Vtop* top = NULL;
VerilatedVcdC* tfp = NULL;

static void single_cycle(Vtop * top, VerilatedVcdC* tfp) {
	//top->clk = 0; eval_dump(top, tfp);
	//top->clk = 1; eval_dump(top, tfp);
	top->clk = 0; top->eval();
	top->clk = 1; top->eval();
}

void init_cpu() {
	contextp = new VerilatedContext;
	//contextp->commandArgs(argc, argv);
	top= new Vtop{contextp};

	Verilated::traceEverOn(true);
	tfp = new VerilatedVcdC;
	 top->trace(tfp, 99);
	 tfp->open("build/wave.vcd");

	 top->rst = 1;
	 single_cycle(top, tfp);
	 top->rst = 0;
}

static void eval_dump(Vtop* top, VerilatedVcdC* tfp) {
	static int time_step = 0;
	top->eval();
	tfp->dump(time_step++);
}


extern "C" void npctrap(int a0) {
	npc_state.state = NPC_END;
	npc_state.halt_ret = a0;
	npc_state.halt_pc = top->pc;
}

static void execute(uint64_t n) {
	for (;n > 0; n --) {
		single_cycle(top, tfp);
		if (npc_state.state != NPC_RUNNING) break;
	}
}

static void statistic() {
}

void cpu_exec(uint64_t n) {
	switch (npc_state.state) {
		case NPC_END: case NPC_QUIT:
			printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
			return;
		default: npc_state.state = NPC_RUNNING;
	}

	execute(n);

	switch (npc_state.state) {
		case NPC_RUNNING: npc_state.state = NPC_STOP; break;

		case NPC_END:
			Log("npc: %s at pc = 0x%08x", (npc_state.halt_ret==0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
					ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED)),
					npc_state.halt_pc);
		case NPC_QUIT: statistic();
										tfp->close();
										delete top;
										delete contextp;
	}
}
