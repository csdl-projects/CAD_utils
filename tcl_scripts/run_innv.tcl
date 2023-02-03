set util 0.5
######### Load Library

if {![file exists ./result/PNR_RES]} {
	file mkdir ./result/PNR_RES
}

if {![file exists ./result/PNR_REP]} {
	file mkdir ./result/PNR_REP
}

if {![file exists ./results/PNR_RES/db_$util]} {
	file mkdir ./result/PNR_RES/db_$util
}

### Design & Libraries
set design 		        aes_cipher_top
set netlist 		    ./result/SYN_RES/${design}.v
set sdc 		        ./result/SYN_RES/${design}.sdc

set best_timing_lib 	./pdk/NangateOpenCellLibrary_typical.lib
set worst_timing_lib    ./pdk/NangateOpenCellLibrary_typical.lib
set lef 		        ./pdk/NangateOpenCellLibrary.lef
#set best_captbl 	    ./cln65g+_1p08m+alrdl_top2_cbest.captable
#set worst_captbl 	    ./cln65g+_1p08m+alrdl_top2_cworst.captable

set init_pwr_net "VDD"
set init_gnd_net "VSS"

set init_verilog "$netlist"
set init_design_netlisttype "Verilog"
set init_design_settop 1
set init_lef_file "$lef"
set init_top_cell "$design"

create_library_set -name SS_LIB -timing $worst_timing_lib
create_library_set -name FF_LIB -timing $best_timing_lib
#create_rc_corner -name Cmax -cap_table $best_captbl
#create_rc_corner -name Cmin -cap_table $worst_captbl

#create_delay_corner -name WC -library_set SS_LIB -rc_corner Cmax
create_delay_corner -name WC -library_set SS_LIB
#create_delay_corner -name BC -library_set FF_LIB -rc_corner Cmin
create_delay_corner -name BC -library_set FF_LIB
create_constraint_mode -name CON -sdc_file $sdc
create_analysis_view -name WC_VIEW -delay_corner WC -constraint_mode CON
create_analysis_view -name BC_VIEW -delay_corner BC -constraint_mode CON

init_design -setup {WC_VIEW} -hold {BC_VIEW}

########## Floorplan
set aspectRatio         1
set layoutUtil          $util

#floorPlan -site core -r $aspectRatio $layoutUtil 10.0 10.0 10.0 10.0
floorPlan -r $aspectRatio $layoutUtil 10.0 10.0 10.0 10.0

createObstruct 10 10 20 27
createObstruct 10 45 25 56

saveDesign ./result/PNR_RES/db_$util/floorplan.enc


########## Powerplan
globalNetConnect VDD -type pgpin -pin VDD -inst *
globalNetConnect VSS -type pgpin -pin VSS -inst *

setAddRingMode -ring_target default -extend_over_row 0 -ignore_rows 0 -avoid_short 0 -skip_crossing_trunks none -stacked_via_top_layer M8 -stacked_via_bottom_layer M1 -via_using_exact_crossover_size 1 -orthogonal_only true -skip_via_on_pin {  standardcell } -skip_via_on_wire_shape {  noshape }
addRing -nets {VSS VDD} -type core_rings -follow core -layer {top M5 bottom M5 left M4 right M4} -width {top 1.8 bottom 1.8 left 1.8 right 1.8} -spacing {top 1.8 bottom 1.8 left 1.8 right 1.8} -offset {top 1.8 bottom 1.8 left 1.8 right 1.8} -center 0 -extend_corner {} -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None
setAddStripeMode -ignore_block_check false -break_at none -route_over_rows_only false -rows_without_stripes_only false -extend_to_closest_target none -stop_at_last_wire_for_area false -partial_set_thru_domain false -ignore_nondefault_domains false -trim_antenna_back_to_shape none -spacing_type edge_to_edge -spacing_from_block 0 -stripe_min_length 0 -stacked_via_top_layer M8 -stacked_via_bottom_layer M1 -via_using_exact_crossover_size false -split_vias false -orthogonal_only true -allow_jog { padcore_ring  block_ring }
addStripe -nets {VDD VSS} -layer M3 -direction horizontal -width 1.8 -spacing 1.8 -set_to_set_distance 25 -start_from top -start_offset 22 -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit M8 -padcore_ring_bottom_layer_limit M1 -block_ring_top_layer_limit M8 -block_ring_bottom_layer_limit M1 -use_wire_group 0 -snap_wire_center_to_grid None -skip_via_on_pin {  standardcell } -skip_via_on_wire_shape {  noshape }
addStripe -nets {VDD VSS} -layer M2 -direction vertical -width 1.8 -spacing 1.8 -set_to_set_distance 25 -start_from left -start_offset 22 -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit M8 -padcore_ring_bottom_layer_limit M1 -block_ring_top_layer_limit M8 -block_ring_bottom_layer_limit M1 -use_wire_group 0 -snap_wire_center_to_grid None -skip_via_on_pin {  standardcell } -skip_via_on_wire_shape {  noshape }
setSrouteMode -viaConnectToShape { noshape }
sroute -connect { blockPin padPin padRing corePin floatingStripe } -layerChangeRange { M1(1) M8(8) } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -floatingStripeTarget { blockring padring ring stripe ringpin blockpin followpin } -allowJogging 1 -crossoverViaLayerRange { M1(1) M8(8) } -nets { VDD VSS } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { M1(1) M8(8) }

saveDesign ./result/PNR_RES/db_$util/powerplan.enc


########### Placement

setPlaceMode -timingDriven true -doCongOpt false
setPlaceMode -place_global_reorder_scan false
setPlaceMode -place_global_cong_effort medium
placeDesign -inPlaceOpt

saveDesign ./result/PNR_RES/db_$util/placement.enc


############ Clock
set clock_buffers {
    CLKBUF_*
}

# Clock tree synthesis
set_ccopt_property buffer_cells $clock_buffers
create_ccopt_clock_tree_spec
ccopt_design -cts -expandedViews

optDesign -postCTS

saveDesign ./result/PNR_RES/db_$util/cts.enc


# Routing
setNanoRouteMode -quiet -drouteAllowMergedWireAtPin false
setNanoRouteMode -quiet -drouteFixAntenna true
setNanoRouteMode -quiet -routeWithTimingDriven true
setNanoRouteMode -quiet -routeWithSiDriven true
setNanoRouteMode -quiet -routeSiEffort medium
setNanoRouteMode -quiet -routeWithSiPostRouteFix false
setNanoRouteMode -quiet -drouteAutoStop true
setNanoRouteMode -quiet -routeSelectedNetOnly false
setNanoRouteMode -quiet -drouteStartIteration default
globalDetailRoute

saveDesign ./result/PNR_RES/db_$util/route.enc
############# ReportDesign


# Timing report
#report_timing -max_paths 5 > ${design}.post_route.setup.timing.rpt

# Design report
#summaryReport

# Routing report
#reportRoute

# RC extraction (Spef)
reset_parasitics
extractRC
#rcOut -spef $design.spef -rc_corner Cmin
rcOut -spef ./result/PNR_RES/db_$util/$design.spef

# Def extraction
set dbgLefDefOutVersion 5.8
defOut -floorplan -netlist -routing ./result/PNR_RES/db_$util/$design.def

# GDS extraction
streamOut ./result/PNR_RES/db_$util/$design.gds -mapFile streamOut.map -libName DesignLib -units 2000 -mode ALL

file delete -force ./timingReports
