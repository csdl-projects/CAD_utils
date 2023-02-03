set design adder32

set link_library ./pdk/NangateOpenCellLibrary_typical.db
set target_library ./pdk/NangateOpenCellLibrary_typical.db

set NETLIST [list ./result/SYN_RES/$design.v]
set DRIVE0_PORT [list clock rst]
set SDF_FILE "./result/SYN_RES/$design.sdf"
#set SPEF_FILE "CHIP.spef.max"
set CNST_SDC "./design/$design.sdc"
set CLK_INFO "./result/STA_REP/clock_pt.rpt"
set TIME_RPT "./result/STA_REP/timing_pt.rpt"
#set BEST_OP "fast"
#set WRST_OP "slow"
set RST "rst"
#set VCD_FILE "../run/CHIP.vcd"
#set INST_NAME "CHIP_beh/u0"

##====================================================================
## Reading in Synthesized Netlist Verilog design
##====================================================================

read_file -format verilog $NETLIST
current_design $design
link

##====================================================================
## SDF information from the synthesis result
##====================================================================

current_design $design
read_sdf $SDF_FILE
report_annotated_check
read_sdc -echo $CNST_SDC
set_drive 0 $DRIVE0_PORT
set_drive 0 [get_port $RST*]
# Input drive is 0 on signals without timing analysis
set_false_path -from [get_ports $RST*]
#get_design *
#current_design $CHIP

##====================================================================
## Report Clock Information Post false-path settings
##====================================================================

echo "reporting clock information post set"
report_clock > $CLK_INFO
report_port -input_delay >> $CLK_INFO
report_port -output_delay >> $CLK_INFO
check_timing >> $CLK_INFO

##====================================================================
## Report All Violation & Timing Path Post false-path settings
##====================================================================

echo "reporting timing check information post set"
#report_constraint -all_violators > $TIME_RPT
report_timing > $TIME_RPT
report_timing -nets -transition_time -capacitance >> $TIME_RPT
report_timing -nworst 10 -path_type summary >> $TIME_RPT

##====================================================================
## Remove everything before exiting
##====================================================================

echo "removing design & lib"
#remove_design -all
#remove_lib -all
echo "end of compilation"
#exit
