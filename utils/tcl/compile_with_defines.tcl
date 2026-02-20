# compile_with_defines.tcl
# Usage examples:
#   quartus_sh -t compile_with_defines.tcl --project myproj --rev myrev --define FOO --define BAR=3
#   quartus_sh -t compile_with_defines.tcl --project myproj --define SIM

package require ::quartus::project
package require ::quartus::flow

proc usage {} {
    puts "Usage:"
    puts "  quartus_sh -t compile_with_defines.tcl --project <name> ?--rev <revision>? ?--define NAME[=VALUE] ...?"
    exit 2
}

# Simple CLI parse
set project_name ""
set revision_name ""
set defines {}

set i 0
while {$i < [llength $argv]} {
    set a [lindex $argv $i]
    switch -- $a {
        --project {
            incr i
            if {$i >= [llength $argv]} { usage }
            set project_name [lindex $argv $i]
        }
        --rev - --revision {
            incr i
            if {$i >= [llength $argv]} { usage }
            set revision_name [lindex $argv $i]
        }
        --define {
            incr i
            if {$i >= [llength $argv]} { usage }
            lappend defines [lindex $argv $i]
        }
        -h - --help {
            usage
        }
        default {
            puts "Unknown argument: $a"
            usage
        }
    }
    incr i
}

if {$project_name eq ""} {
    puts "ERROR: --project is required"
    usage
}

# Open the project (optionally with revision)
if {$revision_name eq ""} {
    project_open $project_name
} else {
    project_open $project_name -revision $revision_name
}

# Apply defines as VERILOG_MACRO assignments
# Quartus expects: set_global_assignment -name VERILOG_MACRO "NAME" or "NAME=VALUE"
# Note: repeated calls create multiple macros.
foreach d $defines {
    # Basic sanity (optional)
    if {[string trim $d] eq ""} {
        continue
    }
    puts "Applying define: $d"
    set_global_assignment -name VERILOG_MACRO $d
}

# Run a full compile (Analysis & Synthesis, Fitter, Assembler, Timing, etc.)
puts "Starting Quartus compile for project '$project_name'..."
if {[catch {execute_flow -compile} err]} {
    puts "ERROR: Compilation failed:"
    puts $err
    project_close
    exit 1
}

puts "Compile finished successfully."

puts "Extracting database."

set_global_assignment -name VER_COMPATIBLE_DB_DIR db_export
execute_flow -flow export_database

puts "Extracted database successfully."
project_close
exit 0
