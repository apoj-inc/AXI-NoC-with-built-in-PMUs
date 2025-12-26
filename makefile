SHELL := /bin/bash

CCTB_MAKEFILE ?= $(CURDIR)/cctb/build/makefile

CACHE_DIR ?= $(CURDIR)/.cache
VENV_DIR ?= $(CCTBCACHE_DIR_DIR)/.venv

.PHONY: all test clean
all: test

test: $(VENV_DIR)
	make -f $(CCTB_MAKEFILE) run CACHE_DIR=$(CACHE_DIR) VENV_DIR=$(VENV_DIR)

$(VENV_DIR) : $(CURDIR)/requirements.txt
	python3 -m venv $(VENV_DIR)
	source $(VENV_DIR)/bin/activate; \
	pip install -r $(CURDIR)/requirements.txt

clean:
	@rm -rf .cache
