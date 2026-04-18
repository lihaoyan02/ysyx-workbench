#include <am.h>
#include <klib-macros.h>
#include <riscv/riscv.h>

extern char _heap_start;
extern char _heap_end;
int main(const char *args);

#define UART_BASE 0x10000000
#define UART_FCR (UART_BASE + 0x02) // FIFO Control Register
#define UART_LCR (UART_BASE + 0x03) // Line Control Register
#define UART_LSR (UART_BASE + 0x05) // Line Status Register

Area heap = RANGE(&_heap_start, &_heap_end);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

void init_uart() {
	// 115200 bps, 8N1
	outb(UART_LCR, 0x83); // Divisor Latch Access Bit (DLAB) set
	outb(UART_BASE + 0x00, 0x01); // Set divisor to 1 (LSB) 115200 bps
	outb(UART_BASE + 0x01, 0x00); //                  (MSB)

	outb(UART_LCR, 0x03); // 8 bits, no parity, one stop bit
	outb(UART_FCR, 0x07); // Enable FIFO, clear RX/TX FIFO
}
void putch(char ch) {
	// wait for Transmitter Holding Register (THR) empty
	while ((inb(UART_LSR) & 0x20)==0) ;
	outb(UART_BASE, ch);
}

void halt(int code) {
	asm volatile("mv a0, %0; ebreak" : :"r"(code));
	while(1);
}

//#include <stdio.h>
void _trm_init() {
	/*
	uint32_t marchid;
	uint32_t mvendorid;
	asm volatile("csrr %0, marchid":"=r" (marchid));
	asm volatile("csrr %0, mvendorid":"=r" (mvendorid));
	char *arch_str = (char*)&mvendorid;
	printf("%c%c%c%c-%d\n",arch_str[3],arch_str[2],arch_str[1],arch_str[0],marchid);
	*/
	init_uart();
  	int ret = main(mainargs);
  	halt(ret);
}
