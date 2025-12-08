VERILATOR_FLAGS = -cc --exe --trace-fst --build -Wall
VERILATOR_INPUT = vsrc/top.v csrc/tb.cpp

all: sim
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	verilator $(VERILATOR_FLAGS) $(VERILATOR_INPUT)
	@echo "Write this Makefile by your self."

include ../Makefile
include $(NVBOARD_HOME)/scripts/nvboard.mk
