#include <memory.h>
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <Vtop__Dpi.h>

static uint8_t pmem[MEM_MAX];

extern "C" int pmem_read(int raddr, int len) {
	uint8_t* paddr = pmem + ((unsigned)raddr & ~0x3u);
	switch (len) {
		case 1: return *(uint8_t  *)paddr;
		case 2: return *(uint16_t *)paddr;
		case 4: return *(uint32_t *)paddr;
		default: assert(0);
	}
}	

extern "C" void pmem_write(int waddr, int wdata, char wmask) {
	uint8_t* paddr = pmem + (unsigned)waddr;
	switch (wmask) {
		case 0x1: *(uint8_t *)paddr = (uint8_t)wdata; break;
		case 0x3: *(uint16_t *)paddr = (uint16_t)wdata; break;
		case 0xf: *(uint32_t *)paddr = wdata; break;
		default: assert(0);
	}
}

int load_mem(){
	FILE *file;
	file = fopen("./logisim-bin/mem.bin","rb");
	if(file==NULL){
		printf("fail to open the file\n");
		return 1;
	}
	//obtain the file size
	fseek(file, 0, SEEK_END);
	long file_size = ftell(file);
	fseek(file, 0, SEEK_SET);
	int count = file_size / sizeof(uint8_t);
	//read to the memory
	size_t n = fread(pmem, sizeof(uint8_t), MEM_MAX, file);
	if(n != count){
		printf("read error or file truncated!\n"); 
	}
	fclose(file);
	//pmem_write(0x228, 0x00100073, 0b1111);
	pmem_write(0x1220, 0x00100073, 0b1111);
	//printf("0x1220 = %08x\n",pmem_read(0x1220,4)); 
	return 0;
}
