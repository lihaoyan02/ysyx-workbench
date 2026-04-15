/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#ifdef CONIFG_TARGET_REF_YSYXSOC
static uint8_t sram[CONFIG_SRAM_SIZE] PG_ALIGN = {};
#endif
#endif

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

#ifdef CONIFG_TARGET_REF_YSYXSOC
static word_t sram_read(paddr_t addr, int len) {
  word_t ret = host_read(sram+addr-CONFIG_SRAM_BASE, len);
  return ret;
}

static void sram_write(paddr_t addr, int len, word_t data) {
  host_write(sram+addr-CONFIG_SRAM_BASE, len, data);
}
#endif

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

word_t paddr_read(paddr_t addr, int len) {
	IFDEF(CONFIG_MTRACE,
			if(addr >= CONFIG_MTRACE_START && addr < CONFIG_MTRACE_END) {
				Log("mtrace: R addr=" FMT_PADDR ", len=%d\n", addr, len);
			}
	);
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
  IFDEF(CONIFG_TARGET_REF_YSYXSOC,if (likely(in_sram(addr))) return sram_read(addr, len))
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
	IFDEF(CONFIG_MTRACE,
			if(addr >= CONFIG_MTRACE_START && addr < CONFIG_MTRACE_END) {
				Log("mtrace: W addr=" FMT_PADDR ", len=%d data=0x%x\n", addr, len, data);
			}
	);
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  IFDEF(CONIFG_TARGET_REF_YSYXSOC,if (likely(in_sram(addr))) { sram_write(addr, len, data); return; })
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
