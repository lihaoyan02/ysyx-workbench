TOPNAME = top
NXDC_FILES = constr/top.nxdc
NPC_DIR := $(NPC_HOME)
INC_PATH = $(NPC_DIR)/include

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD -cc --build -sv\
				-O3 --x-assign fast --x-initial fast --trace-vcd 
BUILD_DIR = $(NPC_DIR)/build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

$(shell mkdir -p $(BUILD_DIR))

# project source
VSRCS = $(wildcard vsrc/*.v)
CSRCS = $(shell find csrc -name "*.cpp" -type f)
# CSRCS += $(SRC_AUTO_BIND)
# $(NVBOARD_ARCHIVE)

# rules for NVBoard
# include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS)

# Some convenient rules 

override ARGS ?= --log=$(BUILD_DIR)/npc-log.txt
# override ARGS += $(ARGS_DIFF)

# Command to execute NPC
IMG ?=
NPC_EXEC := $(BIN) $(ARGS) $(IMG)

LDFLAGS = -lreadline -lhistory

all: run-env
	@echo "Building NPC"

$(BIN): $(VSRCS) $(CSRCS) 
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN)) \
		$(addprefix -LDFLAGS , $(LDFLAGS)) 

run-env: $(BIN)


# image file
run: run-env
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "Write this Makefile by your self."
	$(NPC_EXEC)

clean:
	rm -rf $(BUILD_DIR)

# Include rules for menuconfig
include $(NPC_HOME)/scripts/config.mk
include ../Makefile
