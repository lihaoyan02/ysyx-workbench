
CC ?= gcc
CFLAGS ?= -O2 -std=c11 -Wall
CPPFLAGS += -Iinclude
LDFLAGS =

BUILD_DIR ?= build
OBJDIR := $(BUILD_DIR)/obj
BIN := $(BUILD_DIR)/cachesim

SRC_DIR ?= src
PCFILE ?= sum-riscv32e-ysyxsoc-pc.bin
LOGFILE ?= $(BUILD_DIR)/out.log

SRCS := $(wildcard $(SRC_DIR)/*.c)
OBJS := $(patsubst $(SRC_DIR)/%.c,$(OBJDIR)/%.o,$(SRCS))

all: $(BIN)

$(BIN): $(OBJS) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: $(SRC_DIR)/%.c | $(OBJDIR)
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

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
