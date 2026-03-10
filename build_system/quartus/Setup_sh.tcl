source ../../../.cache/quartus/vars.tcl

set fp [open $FILES_RTL_PATH r]
set file_data [read $fp]
close $fp

set FILES_RTL_LIST [split $file_data "\n"]

set fp [open $INCDIRS_PATH r]
set file_data [read $fp]
close $fp

set INCDIRS_LIST [split $file_data "\n"]

project_new NoC -overwrite

set_global_assignment -name TOP_LEVEL_ENTITY $TOPLEVEL
set_global_assignment -name VERILOG_MACRO QUARTUS

set_global_assignment -name FAMILY $DEVICE_FAMILY
set_global_assignment -name DEVICE $DEVICE_PART

source $CUSTOM_ASSIGNMENTS_PATH

foreach rtl $FILES_RTL_LIST {
    if { [string match $rtl tb*] } {
        continue
    }

    set_global_assignment -name SYSTEMVERILOG_FILE $RTL_PATH/$rtl
}

set FILES_RTL_LIST [split $file_data "\n"]

foreach incdir $INCDIRS_LIST {
    set_global_assignment -name SEARCH_PATH $RTL_PATH/$incdir
}

load_package flow
execute_flow -compile

project_close
