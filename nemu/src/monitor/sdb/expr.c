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

#include <isa.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum {
  TK_NOTYPE = 256, TK_EQ, TK_NUM

  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", '+'},         // plus
	{"\\-", '-'},
	{"\\*", '*'},
	{"/", '/'},
	{"[0-9]+", TK_NUM},
	{"\\(", '('},
	{"\\)", ')'},
  {"==", TK_EQ}        // equal
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[32] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        switch (rules[i].token_type) {
					case '+':
						tokens[nr_token].type = '+';
						nr_token++;
						break;
					case '-':
						tokens[nr_token].type = '-';
						nr_token++;
						break;
					case '*':
						tokens[nr_token].type = '*';
						nr_token++;
						break;
					case '/':
						tokens[nr_token].type = '/';
						nr_token++;
						break;
					case TK_NUM:
						if(substr_len>31) {
							printf("the number is too long\n");
							return false;
						} else {
							tokens[nr_token].type = TK_NUM;
							strncpy(tokens[nr_token].str, substr_start, substr_len);
							tokens[nr_token].str[substr_len] = '\0';	
							nr_token++;
						}
						break;
					case '(':
						tokens[nr_token].type = '(';
						nr_token++;
						break;
					case ')':
						tokens[nr_token].type = ')';
						nr_token++;
						break;
					case TK_EQ:
						tokens[nr_token].type = TK_EQ;
						nr_token++;
						break;
          default: ;
        }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

static bool check_parentheses(int p, int q, bool *success) {
	assert(q > p);
	if(tokens[p].type != '(' || tokens[q].type != ')') {
		return false;
	} else {
		int flag = 0;
		int cnt = 0;
		for(int i=p+1; i<q; i++) {
			if (tokens[i].type == '(') {
				cnt ++;
			} else if (tokens[i].type == ')') {
				cnt --;
			}
			if (cnt == -1) {
				flag = 1; // matched internal
			} else if (cnt < -1) {
				*success = false;
				printf("Invalid format, require '(' before ')'\n");
				//panic("Invalid format, require '(' before ')'");
			}
		}
		if (cnt!=0) {
			printf("Invalid format (parentheses number not match\n");
			*success = false;
		}
		//Assert(cnt==0, "Invalid format (parentheses number not match");
		if (flag == 0) {
			return true;
		} else{
			return false;
		}
	}
}

static bool is_operator(int expr) {
	if(expr=='-' || expr=='+' || expr=='*' || expr=='/') {
		return true;
	} else {
		return false;
	}
}

static int find_main_op(int p, int q, bool* success) {
	int musk = 0;
	int main_op = 0;
	for(int i=q; i>p; i--) {
		switch (tokens[i].type) {
			case ')': musk++;
				break;
			case '(': musk--;
				break;
			case '+':
				if(musk == 0) {
					return i;
				}
				break;
			case '-':
				if (musk == 0) {
					if(is_operator(tokens[i-1].type)) {
						return i-1;
					} else {
						return i;
					}
				}
				break;
			case '*':
				if (musk == 0 && main_op ==0) {
					main_op = i;
				}
				break;
			case '/':
				if (musk == 0 && main_op ==0) {
					main_op = i;
				}
				break;
			default:;
		}
	}
	if(main_op == 0) {
		printf("Invalid format\n");
		*success = false;
	}
	//assert(main_op!=0);
	return main_op;
}

static int eval(int p, int q, bool* success) {
	if (p > q) {
		panic("Invalid format at position %d", q);
		/* bad */
	}
	else if (p == q) {
		if(tokens[p].type != TK_NUM) {
			printf("Invalid format at %d\n", p);
			*success = false;
		}
		//Assert(tokens[p].type == TK_NUM, "Invalid format at %d", p);
		return atoi(tokens[p].str);
		/* return the singel number*/
	}
	else if ((p+1)==q) {
		if(tokens[p].type != '-' || tokens[q].type != TK_NUM) {
			printf("Invalid format at %d\n", p); 
			*success = false;
		}
		//Assert(tokens[p].type == '-', "Invalid format at %d", p);
		//Assert(tokens[q].type == TK_NUM, "Invalid format at %d", q);
		return -atoi(tokens[q].str);
		/* return negative number*/
	}
	else if (check_parentheses(p, q, success) == true) {
		/* surrounded by a matched parentheses*/
		return eval(p+1, q-1, success);
	}
	else {
		int op =find_main_op(p, q, success);
		if(*success == false) {
			return 1;
		}
		int val1 =0;
		if(op!=0) {
			val1 = eval(p, op - 1, success);
		}
		int val2 = eval(op + 1, q, success);

		switch (tokens[op].type) {
			case '+': return val1 + val2;
			case '-': return val1 - val2;
			case '*': return val1 * val2;
			case '/': Assert(val2 != 0, "the denominater is zero!!!, divation at %d", op);
				return val1 / val2;
			default: assert(0);
		}
	}
	if (*success == false) {
		return 1;
	}
}

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* TODO: Insert codes to evaluate the expression. */
	int expr_result = eval(0, nr_token-1, success);
	if(*success==true) {
		printf("%d\n", expr_result);
		return (word_t)expr_result;
	}
  return 0;
}
