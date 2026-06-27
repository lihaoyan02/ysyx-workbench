
#include <common.h>
#include <device/map.h>

#define SRAM_ADDR 0x0f000000
#define SRAM_SIZE 0x2000

static void *sram_space = NULL;

void init_sram() {
  sram_space = new_space(SRAM_SIZE);
  assert(sram_space != NULL);
  add_mmio_map("sram", SRAM_ADDR, sram_space, SRAM_SIZE, NULL);
  memset(sram_space, 0, SRAM_SIZE);
}
