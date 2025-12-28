SHELL := /bin/bash

CCTB_MAKEFILE ?= $(CURDIR)/cctb/build/makefile

CACHE_DIR ?= $(CURDIR)/.cache
VENV_DIR ?= $(CACHE_DIR)/.venv
COCOTB_DIR ?= $(CACHE_DIR)/cctb

ifndef INCLUDE_DIRS
INCLUDE_DIRS :=
INCLUDE_DIRS += $(CURDIR)/rtl/axi
INCLUDE_DIRS += $(CURDIR)/rtl/cores/src
endif

LIST_DIR ?= $(CURDIR)/rtl/lists
LIST_RTL ?= $(LIST_DIR)/files_rtl.lst
VERILOG_SOURCES ?= $(foreach file,$(shell cat $(LIST_RTL)),$(CURDIR)/$(file))

TB_FILES ?=  $(foreach file,$(shell find tb/ -type f -name '*.sv'),$(CURDIR)/$(file))

TB_DIR ?= $(CURDIR)/tb
TESTS_DIRS ?= $(sort $(dir $(wildcard $(TB_DIR)/*/)))

BUILD_DIR   ?= $(COCOTB_DIR)/tests
LOGS_DIR    ?= $(BUILD_DIR)/logs
RESULTS_DIR ?= ${LOGS_DIR}/results

.PHONY: all test clean run_pytest
all: test

test: $(VENV_DIR)
	make -f $(CCTB_MAKEFILE) run CACHE_DIR=$(CACHE_DIR) VENV_DIR=$(VENV_DIR) INCLUDE_DIRS=$(INCLUDE_DIRS)

run_pytest: $(VENV_DIR)
	@export TESTS_DIRS="$(TESTS_DIRS)"; \
	export INCLUDE_DIRS="$(INCLUDE_DIRS)"; \
	export VERILOG_SOURCES="$(sort $(VERILOG_SOURCES) $(TB_FILES))"; \
	export LOGS_DIR=${LOGS_DIR}; \
	export RESULTS_XML=${RESULTS_XML}; \
	export BUILD_DIR="$(BUILD_DIR)"; \
	source $(VENV_DIR)/bin/activate; \
	python3 -m pytest --junit-xml=${RESULTS_DIR}/all.xml

$(VENV_DIR) : $(CURDIR)/requirements.txt
	python3 -m venv $(VENV_DIR)
	source $(VENV_DIR)/bin/activate; \
	pip install -r $(CURDIR)/requirements.txt

clean:
	@rm -rf $(CURDIR)/.cache \
	$(CURDIR)/tests/__pycache__ \
	$(CURDIR)/qrun.log \
	$(CURDIR)/modelsim.ini\
	$(CURDIR)/transcript
