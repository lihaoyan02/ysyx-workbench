
CC = gcc
CFLAGS = -O2 -std=c11 -Wall
LDFLAGS =

BUILD_DIR ?= build
OBJDIR := $(BUILD_DIR)/obj
BIN := $(BUILD_DIR)/cachesim

PCFILE ?= sum-riscv32e-ysyxsoc-pc.bin
LOGFILE ?= $(BUILD_DIR)/out.log

all: $(BIN)

$(BIN): $(OBJDIR)/main.o $(OBJDIR)/cache.o | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/main.o: main.c cache.h | $(OBJDIR)
	$(CC) $(CFLAGS) -c main.c -o $@

$(OBJDIR)/cache.o: cache.c cache.h | $(OBJDIR)
	$(CC) $(CFLAGS) -c cache.c -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJDIR):
	mkdir -p $(OBJDIR)

run: all
	./$(BIN) $(PCFILE) $(LOGFILE)
	@echo "Log written to $(LOGFILE)"

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean run
