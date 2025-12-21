TOPLEVEL ?= toplevel
QUARTUS_PATH := build_system/quartus
VARS_TCL_PATH := $(QUARTUS_PATH)/$(TOPLEVEL)/vars.tcl
FILES_RTL_PATH := $(CURDIR)/rtl/lists/files_rtl.lst

.PHONY: compile fmax

compile: build_system/quartus/$(TOPLEVEL)/NoC.qpf

build_system/quartus/$(TOPLEVEL)/NoC.qpf: $(shell find rtl -type f | tr '\n' ' ')
	@mkdir -p build_system/quartus/$(TOPLEVEL)

	@echo set TOPLEVEL $(TOPLEVEL) > $(VARS_TCL_PATH)
	@echo set FILES_RTL_PATH $(FILES_RTL_PATH) >> $(VARS_TCL_PATH)

	quartus_sh -t $(QUARTUS_PATH)/Setup_sh.tcl

clean:
	rm -rf build_system/quartus/$(TOPLEVEL)