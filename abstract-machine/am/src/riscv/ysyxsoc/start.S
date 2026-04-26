.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero

  # 初始化栈指针，指向链接器定义的栈顶地址
  la sp, _stack_pointer

  # 将初始化代码段（以及只读数据）从加载区复制到运行时数据区
  la a0, _text_load    # 源地址：数据加载区
  la a1, _text_start   # 目标地址：数据段起始
  la a2, _text_end     # 数据段结束地址

  # 如果代码段为空，则跳过复制
  beq a1, a2, 2f
1:
  lw t0, 0(a0)         # 从加载区读取一个字
  sw t0, 0(a1)         # 存储到代码段
  addi a0, a0, 4       # 源地址前进 4 字节
  addi a1, a1, 4       # 目标地址前进 4 字节
  blt a1, a2, 1b       # 继续复制直到到达结束地址
2:
  # 将初始化数据段从加载区复制到运行时数据区
  la a0, _data_load    # 源地址：数据加载区
  la a1, _data_start   # 目标地址：数据段起始
  la a2, _data_end     # 数据段结束地址

  # 如果数据段为空，则跳过复制
  beq a1, a2, 4f
3:
  lw t0, 0(a0)         # 从加载区读取一个字
  sw t0, 0(a1)         # 存储到数据段
  addi a0, a0, 4       # 源地址前进 4 字节
  addi a1, a1, 4       # 目标地址前进 4 字节
  blt a1, a2, 3b       # 继续复制直到到达结束地址

4:
  # 清零 BSS 段，保证未初始化全局变量为 0
  la a0, _bss_start    # BSS 段起始地址
  la a1, _bss_end      # BSS 段结束地址
  beq a0, a1, 6f       # 若 BSS 为空则跳过清零

5:
  sw zero, 0(a0)       # 将当前地址的 4 字节清零
  addi a0, a0, 4       # 前进到下一个字
  blt a0, a1, 5b       # 继续清零直到结束

6:
  # 启动trm/环境初始化
  call _trm_init


.size _start, . - _start
