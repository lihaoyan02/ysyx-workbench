#include <core.h>

VerilatedContext* contextp = NULL;
Vtop* top = NULL;
VerilatedVcdC* tfp = NULL;

int core_read_inst() {
	const svScope scope = svGetScopeFromName("TOP.top.u_IFU");
	assert(scope); 
	svSetScope(scope);
	return read_inst(); 
}
