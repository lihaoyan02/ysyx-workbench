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

void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
int is_exit_status_bad();

word_t expr(char *e, bool *success);
void test_expr() {
	FILE *fp = fopen("tools/gen-expr/input","r");
	assert(fp != NULL);
	uint32_t exp_result;
	char expression[65536];
	int failtimes = 0;
	uint32_t result;
	bool success = true;
	int linenum = 0;
	while (fscanf(fp, "%d %[^\n]", &exp_result, expression)==2) {
		printf("%d\n",linenum);
		linenum++;
		result = expr(expression,&success);
		if (result!=exp_result) { 
			failtimes++;
		}
	}
	fclose(fp);
	printf("test fail = %d\n",failtimes);
}

int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif
	
	//test_expr();
  /* Start engine. */
  engine_start();

  return is_exit_status_bad();
}
