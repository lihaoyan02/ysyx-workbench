#ifndef __NPC_MEMORY_H__
#define __NPC_MEMORY_H__

#define MEM_MAX 0x8000000 
extern "C" int pmem_read(int raddr, int len);

extern "C" void pmem_write(int waddr, int wdata, char wmask);

int load_mem(const char* img);

#endif
