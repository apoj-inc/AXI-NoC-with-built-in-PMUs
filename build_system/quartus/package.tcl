source ../../../.cache/quartus/vars.tcl

project_new $TOPLEVEL -overwrite

set_global_assignment -name TOP_LEVEL_ENTITY $TOPLEVEL

foreach rtl $RTL_FILES {
    set_global_assignment -name SYSTEMVERILOG_FILE $rtl
}

set_global_assignment -name SEARCH_PATH $INCDIR

load_package flow
execute_flow -analysis_and_elaboration

project_close
