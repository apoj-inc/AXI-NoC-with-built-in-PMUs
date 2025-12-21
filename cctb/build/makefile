SHELL := /bin/bash

TOPLEVEL_LANG ?= verilog

TOPLEVEL ?= axi_unwrap

MODULE ?= tb_axi

LIST_DIR ?= $(CURDIR)/rtl/lists
LIST_RTL ?= $(LIST_DIR)/files_rtl.lst

SIM ?= questa
SIM_ARGS := -suppress 12110 -autofindloop -voptargs="\""-access=rw+/. -debug,cell"\"" -suppress 12130
CCTB_DIR ?= .cache/cctb
SIM_BUILD ?= $(CCTB_DIR)/$(MODULE)

VERILOG_SOURCES ?= 
VERILOG_SOURCES += $$(cat $(LIST_RTL))

COCOTB_MAKEFILES := $$(cocotb-config --makefiles)

WAVES ?= 1

.PHONY: run clean_run clean_all_runs clean_all clean_venv

run: $(CURDIR)/.venv/bin/activate
	@source $(CURDIR)/.venv/bin/activate
	@mkdir -p $(SIM_BUILD)
	@make -f $(COCOTB_MAKEFILES)/Makefile.sim TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
	TOPLEVEL=$(TOPLEVEL) MODULE=$(MODULE) SIM=$(SIM) SIM_BUILD=$(SIM_BUILD) \
	SIM_ARGS='$(SIM_ARGS)' WAVES=$(WAVES) \
	VERILOG_SOURCES="$(VERILOG_SOURCES)"

wave:
	vsim -view $(SIM_BUILD)/vsim.wlf

$(CURDIR)/.venv/bin/activate: cctb/build/user_requirements.txt cctb/build/requirements.txt
	@python3 -m venv cctb/build/venv; \
	source cctb/build/venv/bin/activate; \
	pip install -r cctb/build/requirements.txt; \
	pip install -r cctb/build/user_requirements.txt

clean_run:
	@rm -rf $(SIM_BUILD)

clean_venv:
	@rm -rf $(CURDIR)/.venv

clean_all: clean_runs clean_venv
