TOPLEVEL ?= toplevel
QUARTUS_BUILD_PATH ?= $(CURDIR)/build_system/quartus
VARS_TCL_PATH ?= $(CURDIR)/.cache/quartus
VARS_TCL ?= $(VARS_TCL_PATH)/vars.tcl
RTL_PATH ?= $(CURDIR)/rtl
FILES_RTL_PATH ?= $(RTL_PATH)/lists/files_rtl.lst
INCDIRS_PATH ?= $(RTL_PATH)/lists/incdirs.lst
CUSTOM_ASSIGNMENTS_PATH ?= $(QUARTUS_BUILD_PATH)/custom_assignments.tcl

.PHONY: all compile fmax

all: compile

compile: $(QUARTUS_BUILD_PATH)/$(TOPLEVEL)/NoC.qpf

$(QUARTUS_BUILD_PATH)/$(TOPLEVEL)/NoC.qpf: $(shell find $(RTL_PATH) -type f | tr '\n' ' ')
	@mkdir -p $(QUARTUS_BUILD_PATH)/$(TOPLEVEL) $(VARS_TCL_PATH)

	@echo set TOPLEVEL $(TOPLEVEL) > $(VARS_TCL)
	@echo set RTL_PATH $(CURDIR) >> $(VARS_TCL)
	@echo set CUSTOM_ASSIGNMENTS_PATH $(CUSTOM_ASSIGNMENTS_PATH) >> $(VARS_TCL)
	@echo set FILES_RTL_PATH $(FILES_RTL_PATH) >> $(VARS_TCL)
	@echo set INCDIRS_PATH $(INCDIRS_PATH) >> $(VARS_TCL)

	@cd $(QUARTUS_BUILD_PATH)/$(TOPLEVEL);\
	quartus_sh -t $(QUARTUS_BUILD_PATH)/Setup_sh.tcl

clean:
	rm -rf $(QUARTUS_BUILD_PATH)/$(TOPLEVEL)