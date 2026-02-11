#include <common.h>
#include <memory.h> 
#include <decode.h>

#include <verilated.h>
#include <Vtop.h>
#include <Vtop__Dpi.h>
#include "svdpi.h"
#include "verilated_vcd_c.h"

#define MAX_INST_TO_PRINT 10

VerilatedContext* contextp = NULL;
Vtop* top = NULL;
VerilatedVcdC* tfp = NULL;

static bool g_print_step = false;

static void trace_and_difftest(Decode *_this) {
	if (g_print_step) { IFDEF(CONFIG_ITRACE, puts(_this->logbuf)); }

}

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

static void exec_once(Decode *s) {
	s->pc = top->pc;	
	single_cycle(top, tfp);
	s->dnpc = top->pc;
#ifdef CONFIG_ITRACE
	char *p = s->logbuf;
	p += snprintf(p, sizeof(s->logbuf), "0x%08x:", s->pc);
	int ilen = s->snpc - s->pc;
	int i;
	// dpi
	const svScope scope = svGetScopeFromName("Top.top");
	assert(scope);
	svSetScope(scope);
	uint32_t inst32 = read_inst();
	uint8_t *inst = (uint8_t *)&inst32;
	for (i = ilen - 1; i >= 0; i --) {
		p += snprintf(p, 4, " %02x", inst[i]);
	}
	memset(p, ' ', 1);
	p += 1;

	//void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
	//disassemble(p, s->logbuf + sizeof(s->logbuf) - p, s->pc, (uint8_t *)&top->inst_fetch, ilen);
#endif
}


static void execute(uint64_t n) {
	Decode s;
	for (;n > 0; n --) {
		exec_once(&s);
		trace_and_difftest(&s);
		if (npc_state.state != NPC_RUNNING) break;
	}
}

static void statistic() {
}

void cpu_exec(uint64_t n) {
	g_print_step = (n < MAX_INST_TO_PRINT);
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
