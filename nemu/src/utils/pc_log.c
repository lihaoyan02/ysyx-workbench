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

#include <common.h>

#ifndef CONFIG_TARGET_AM
static FILE *pc_log_fp = NULL;

void init_pc_log(const char *file_name) {
  pc_log_fp = NULL;
  if (file_name != NULL) {
    pc_log_fp = fopen(file_name, "wb");
    Assert(pc_log_fp, "Can not open '%s'", file_name);
    Log("PC log is written to %s", file_name);
  }
}

void record_pc(uint64_t pc) {
  if (pc_log_fp == NULL) {
    return;
  }
  size_t ret = fwrite(&pc, sizeof(pc), 1, pc_log_fp);
  Assert(ret == 1, "Failed to write pc to file");
}

void close_pc_log(void) {
  if (pc_log_fp) {
    fclose(pc_log_fp);
    pc_log_fp = NULL;
  }
}
#endif
