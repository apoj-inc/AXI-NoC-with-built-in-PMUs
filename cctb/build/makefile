SHELL := /bin/bash

TOPLEVEL_LANG ?= verilog

CACHE_DIR ?= $(CURDIR)/.cache

COCOTB_TOPLEVEL ?= tb_uart_loop
COCOTB_TEST_MODULES ?= tb_example
TB_DIR ?= $(CURDIR)/tb
TB_EXT ?= sv

LIST_DIR ?= $(CURDIR)/rtl/lists
LIST_RTL ?= $(LIST_DIR)/files_rtl.lst

ifndef INCLUDE_DIRS
INCLUDE_DIRS :=
INCLUDE_DIRS += $(CURDIR)/rtl/axi
INCLUDE_DIRS += $(CURDIR)/rtl/cores/src
INCLUDE_DIRS += $(CURDIR)/tests/inc
endif

TB_FILES ?=  $(foreach file,$(shell find tb/ -type f -name '*.sv'),$(CURDIR)/$(file))

SIM ?= questa
SIM_ARGS := -suppress 12110 -autofindloop -suppress 12130
CCTB_DIR ?= $(CACHE_DIR)/cctb
SIM_BUILD ?= $(CCTB_DIR)/$(COCOTB_TEST_MODULES)

VENV_DIR ?= $(CACHE_DIR)/.venv

WAVES ?= 1

VERILOG_SOURCES ?= $(foreach file,$(shell cat $(LIST_RTL)),$(CURDIR)/$(file))

TOPLEVEL_LIBRARY ?= work

.PHONY: run wave clean_module

run: $(VENV_DIR) $(VERILOG_SOURCES)
	@mkdir -p $(SIM_BUILD)
	@cp -r $(TB_DIR)/$(COCOTB_TEST_MODULES) $(SIM_BUILD)/..
	source $(VENV_DIR)/bin/activate; \
	cd $(SIM_BUILD); \
	make -f $(shell $(VENV_DIR)/bin/cocotb-config --makefiles)/Makefile.sim TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
	TOPLEVEL=$(COCOTB_TOPLEVEL) MODULE=$(COCOTB_TEST_MODULES) SIM=$(SIM) SIM_BUILD=$(CCTB_DIR) \
	SIM_ARGS='$(SIM_ARGS)' WAVES=$(WAVES) VERILOG_INCLUDE_DIRS="$(INCLUDE_DIRS)" TOPLEVEL_LIBRARY=$(TOPLEVEL_LIBRARY) \
	VERILOG_SOURCES="$(CURDIR)/tests/test.svh $(VERILOG_SOURCES) $(TB_FILES)"

wave:
	vsim -view $(SIM_BUILD)/vsim.wlf

$(VENV_DIR): cctb/build/user_requirements.txt cctb/build/requirements.txt
	python3 -m venv $(VENV_DIR)
	source $(VENV_DIR)/bin/activate; \
	pip install -r cctb/build/requirements.txt; \
	pip install -r cctb/build/user_requirements.txt


clean_module:
	@rm -rf $(SIM_BUILD)
