#ifndef __NPC_MEMORY_H__
#define __NPC_MEMORY_H__

#define MEM_MAX 0x8000000 
#define MEM_BASE 0

//0x80000000 
#include <cstdint>
static bool in_mem(uint32_t addr) { 
	return addr - MEM_BASE < MEM_MAX; 
}

extern "C" int pmem_read(int raddr, int len);

extern "C" void pmem_write(int waddr, int wdata, char wmask);

int load_mem(const char* img);

#endif
