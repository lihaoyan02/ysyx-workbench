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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char buf[65536] = {};
static unsigned int buf_ptr=0;
static int overflow_flag = 0;
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

static uint32_t choose(uint32_t n) {
	assert(n>0);
	return rand() % n;
}

static void gen(char a) {
	if (buf_ptr < 65535) {
		sprintf(buf+buf_ptr, "%c", a);
		buf_ptr++;
	} else {
		overflow_flag = 1;
	}
}

static void gen_rand_op() {
	switch (choose(4)) {
		case 0: gen('+'); break;
		case 1: gen('-'); break;
		case 2: gen('*'); break;
		default: gen('/'); break;
	}
}

static void gen_num() {
	uint32_t rand_num = choose(10000);
	char num_str[32];
 	sprintf(num_str, "%u", rand_num);
	for (int i=0; num_str[i] != '\0'; i++) {
		gen(num_str[i]);
	}
}

static void gen_rand_expr() {
	switch (choose(4)) {
		case 0: gen_num(); break;
		case 1: gen('('); gen_rand_expr(); gen(')'); break;
		case 2: gen(' '); gen_rand_expr(); break;// genarate random space
		default: gen_rand_expr(); gen_rand_op(); gen_rand_expr(); break;
	}
  buf[buf_ptr] = '\0';
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
		buf_ptr = 0;
    gen_rand_expr();
		if (overflow_flag==1) {
			overflow_flag = 0;
			continue;
		}

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc -Wall -Werror /tmp/.code.c -o /tmp/.expr > /dev/null");// detect divide 0
    if (ret != 0) continue;

		ret = system("/tmp/.expr > /dev/null");
		if (ret != 0) continue; // detect divide 0

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%u %s\n", result, buf);
  }
  return 0;
}
