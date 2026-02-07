#include <memory.h>
#include <assert.h>
#include <Vtop__Dpi.h>
#include <chrono>
#include <common.h>

static uint8_t pmem[MEM_MAX];
static uint32_t rtc_port[2];
static uint64_t boot_time = 0;

static uint64_t get_time_internal() {
	using namespace std::chrono;
	return duration_cast<microseconds>(
			steady_clock::now().time_since_epoch()
			).count();
}

uint64_t get_time() {
	if (boot_time == 0) boot_time = get_time_internal();
	uint64_t now = get_time_internal();
	return now - boot_time;
}

static void rtc_port_update() {
	uint64_t us = get_time();
	rtc_port[0] = (uint32_t)us;
	rtc_port[1] = us >> 32;
}

extern "C" int pmem_read(int raddr) {
	if(in_mem((uint32_t)raddr)) {
		uint8_t* paddr = pmem + ((unsigned)raddr & ~0x3u) - MEM_BASE;
		return *(uint32_t *)paddr;
		/*
		switch (len) {
			case 1: return *(uint8_t  *)paddr;
			case 2: return *(uint16_t *)paddr;
			case 4: return *(uint32_t *)paddr;
			default: assert(0);
		}
		*/
	} else if (raddr == 0xa0000048) {
		return rtc_port[0];
	} else if (raddr == 0xa0000048+4) {
		rtc_port_update();
		return rtc_port[1];
	}else {
		printf("illegal access for pmem\n");
		assert(0);
	}
}	

extern "C" void pmem_write(int waddr, int wdata, char wmask) {
	if(in_mem((uint32_t)waddr)) {
		uint8_t* paddr = pmem + (unsigned)waddr - MEM_BASE;
		switch (wmask) {
			case 0x1: *(uint8_t *)paddr = (uint8_t)wdata; break;
			case 0x3: *(uint16_t *)paddr = (uint16_t)wdata; break;
			case 0xf: *(uint32_t *)paddr = wdata; break;
			default: assert(0);
		}
	} else if (waddr == 0x10000000){
		putchar((uint8_t)wdata);
	} else {
		printf("illegal access for pmem\n");
		assert(0);
	}
}

long load_mem(const char *img){
	FILE *file;
	file = fopen(img,"rb");
	Assert(file, "Can not open '%s'", img);

	//obtain the file size
	fseek(file, 0, SEEK_END);
	long file_size = ftell(file);

	Log("The image is %s, size = %ld", img, file_size);

	fseek(file, 0, SEEK_SET);
	int count = file_size / sizeof(uint8_t);
	//read to the memory
	size_t n = fread(pmem, file_size, 1, file);
	assert(n == 1);

	fclose(file);
	//pmem_write(0x228, 0x00100073, 0b1111);
	//pmem_write(0x1220, 0x00100073, 0b1111);
	//printf("0x1220 = %08x\n",pmem_read(0x1220,4)); 
	return file_size;
}
