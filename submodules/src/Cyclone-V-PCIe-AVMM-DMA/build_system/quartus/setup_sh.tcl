package require ::quartus::project
package require ::quartus::flow

source vars.tcl

set fp [open $FILES_RTL_PATH r]
set file_data [read $fp]
close $fp

set FILES_RTL_LIST [split $file_data "\n"]

set fp [open $INCDIRS_PATH r]
set file_data [read $fp]
close $fp

set INCDIRS_LIST [split $file_data "\n"]

set fp [open $FILES_SDC_PATH r]
set file_data [read $fp]
close $fp

set FILES_SDC_LIST [split $file_data "\n"]

set fp [open $NAMES_QSYS_PATH r]
set file_data [read $fp]
close $fp

set NAMES_QSYS_LIST [split $file_data "\n"]


project_new $TOPLEVEL -overwrite

set_global_assignment -name TOP_LEVEL_ENTITY $TOPLEVEL
set_global_assignment -name VERILOG_MACRO QUARTUS

set_global_assignment -name FAMILY $DEVICE_FAMILY
set_global_assignment -name DEVICE $DEVICE_PART

set_global_assignment -name IP_SEARCH_PATHS $CUSTOM_IP_PATH

source $CUSTOM_ASSIGNMENTS

foreach rtl $FILES_RTL_LIST {
    set_global_assignment -name SYSTEMVERILOG_FILE $CURDIR/$rtl
}

foreach incdir $INCDIRS_LIST {
    set_global_assignment -name SEARCH_PATH $CURDIR/$incdir
}

foreach sdc $FILES_SDC_LIST {
    set_global_assignment -name SDC_FILE $CURDIR/$sdc
}

foreach qsys $NAMES_QSYS_LIST {
    set qip_name [file tail $qsys]
    set_global_assignment -name QIP_FILE $qip_name/synthesis/$qip_name.qip
}

load_package flow
execute_flow -compile

project_close
