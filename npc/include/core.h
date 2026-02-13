#ifndef __CORE_H__
#define __CORE_H__

#include <verilated.h>
#include <Vtop.h>
#include <Vtop__Dpi.h> 
#include "svdpi.h"
#include "verilated_vcd_c.h"

extern VerilatedContext* contextp;
extern Vtop* top;
extern VerilatedVcdC* tfp; 

uint32_t core_read_inst();

uint32_t core_read_reg(uint32_t idx);

#endif
