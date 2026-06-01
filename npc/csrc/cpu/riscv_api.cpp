#include <common.h>
#include <core.h>

VerilatedContext* contextp = NULL;
#ifndef CONFIG_TARGET_SOC
Vtop* top = NULL;
#else
VysyxSoCFull* top = NULL;
#endif
#ifdef CONFIG_TRACE_WAVE
VerilatedVcdC* tfp = NULL;
#endif 

#ifndef CONFIG_TARGET_SOC
char IFUscope[] = "TOP.top.u_core.u_IFU";
char gprscope[] = "TOP.top.u_core.u_gpr";
#else
char IFUscope[] = "TOP.ysyxSoCFull.asic.cpu.cpu.u_core.u_IFU";
char gprscope[] = "TOP.ysyxSoCFull.asic.cpu.cpu.u_core.u_gpr";
#endif

uint32_t core_read_inst() {
	const svScope scope = svGetScopeFromName(IFUscope);
	assert(scope); 
	svSetScope(scope);
	return read_inst(); 
}

uint32_t core_read_pc() {
	const svScope scope = svGetScopeFromName(IFUscope);
	assert(scope); 
	svSetScope(scope);
	return read_pc(); 
}

uint32_t core_read_dnpc() {
	const svScope scope = svGetScopeFromName(IFUscope);
	assert(scope); 
	svSetScope(scope);
	return read_dnpc(); 
}

uint32_t core_read_reg(uint32_t idx) {
	assert(idx<16);
	const svScope scope = svGetScopeFromName(gprscope);
	assert(scope); 
	svSetScope(scope);
	return read_reg(idx);
}

uint32_t core_read_state() {
	const svScope scope = svGetScopeFromName(IFUscope);
	assert(scope); 
	svSetScope(scope);
	return read_state();
}

extern "C" void AXI_Access_Falt() {
	int pc = core_read_pc();
	int inst = core_read_inst();
	Assert(npc_state.state != NPC_RUNNING,"axi access falt at pc=0x%08x inst=0x%08x", pc,inst);
}
static uint64_t IFU_inst_num = 0;
static uint64_t ALU_inst_num = 0;
static uint64_t LSU_read_num = 0;
static uint64_t IDU_alu_num = 0;
static uint64_t IDU_lsu_num = 0;
static uint64_t IDU_csr_num = 0;
static uint64_t IDU_jump_num = 0;
static uint64_t LSU_write_num = 0;
static int inst_cat;
extern "C" void performance_counter(int category) {
	if (category==0)
	{
		IFU_inst_num++;
	}
	else if (category==1)
	{
		ALU_inst_num++;
	}
	else if (category==2)
	{
		LSU_read_num++;
	}
	else if (category==3)
	{
		IDU_alu_num++;
		inst_cat = category;
	}
	else if (category==4)
	{
		IDU_lsu_num++;
		inst_cat = category;
	}
	else if (category==5)
	{
		IDU_csr_num++;
	}
	else if (category==6)
	{
		IDU_jump_num++;
		inst_cat = category;
	}
	else if (category==7)
	{
		LSU_write_num++;
	}
}

static uint64_t Load_Store_cycle_num = 0;
static uint64_t ALU_cycle_num = 0;
static uint64_t jump_cycle_num = 0;

static uint64_t cache_acc_num = 0;
static uint64_t cache_hit_num = 0;
static uint64_t cache_acc_cycle_num = 0;

void cycle_record(int cycle) {
	if (inst_cat==4)
	{
		Load_Store_cycle_num += (uint64_t)cycle;
	}
	else if (inst_cat==3)
	{
		ALU_cycle_num += (uint64_t)cycle;
	}
	else if (inst_cat==6)
	{
		jump_cycle_num += (uint64_t)cycle;
	}
	inst_cat = 0;
}

void performance_statistic() {
	Log("total IFU instructions = %lu", IFU_inst_num);
	Log("total ALU instructions = %lu", ALU_inst_num);
	Log("total IDU ALU instructions = %lu", IDU_alu_num);
	Log("total LSU reads = %lu", LSU_read_num);
	Log("total LSU writes = %lu", LSU_write_num);
	Log("total IDU LSU instructions = %lu", IDU_lsu_num);
	Log("total IDU CSR instructions = %lu", IDU_csr_num);
	Log("total IDU jump instructions = %lu", IDU_jump_num);
	Log("average Load Store inst cycle = %lu", Load_Store_cycle_num/IDU_lsu_num);
	Log("average ALU inst cycle = %lu", ALU_cycle_num/IDU_alu_num);
	Log("average jump inst cycle = %lu", jump_cycle_num/IDU_jump_num);
	Log("average icache cycle = %lu", cache_acc_cycle_num/cache_acc_num);
	Log("average icache hit rate = %f", cache_hit_num/cache_acc_num);
}


extern "C" void icache_access_rcd(char hit, int access_time) {
	cache_acc_num++;
	cache_acc_cycle_num += access_time;
	if (hit)
	{
		cache_hit_num++;
		assert(access_time==1);
	}
}