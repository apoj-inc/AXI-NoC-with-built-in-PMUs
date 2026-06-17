SHELL := /bin/bash

BUILD_SYSTEM_DIR ?= $(CURDIR)/build_system

CCTB_MAKEFILE ?= $(CURDIR)/cctb/build/makefile
QUARTUS_MAKEFILE ?= $(BUILD_SYSTEM_DIR)/quartus/makefile

CACHE_DIR ?= $(CURDIR)/.cache
RTL_PATH  ?= $(CURDIR)/rtl
VENV_DIR ?= $(CACHE_DIR)/.venv
COCOTB_DIR ?= $(CACHE_DIR)/cctb

INCDIRS_PATH ?= $(RTL_PATH)/lists/incdirs.lst
INCLUDE_DIRS ?= $(foreach file,$(shell cat $(INCDIRS_PATH) | grep -v "#"),$(CURDIR)/$(file))

LIST_DIR ?= $(RTL_PATH)/lists
LIST_RTL ?= $(LIST_DIR)/files_rtl.lst
VERILOG_SOURCES ?= $(foreach file,$(shell cat $(LIST_RTL) | grep -v "#"),$(CURDIR)/$(file))

TB_DIR ?= $(CURDIR)/tb
TESTS_DIRS ?= $(sort $(dir $(wildcard $(TB_DIR)/tb_*/)))
TB_FILES ?=  $(foreach file,$(shell find $(TB_DIR)/tb_* -type f -name '*.sv'),$(file))

BUILD_DIR   ?= $(COCOTB_DIR)
TESTS_DIR   ?= $(BUILD_DIR)/tests
LOGS_DIR    ?= $(TESTS_DIR)/logs
RESULTS_DIR ?= ${LOGS_DIR}/results

SIM ?= questa-qisqrun
BUILD_ARGS ?= -suppress 13314 -suppress 14408
SIM_ARGS ?= -suppress 12110 -autofindloop -suppress 12130

ifndef GENERAL_TOPLEVEL
COCOTB_TOPLEVEL     ?= tb_uart_loop
COCOTB_TEST_MODULES ?= tb_example
else
COCOTB_TOPLEVEL     ?= $(GENERAL_TOPLEVEL)
COCOTB_TEST_MODULES ?= $(GENERAL_TOPLEVEL)
endif

TOPLEVEL ?= toplevel
DEVICE_FAMILY ?= "{Cyclone V}"
DEVICE_PART ?= "5CGXFC9E7F35C8"

ARGS ?=

.PHONY: all test clean run_pytest run_quartus
all: test

test: $(VENV_DIR)
	make -f $(CCTB_MAKEFILE) run CACHE_DIR=$(CACHE_DIR) \
	VENV_DIR=$(VENV_DIR) INCLUDE_DIRS="$(INCLUDE_DIRS)" \
	COCOTB_TEST_MODULES=$(COCOTB_TEST_MODULES) \
	COCOTB_TOPLEVEL=$(COCOTB_TOPLEVEL)

wave: $(VENV_DIR)
	make -f $(CCTB_MAKEFILE) wave CACHE_DIR=$(CACHE_DIR) \
	VENV_DIR=$(VENV_DIR) INCLUDE_DIRS="$(INCLUDE_DIRS)" \
	COCOTB_TEST_MODULES=$(COCOTB_TEST_MODULES) \
	COCOTB_TOPLEVEL=$(COCOTB_TOPLEVEL) \
	SIM=$(SIM)

run_pytest: $(VENV_DIR)
	@export TESTS_DIRS="$(TESTS_DIRS)"; \
	export INCLUDE_DIRS="$(INCLUDE_DIRS)"; \
	export VERILOG_SOURCES="$(VERILOG_SOURCES) $(TB_FILES)"; \
	export LOGS_DIR=${LOGS_DIR}; \
	export RESULTS_DIR=${RESULTS_DIR}; \
	export TESTS_DIR=${TESTS_DIR}; \
	export BUILD_DIR="$(BUILD_DIR)"; \
	export BUILD_ARGS="$(BUILD_ARGS)"; \
	export SIM_ARGS="$(SIM_ARGS)"; \
	source $(VENV_DIR)/bin/activate; \
	python3 -m pytest --junit-xml=${RESULTS_DIR}/all.xml $(ARGS)

run_quartus:
	make -f $(QUARTUS_MAKEFILE) compile TOPLEVEL=$(TOPLEVEL) PREFERRED_DEVICE=$(PREFERRED_DEVICE)

$(VENV_DIR) : $(CURDIR)/requirements.txt
	python3 -m venv $(VENV_DIR)
	source $(VENV_DIR)/bin/activate; \
	pip install -r $(CURDIR)/requirements.txt

make_release:
	make -f $(QUARTUS_MAKEFILE) create_releases DEVICE_FAMILY=$(DEVICE_FAMILY) DEVICE_PART=$(DEVICE_PART)

clean_release:
	make -f $(QUARTUS_MAKEFILE) clean_releases

clean:
	@rm -rf $(CURDIR)/.cache \
	$(CURDIR)/.pytest_cache \
	$(CURDIR)/tests/__pycache__ \
	$(CURDIR)/qrun.log \
	$(CURDIR)/modelsim.ini \
	$(CURDIR)/transcript
	@make -f $(QUARTUS_MAKEFILE) clean_releases
