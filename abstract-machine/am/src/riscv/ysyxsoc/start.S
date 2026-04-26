.section entry, "ax"
.globl _start
.type _start, @function

_start:
  mv s0, zero

  # 初始化栈指针，指向链接器定义的栈顶地址
  la sp, _stack_pointer

  # 将初始化代码段（以及只读数据）从加载区复制到运行时数据区
  la a0, _ssbl_load    # 源地址：数据加载区
  la a1, _ssbl_start   # 目标地址：数据段起始
  la a2, _ssbl_end     # 数据段结束地址

  # 如果代码段为空，则跳过复制
  beq a1, a2, 2f
1:
  lw t0, 0(a0)         # 从加载区读取一个字
  sw t0, 0(a1)         # 存储到代码段
  addi a0, a0, 4       # 源地址前进 4 字节
  addi a1, a1, 4       # 目标地址前进 4 字节
  blt a1, a2, 1b       # 继续复制直到到达结束地址
2:
  call _ssbl_entry


.size _start, . - _start
