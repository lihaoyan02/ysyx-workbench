#include <core.h>
#include <reg.h>

const char *regs[] = {
	"$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
	"s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5"
};

void reg_display() {
	for(int i=0; i < 16; i++) {
		printf("%s = %x\t", reg_name(i), core_read_reg(i));
	}
	printf("\n");
}
