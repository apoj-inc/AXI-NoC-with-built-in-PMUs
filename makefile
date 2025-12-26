SHELL := /bin/bash

CCTB_MAKEFILE ?= $(CURDIR)/cctb/build/makefile

CACHE_DIR ?= $(CURDIR)/.cache
VENV_DIR ?= $(CACHE_DIR)/.venv

LIST_DIR ?= $(CURDIR)/rtl/lists
LIST_RTL ?= $(LIST_DIR)/files_rtl.lst
VERILOG_SOURCES ?= $(foreach file,$(shell cat $(LIST_RTL)), $(CURDIR)/$(file))

TB_FILES ?=  $(foreach file,$(shell find tb/ -type f -name '*.sv'), $(CURDIR)/$(file))

.PHONY: all test clean run_pytest
all: test

test: $(VENV_DIR)
	make -f $(CCTB_MAKEFILE) run CACHE_DIR=$(CACHE_DIR) VENV_DIR=$(VENV_DIR)

run_pytest: $(VENV_DIR)
	export VERILOG_SOURCES="$(VERILOG_SOURCES) $(TB_FILES)"; \
 	source $(VENV_DIR)/bin/activate; \
	python3 -m pytest tb

$(VENV_DIR) : $(CURDIR)/requirements.txt
	python3 -m venv $(VENV_DIR)
	source $(VENV_DIR)/bin/activate; \
	pip install -r $(CURDIR)/requirements.txt

clean:
	@rm -rf .cache
