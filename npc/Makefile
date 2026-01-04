TOPNAME = top
NXDC_FILES = constr/top.nxdc
NPC_DIR := $(shell pwd)
INC_PATH = $(NPC_DIR)/include

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD -cc --build \
				-O3 --x-assign fast --x-initial fast --trace-vcd 
BUILD_DIR = $(NPC_DIR)/build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

$(shell mkdir -p $(BUILD_DIR))

# project source
VSRCS = $(wildcard vsrc/*.v)
CSRCS = $(wildcard csrc/*.cpp)
# CSRCS += $(SRC_AUTO_BIND)
# $(NVBOARD_ARCHIVE)

# rules for NVBoard
# include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS)

all: sim
	@echo "Write this Makefile by your self."

$(BIN): $(VSRCS) $(CSRCS) 
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
	#	$(addprefix -LDFLAGS , $(LDFLAGS)) 

run: $(BIN)
	@$^

clean:
	rm -rf $(BUILD_DIR)
sim: $(BIN) 
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "Write this Makefile by your self."

include ../Makefile
