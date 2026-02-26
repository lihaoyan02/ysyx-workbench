#include <dlfcn.h>
#include <utils.h>
#include <reg.h>
#include <memory.h>

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

void (*ref_difftest_memcpy)(uint32_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;

#ifdef CONFIG_DIFFTEST

void init_difftest(char *ref_so_file, long img_size, int port) {
	assert(ref_so_file != NULL);

	void *handle;
	handle = dlopen(ref_so_file, RTLD_LAZY);
	assert(handle);

	ref_difftest_memcpy = dlsym(handle, "difftest_memcpy");
	assert(ref_difftest_memcpy);

	ref_difftest_regcpy = dlsym(handle, "difftest_regcpy");
	assert(ref_difftest_regcpy);

	ref_difftest_exec = dlsym(handle, "difftest_exec");
	assert(ref_difftest_exec);

	void (*ref_difftest_init)(int) = dlsym(handle, "difftest_init"); 
	assert(ref_difftest_init);

	Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
	Log("The result of every instruction will be compared with %s. "
			"This will help you a lot for debugging, but also significantly reduce the performance. "
			"If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

	ref_difftest_init(port);
	ref_difftest_memcpy(MEM_BASE, memory_export(MEM_BASE), img_size, DIFFTEST_TO_REF);
	ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

static bool difftest_checkregs(CPU_state *ref_r, uint32_t pc) {
	bool ret = true;
	for( int i=0; i<16; i++) {
		if(ref_r->gpr[i] != cpu.gpr[i])
			ret = false;
	}
	if(ref_r->pc != pc)
		ret = false;
	return ret;
}

static void checkregs(CPU_state *ref, uint32_t pc) {
	if (!isa_difftest_checkregs(ref, pc)) {
		npc_state.state = NPC_ABORT;
		npc_state.halt_pc = pc;
		reg_display();
	}
}

void difftest_step(uint32_t pc, uint32_t npc) {
	CPU_state ref_r;

	update_reg_state();
	ref_difftest_exec(1);
	ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

	checkregs(&ref_r, npc);

}
#else
void init_difftest(char *ref_so_file, long img_size, int port) { }
#endif
