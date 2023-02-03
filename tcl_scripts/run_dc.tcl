set top_module aes_cipher_top
set LibDir ./pdk
set ResDir ./result
set DesDir ./design

# Target library
set tl_list "$LibDir/NangateOpenCellLibrary_typical.db"
set ll_list "$LibDir/NangateOpenCellLibrary_typical.db"

set link_library $ll_list
set target_library $tl_list
set symbol_library {}
set wire_library_file {}
set wire_library {}
set wire_load_model ""
set wire_load_mode enclosed
## Use worst CAP (for PT correlateion)
set timing_use_enhanced_capacitance_modeling true


set search_path [concat $search_path ]
set link_library [concat * $link_library ]
set dont_use_cells 1
set dont_use_cell_list ""

set synthetic_library {}
set link_path [concat  $link_library $synthetic_library]

# Start
sh date
sh hostname
sh uptime

if {![file exists $ResDir/SYN_REP]} {
	sh mkdir $ResDir/SYN_REP
}
if {![file exists $ResDir/SYN_RES]} {
	sh mkdir $ResDir/SYN_RES
}
# Compiler drectives
set compile_effort   "high"
set compile_flatten_all 0
set compile_no_new_cells_at_top_level false
set hdlin_enable_vpp true
set hdlin_auto_save_templates false
define_design_lib WORK -path .template
set verilogout_single_bit false
set hdlout_internal_busses true
set bus_naming_style {%s[%d]}
set bus_inference_style $bus_naming_style
set enforce_input_fanout_one     0
set allow_outport_drive_innodes  1
set dont_touch_nets_with_size_only_cells false

# read RTL
set rtl_all [glob -directory $DesDir/$top_module/ *.v*]


foreach rtl_file $rtl_all {
    analyze -format verilog -lib WORK $rtl_file
}
elaborate $top_module -lib WORK

current_design $top_module
set ideal_net_list {}
set false_path_list {}



# Link Design
set dc_shell_status [ link ]
if {$dc_shell_status == 0} {
	echo "****************************************************"
	echo "* ERROR!!!! Failed to Link...exiting prematurely.  *"
	echo "****************************************************"
#	quit
}

# Default SDC Constraints
read_sdc $DesDir/$top_module/$top_module.sdc

# Input Fanout Control
if {[info exists enforce_input_fanout_one] && ($enforce_input_fanout_one  == 1)} {
	set_max_fanout 1 $non_ideal_inputs
}

# More constraints and setup before compile
foreach_in_collection design [ get_designs "*" ] {
	current_design $design
	set_fix_multiple_port_nets -all
}
current_design $top_module

# Compile

#set dc_shell_status [ compile -exact_map -map_effort low -area_effort none -power_effort none ]
#write -format verilog -hier -output ./test.v
#quit
# Source user compile options
if {[info exists compile_flatten_all] && ($compile_flatten_all  == 1)} {
	ungroup -flatten -all
}
set_fix_multiple_port_nets -all -buffer_constants
#set dc_shell_status [ compile -boundary_optimization -exact_map -map_effort $compile_effort ]
set dc_shell_status [ compile_ultra -no_autoungroup -exact_map -timing_high_effort_script -no_boundary_optimization]

if {$dc_shell_status == 0} {
	echo "*******************************************************"
	echo "* ERROR!!!! Failed to compile...exiting prematurely.  *"
	echo "*******************************************************"
	quit
}
sh date


# Write Out Design - Hierarchical
define_name_rules afara_rules -map {{ {"\\*cell\\*", "UDW_"}}}
change_names -rule afara_rules -hierarchy
foreach_in_collection design [ get_designs "*" ] {
	current_design $design
	set_fix_multiple_port_nets -all -buffer_constants
}
current_design $top_module
change_names -rules verilog -hierarchy

if {[info exists use_physopt] && ($use_physopt == 1)} {
	write -format verilog -hier -output [format "%s%s%s" $ResDir/SYN_RES/ $top_module _hier_fromdc.v]
} else {
	write -format verilog -hier -output [format "%s%s%s" $ResDir/SYN_RES/ $top_module .v]
}

current_design $top_module
write_sdc [format "%s%s%s" $ResDir/SYN_RES/ $top_module .sdc]
#write_saif -output $top_module\_syn.saif -propagated -exclude_sdpd 
write_sdf -version 1.0 [format "%s%s%s" $ResDir/SYN_RES/ $top_module .sdf]

# Write Reports
redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _area.rep] { report_area }
redirect -append [format "%s%s%s" $ResDir/SYN_REP/ $top_module _area.rep] { report_reference }
redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _area.hier.rep] { report_area -hierarchy }
redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _cell.rep] { report_cell }
redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _design.rep] { report_design }
redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _power.rep] { report_power }
redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _timing.rep] { report_timing -path full -max_paths 100 -nets -transition_time -capacitance -significant_digits 3}
redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _check_timing.rep] { check_timing }
redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _check_design.rep] { check_design }
redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _cell.hier.rep] { report_cell [get_cells -hierarchical] }
#redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _latch_timing.rep] { report_timing -from [get_cells */*/*/*/latched_output_reg[*]] }
# redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _qor.rep] { report_qor }
# redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _constraint.rep] { report_constraint -all }
# redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _attribute.rep] { report_attribute }
# redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _hierarchy.rep] { report_hierarchy }
# redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _net.rep] { report_net }
# redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _path_group.rep] { report_path_group }
# redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _resources.rep] { report_resources }
# redirect [format "%s%s%s" $ResDir/SYN_REP/ $top_module _timing_requirements.rep] { report_timing_requirements }

set inFile  [open $ResDir/SYN_REP/$top_module\_area.rep]
while { [gets $inFile line]>=0 } {
    if { [regexp {Total cell area:} $line] } {
        set AREA [lindex $line 3]
    }
}
close $inFile
set inFile  [open $ResDir/SYN_REP/$top_module\_power.rep]
while { [gets $inFile line]>=0 } {
    if { [regexp {Total Dynamic Power} $line] } {
        set PWR [lindex $line 4]
    } elseif { [regexp {Cell Leakage Power} $line] } {  
        set LEAK [lindex $line 4] 
    }
}
close $inFile

#set path    [get_timing_path -nworst 1]
#set WNS     [get_attribute $path slack]
#set outFile [open SYN_RES/result_dc.rpt w]
#puts $outFile "$AREA\t$WNS\t$PWR\t$LEAK"
#close $outFile


# Check Design and Detect Unmapped Design
set unmapped_designs [get_designs -filter "is_unmapped == true" $top_module]
if {  [sizeof_collection $unmapped_designs] != 0 } {
	echo "****************************************************"
	echo "* ERROR!!!! Compile finished with unmapped logic.  *"
	echo "****************************************************"
	quit
}
# Done
sh date
sh uptime
echo "run.scr completed successfully"
file delete -force ./alib-52
file delete -force ./command.log
file delete -force ./default.svf
quit
