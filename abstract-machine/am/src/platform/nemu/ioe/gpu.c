#include <am.h>
#include <nemu.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
	/*
	int i;
	int w = inl(VGACTL_ADDR)>>16;
	int h = inw(VGACTL_ADDR);
	uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
	for (i = 0; i < w * h; i ++) fb[i] = i;
	outl(SYNC_ADDR, 1);
	*/
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = inl(VGACTL_ADDR)>>16, .height = inw(VGACTL_ADDR),
    .vmemsz = inl(VGACTL_ADDR)>>16 * inw(VGACTL_ADDR) * sizeof(uint32_t)
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
	uint32_t x = ctl->x;
	uint32_t y = ctl->y;
	uint32_t pos = y * ctl->w + x;
	uintptr_t fb = (uintptr_t)FB_ADDR + pos*4;
	//uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
	outl(fb, *(uint32_t *)ctl->pixels);
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
