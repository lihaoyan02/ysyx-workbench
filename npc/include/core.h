#ifndef __CORE_H__
#define __CORE_H__

#include <verilated.h>
#include <Vtop.h>
#include <Vtop__Dpi.h> 
#include "svdpi.h"

#include "generated/autoconf.h"
#ifdef CONFIG_TRACE_WAVE
#include "verilated_vcd_c.h"
extern VerilatedVcdC* tfp; 
#endif

extern VerilatedContext* contextp;
extern Vtop* top;

uint32_t core_read_inst();

uint32_t core_read_pc();

uint32_t core_read_dnpc();

uint32_t core_read_reg(uint32_t idx);

uint32_t core_read_state();

#endif
