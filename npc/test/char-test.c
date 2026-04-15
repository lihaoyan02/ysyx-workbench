#define UART_BASE 0x10000000L
#define UART_TX 0

#define SRAM_BASE 0x0f000000
#define STACK_TOP SRAM_BASE+(1024*1024)

__attribute__((naked))
void _start() {
    __asm__ volatile (
        "li sp, %0\n"
        ::"i"(STACK_TOP)
    );
    *(volatile char *)(UART_BASE + UART_TX) = 'A';
    while (1);    
}