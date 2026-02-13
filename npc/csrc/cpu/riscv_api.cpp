#include <core.h>

VerilatedContext* contextp = NULL;
Vtop* top = NULL;
VerilatedVcdC* tfp = NULL;

uint32_t core_read_inst() {
	const svScope scope = svGetScopeFromName("TOP.top.u_IFU");
	assert(scope); 
	svSetScope(scope);
	return read_inst(); 
}

uint32_t core_read_reg(uint32_t idx) {
	assert(idx<16);
	const svScope scope = svGetScopeFromName("TOP.top.u_gpr");
	assert(scope); 
	svSetScope(scope);
	return read_reg(idx);
}
