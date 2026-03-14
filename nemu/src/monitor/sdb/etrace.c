#include <common.h> 
#include <cpu/decode.h>

word_t isa_csr_idx2val(int idx);
void etrace_rcd(Decode *s) {
	word_t inst = s->isa.inst;
	if (inst ==0x00000073) {
		Log("[etrace]: pc=0x%08x\nmepc=0x%08x, mecause=0x%x, mestatus=0x%x, mtvec=0x%08x\n",
				s->pc, isa_csr_idx2val(0), isa_csr_idx2val(1), isa_csr_idx2val(2), isa_csr_idx2val(3));
	}
}	
