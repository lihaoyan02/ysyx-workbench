
#include <common.h>
#include <device/map.h>

#define SDRAM_ADDR 0xa0000000
#define SDRAM_SIZE 0x4000

static void *sdram_space = NULL;

void init_sdram() {
  sdram_space = malloc(SDRAM_SIZE);
  assert(sdram_space != NULL);
  add_mmio_map("sdram", SDRAM_ADDR, sdram_space, SDRAM_SIZE, NULL);
  memset(sdram_space, 0, SDRAM_SIZE);
}
