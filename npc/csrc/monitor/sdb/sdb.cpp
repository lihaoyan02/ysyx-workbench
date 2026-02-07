#include <memory.h>
#include <cpu.h>

static int is_batch_mode = true;

static int cmd_c(char *args) {
	cpu_exec(-1);
	return 0;
}

void sdb_mainloop() {
	if (is_batch_mode) {
		cmd_c(NULL);
		return;
	}


}
