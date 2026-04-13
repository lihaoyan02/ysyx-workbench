#include <core.h>

VerilatedContext* contextp = NULL;
Vtop* top = NULL;
#ifdef CONFIG_TRACE_WAVE
VerilatedVcdC* tfp = NULL;
#endif 

uint32_t core_read_inst() {
	const svScope scope = svGetScopeFromName("TOP.top.u_core.u_IFU");
	assert(scope); 
	svSetScope(scope);
	return read_inst(); 
}

uint32_t core_read_pc() {
	const svScope scope = svGetScopeFromName("TOP.top.u_core.u_IFU");
	assert(scope); 
	svSetScope(scope);
	return read_pc(); 
}

uint32_t core_read_dnpc() {
	const svScope scope = svGetScopeFromName("TOP.top.u_core.u_IFU");
	assert(scope); 
	svSetScope(scope);
	return read_dnpc(); 
}

uint32_t core_read_reg(uint32_t idx) {
	assert(idx<16);
	const svScope scope = svGetScopeFromName("TOP.top.u_core.u_gpr");
	assert(scope); 
	svSetScope(scope);
	return read_reg(idx);
}

uint32_t core_read_state() {
	const svScope scope = svGetScopeFromName("TOP.top.u_core.u_IFU");
	assert(scope); 
	svSetScope(scope);
	return read_state();
}
