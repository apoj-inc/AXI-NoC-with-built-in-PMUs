FILES_RTL_PATH := $(CURDIR)/rtl/lists/files_rtl.lst

ICARUS_PATH := $(CURDIR)/.cache/build_system/icarus
TOPLEVEL ?= tb

SIM_PATH := $(ICARUS_PATH)/$(SIM_PATH)

VCD_FILE := $(SIM_PATH)/$(VCD_FILE)

run:
	iverilog -g2012 -o $(SIM_PATH)/simv -s $(TOPLEVEL) -c $$(cat $(FILES_RTL_PATH))
	vvp $(SIM_PATH)/simv

wave:
	gtkwave $(VCD_FILE)
