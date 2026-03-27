TOPLEVEL ?= toplevel
QUARTUS_BUILD_PATH ?= $(CURDIR)/build_system/quartus
VARS_TCL_PATH ?= $(CURDIR)/.cache/quartus
VARS_TCL ?= $(VARS_TCL_PATH)/vars.tcl
RTL_PATH ?= ../../../rtl
FILES_RTL_PATH ?= $(RTL_PATH)/lists/files_rtl.lst
INCDIRS_PATH ?= $(RTL_PATH)/lists/incdirs.lst
CUSTOM_ASSIGNMENTS_PATH ?= $(QUARTUS_BUILD_PATH)/custom_assignments.tcl
DEVICE_FAMILY ?= "$"Cyclone V$""
DEVICE_PART ?= "5CGXFC9E7F35C8"

RELEASE_DIR 	?= $(CURDIR)/release
RELEASE_DIRS 	?= $(wildcard $(RELEASE_DIR)/*/) 
RELEASE_FILES	?= $(foreach directory,$(RELEASE_DIRS), $(directory)$(shell basename $(directory)).qar)

.PHONY: all compile clean create_releases clean_releases

all: compile

compile: $(QUARTUS_BUILD_PATH)/$(TOPLEVEL)/NoC.qpf

$(QUARTUS_BUILD_PATH)/$(TOPLEVEL)/NoC.qpf: $(shell find $(CURDIR)/rtl -type f | tr '\n' ' ')
	@mkdir -p $(VARS_TCL_PATH)/$(TOPLEVEL) $(VARS_TCL_PATH)

	@echo set TOPLEVEL $(TOPLEVEL) > $(VARS_TCL)
	@echo set RTL_PATH $(RTL_PATH)/.. >> $(VARS_TCL)
	@echo set CUSTOM_ASSIGNMENTS_PATH $(CUSTOM_ASSIGNMENTS_PATH) >> $(VARS_TCL)
	@echo set FILES_RTL_PATH $(FILES_RTL_PATH) >> $(VARS_TCL)
	@echo set INCDIRS_PATH $(INCDIRS_PATH) >> $(VARS_TCL)
	@echo set DEVICE_FAMILY $(DEVICE_FAMILY) >> $(VARS_TCL)
	@echo set DEVICE_PART $(DEVICE_PART) >> $(VARS_TCL)

	@cd $(VARS_TCL_PATH)/$(TOPLEVEL);\
	quartus_sh -t $(QUARTUS_BUILD_PATH)/Setup_sh.tcl

create_releases: $(RELEASE_FILES)

$(RELEASE_FILES):\
		$(foreach file,$(shell cat $(wildcard $(RELEASE_DIR)/*/sources.lst) | grep -v "#"),$(CURDIR)/$(file))\
		$(foreach file,$(shell cat $(wildcard $(RELEASE_DIR)/*/incfiles.lst) | grep -v "#"),$(CURDIR)/$(file))\
		$(wildcard $(RELEASE_DIR)/*/sources.lst)\
		$(wildcard $(RELEASE_DIR)/*/incfiles.lst)
	@mkdir -p $(dir $@)package
	@rm -r $(dir $@)package
	@mkdir -p $(dir $@)package $(dir $@)package/src $(dir $@)package/inc
	@$(foreach file,$(shell cat $(abspath $(dir $@)sources.lst) | grep -v "#") , cp $(CURDIR)/$(file) $(dir $@)package/src;)
	@$(foreach file,$(shell cat $(abspath $(dir $@)incfiles.lst) | grep -v "#"), cp $(CURDIR)/$(file) $(dir $@)package/inc;)

	@mkdir -p $(VARS_TCL_PATH)
	@echo set TOPLEVEL $(notdir $(basename $@)) > $(VARS_TCL)
	@echo set RTL_FILES {$(foreach file,$(shell cat $(abspath $(dir $@)sources.lst) | grep -v "#"), src/$(notdir $(file))) } >> $(VARS_TCL)
	@echo set INCDIR inc >> $(VARS_TCL)
	@echo set DEVICE_FAMILY \"$(DEVICE_FAMILY)\" >> $(VARS_TCL)
	@echo set DEVICE_PART $(DEVICE_PART) >> $(VARS_TCL)

	@cd $(dir $@)package;\
		quartus_sh -t $(QUARTUS_BUILD_PATH)/package.tcl
	
	@mv $(dir $@)package/$(notdir $(basename $@)).qar $(dir $@)
	
	@rm -rf $(dir $@)package

clean_releases:
	@rm -f $(wildcard $(RELEASE_DIR)/*/*.qar)

clean:
	@rm -rf $(QUARTUS_BUILD_PATH)/$(TOPLEVEL)
