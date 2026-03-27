package require ::quartus::project
package require ::quartus::flow

proc usage {} {
    puts "Usage:"
    puts "  quartus_sh -t compile_with_defines.tcl --project <name> ?--rev <revision>? ?--define NAME[=VALUE] ...?"
    exit 2
}

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

if {$revision_name eq ""} {
    set revision_name $project_name
}

set qsf_file "${revision_name}.qsf"

if {![file exists $qsf_file]} {
    puts "ERROR: QSF file not found: $qsf_file"
    exit 1
}

puts "Removing all existing VERILOG_MACRO lines from $qsf_file ..."
set fin [open $qsf_file r]
set qsf_data [read $fin]
close $fin

set new_lines {}
foreach line [split $qsf_data "\n"] {
    if {[regexp {VERILOG_MACRO} $line]} {
        puts "  Removing line: $line"
        continue
    }
    lappend new_lines $line
}

set fout [open $qsf_file w]
puts -nonewline $fout [join $new_lines "\n"]
close $fout

if {$revision_name eq ""} {
    project_open $project_name
} else {
    project_open $project_name -revision $revision_name
}

foreach d $defines {
    set d [string trim $d]
    if {$d eq ""} {
        continue
    }
    puts "Applying define: $d"
    set_global_assignment -name VERILOG_MACRO $d
}

# Persist the updated assignments into the .qsf
export_assignments

puts "Starting Quartus compile for project '$project_name'..."
if {[catch {execute_flow -compile} err]} {
    puts "ERROR: Compilation failed:"
    puts $err
}

puts "Compile finished."

puts "Exporting project."
project_archive $project_name.qar -overwrite -include_outputs -include_libraries

puts "Project exported successfully."
project_close
exit 0
