CFLAGS=-march=rv32e -mabi=ilp32e -nostdlib -ffreestanding
IMAGE=char-test
# ffreestanding
all:
	riscv64-linux-gnu-gcc $(CFLAGS) -o $(IMAGE).elf $(IMAGE).c
	riscv64-linux-gnu-objdump -d $(IMAGE).elf > $(IMAGE).txt
	riscv64-linux-gnu-objcopy -j .text -O binary $(IMAGE).elf $(IMAGE).bin