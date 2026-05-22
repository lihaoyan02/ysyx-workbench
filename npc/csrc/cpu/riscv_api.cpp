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
	}
	else if (category==4)
	{
		IDU_lsu_num++;
	}
	else if (category==5)
	{
		IDU_csr_num++;
	}
	else if (category==6)
	{
		IDU_jump_num++;
	}
}

void performance_statistic() {
	Log("total IFU instructions = %lu", IFU_inst_num);
	Log("total ALU instructions = %lu", ALU_inst_num);
	Log("total LSU reads = %lu", LSU_read_num);
	Log("total IDU ALU instructions = %lu", IDU_alu_num);
	Log("total IDU LSU instructions = %lu", IDU_lsu_num);
	Log("total IDU CSR instructions = %lu", IDU_csr_num);
	Log("total IDU jump instructions = %lu", IDU_jump_num);
}