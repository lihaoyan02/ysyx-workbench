#include <common.h>
#include <memory.h> 
#include <decode.h>
#include <core.h>

#define MAX_INST_TO_PRINT 10

uint64_t g_nr_guest_inst = 0;
static bool g_print_step = false;

static void trace_and_difftest(Decode *_this) {
#ifdef CONFIG_ITRACE
	log_write("%s\n", _this->logbuf);
#endif
	if (g_print_step) { IFDEF(CONFIG_ITRACE, puts(_this->logbuf)); }

}

static void single_cycle(Decode *s) {
	//top->clk = 0; eval_dump(top, tfp);
	//top->clk = 1; eval_dump(top, tfp);
	top->clk = 0; top->eval();
	top->clk = 1; top->eval();
	s->inst = core_read_inst();
	s->pc = top->pc;
	s->dnpc = core_read_dnpc(); 
}

void init_cpu() {
	contextp = new VerilatedContext;
	//contextp->commandArgs(argc, argv);
	top= new Vtop{contextp};

	//Verilated::traceEverOn(true);
	//tfp = new VerilatedVcdC;
	 //top->trace(tfp, 99);
	 //tfp->open("build/wave.vcd");

	top->rst = 1;
	top->clk = 0; top->eval();
	top->clk = 1; top->eval();
	top->rst = 0;
	top->eval();
}

static void eval_dump() {
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
	single_cycle(s);
#ifdef CONFIG_ITRACE
	char *p = s->logbuf;
	p += snprintf(p, sizeof(s->logbuf), "0x%08x:", s->pc);
	int ilen = 4;
	int i;
	// dpi
	uint8_t *inst = (uint8_t *)&s->inst;
	for (i = ilen - 1; i >= 0; i --) {
		p += snprintf(p, 4, " %02x", inst[i]);
	}
	memset(p, ' ', 1);
	p += 1;

	void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
	disassemble(p, s->logbuf + sizeof(s->logbuf) - p, s->pc, (uint8_t *)&s->inst, ilen);
#endif
}


static void execute(uint64_t n) {
	Decode s;
	for (;n > 0; n --) {
		exec_once(&s);
		g_nr_guest_inst ++;
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
										//tfp->close();
										//delete tfp;
	}
}
