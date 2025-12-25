SHELL := /bin/bash

TOPLEVEL_LANG ?= verilog

TOPLEVEL ?= axi_unwrap

MODULE ?= tb_axi

LIST_DIR ?= $(CURDIR)/rtl/lists
LIST_RTL ?= $(LIST_DIR)/files_rtl.lst

SIM ?= questa
SIM_ARGS := -suppress 12110 -autofindloop -voptargs="\""-access=rw+/. -debug,cell"\"" -suppress 12130
CCTB_DIR ?= $(CURDIR)/.cache/cctb
SIM_BUILD ?= $(CCTB_DIR)/$(MODULE)

VERILOG_SOURCES ?= 
VERILOG_SOURCES += $$(cat $(LIST_RTL))

VENV_DIR ?= $(CCTB_DIR)/.venv

COCOTB_MAKEFILES := $$(cocotb-config --makefiles)

WAVES ?= 1

.PHONY: run clean



run: $(VENV_DIR)/bin/activate
	@mkdir -p $(SIM_BUILD)
	source $(VENV_DIR)/bin/activate \
	make -f $(COCOTB_MAKEFILES)/Makefile.sim TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
	TOPLEVEL=$(TOPLEVEL) MODULE=$(MODULE) SIM=$(SIM) SIM_BUILD=$(SIM_BUILD) \
	SIM_ARGS='$(SIM_ARGS)' WAVES=$(WAVES) \
	VERILOG_SOURCES="$(VERILOG_SOURCES)"

wave:
	vsim -view $(SIM_BUILD)/vsim.wlf

$(VENV_DIR)/bin/activate: cctb/build/user_requirements.txt cctb/build/requirements.txt
	python3 -m venv $(VENV_DIR)
	source $(VENV_DIR)/bin/activate; \
	pip install -r cctb/build/requirements.txt; \
	pip install -r cctb/build/user_requirements.txt

clean:
	@rm -rf $(SIM_BUILD)
