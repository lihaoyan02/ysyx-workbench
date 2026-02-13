
#ifndef __RISCV_REG_H__
#define __RISCV_REG_H__

#include <common.h>

static inline int check_reg_idx(int idx) {
	assert(idx >= 0 && idx < 16);
	return idx;
}

static inline const char* reg_name(int idx) {
	extern const char* regs[];
	return regs[check_reg_idx(idx)];
}

void reg_display();

uint32_t reg_str2val(const char *s, bool *success);

#endif
