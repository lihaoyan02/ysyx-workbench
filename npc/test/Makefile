CFLAGS=-march=rv32e -mabi=ilp32e -nostdlib -ffreestanding
BUILD_TEST_DIR=./build/
IMAGE=char-test
TARGET_FILE=$(BUILD_TEST_DIR)char-test
$(shell mkdir -p $(BUILD_TEST_DIR))
# ffreestanding
all:
	riscv64-linux-gnu-gcc $(CFLAGS) -o $(TARGET_FILE).elf $(IMAGE).c
	riscv64-linux-gnu-objdump -d $(TARGET_FILE).elf > $(TARGET_FILE).txt
	riscv64-linux-gnu-objcopy -j .text -O binary $(TARGET_FILE).elf $(TARGET_FILE).bin