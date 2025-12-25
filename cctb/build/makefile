SHELL := /bin/bash

TOPLEVEL_LANG ?= verilog

WORK_DIR ?= $(CURDIR)/.cache/questa/WORK_DIR

TB_MODULE ?= tb_bridge
TB_DIR ?= $(CURDIR)/tb
TB_EXT ?= sv

LIST_DIR ?= $(CURDIR)/rtl/lists
LIST_RTL ?= $(LIST_DIR)/files_rtl.lst

SIM ?= questa
SIM_ARGS := -suppress 12110 -autofindloop -suppress 12130
CCTB_DIR ?= $(CURDIR)/.cache/cctb
SIM_BUILD ?= $(CCTB_DIR)/$(TB_MODULE)

VENV_DIR ?= $(CCTB_DIR)/.venv

WAVES ?= 1

VERILOG_SOURCES ?= $(foreach file,$(shell cat $(LIST_RTL)), $(CURDIR)/$(file))

.PHONY: run clean

run: $(VENV_DIR) $(VERILOG_SOURCES)
	@mkdir -p $(SIM_BUILD) $(WORK_DIR)
	@vlib $(WORK_DIR)
	@vmap work $(WORK_DIR)

	@cp -r $(TB_DIR)/$(TB_MODULE) $(SIM_BUILD)/..
	source $(VENV_DIR)/bin/activate; \
	make -f $(shell $(VENV_DIR)/bin/cocotb-config --makefiles)/Makefile.sim TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
	COCOTB_TOPLEVEL=$(TB_MODULE) MODULE=$(TB_MODULE) SIM=$(SIM) SIM_BUILD=$(SIM_BUILD) \
	SIM_ARGS='$(SIM_ARGS)' WAVES=$(WAVES) \
	VERILOG_SOURCES="$(VERILOG_SOURCES)"

wave:
	vsim -view $(SIM_BUILD)/vsim.wlf

$(VENV_DIR): cctb/build/user_requirements.txt cctb/build/requirements.txt
	python3 -m venv $(VENV_DIR)
	source $(VENV_DIR)/bin/activate; \
	pip install -r cctb/build/requirements.txt; \
	pip install -r cctb/build/user_requirements.txt

clean:
	@rm -rf $(SIM_BUILD)
