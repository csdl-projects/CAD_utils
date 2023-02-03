set DESIGN_NAME "aes_cipher_top"
set CLK_PERIOD "3000"
set UTIL "0.5"
set RVT "4_372"
set LVT "4_307"
set DESIGN_DIR "/home/jklee/ISLPED2023/result/SYN_RES"
set PDK_DIR "/project/common/pdk/Lib/ASAP7_PDKandLIB_v1p6/asap7sc7p5t_28"

set TECH_FILE "${PDK_DIR}/synopsys/icc/asap7_icc.tf"
#set MACRO_LEF [list "${PDK_DIR}/LEF/scaled/asap7sc7p5t_28_R_4x_220121a.lef" \
#        "${PDK_DIR}/LEF/scaled/asap7sc7p5t_28_L_4x_220121a.lef"]

set MACRO_LEF "/home/jklee/ISLPED2023/src/ref.lef"

set TLUP_FILES "${PDK_DIR}/synopsys/starrc/tlu_plus"

#set_app_var search_path "/project/common/pdk/Lib/ASAP7_PDKandLIB_v1p6/asap7sc7p5t_28/DB/NLDM/"
#set_app_var link_library [list \
#        "asap7sc7p5t_AO_RVT_TT_nldm_211120.db" \
#        "asap7sc7p5t_INVBUF_RVT_TT_nldm_211120.db" \
#        "asap7sc7p5t_OA_RVT_TT_nldm_211120.db" \
#        "asap7sc7p5t_SEQ_RVT_TT_nldm_220123.db" \
#        "asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.db" \
#        "asap7sc7p5t_AO_LVT_TT_nldm_211120.db" \
#        "asap7sc7p5t_INVBUF_LVT_TT_nldm_211120.db" \
#        "asap7sc7p5t_OA_LVT_TT_nldm_211120.db" \
#        "asap7sc7p5t_SEQ_LVT_TT_nldm_220123.db" \
#        "asap7sc7p5t_SIMPLE_LVT_TT_nldm_211120.db"]

set_app_var search_path "/home/shyeon/research/GateWfOpt/ISLPED2023/libs/CUSTOM_4_250_0_45"
set_app_var link_library [list \
        "ADDER_CUSTOM_4_250_0_45.db" \
        "AO_CUSTOM_4_250_0_45.db" \
        "OA_CUSTOM_4_250_0_45.db" \
        "INVBUF_CUSTOM_4_250_0_45.db" \
        "SIMPLE_CUSTOM_4_250_0_45.db" \
        "SEQ_CUSTOM_4_250_0_45.db"]

set NETLIST_FILES "${DESIGN_DIR}/${DESIGN_NAME}/PLZ_lvt_${LVT}_rvt_${RVT}_clk_${CLK_PERIOD}/${DESIGN_NAME}.v"
set SDC_FILE "${DESIGN_DIR}/${DESIGN_NAME}/PLZ_lvt_${LVT}_rvt_${RVT}_clk_${CLK_PERIOD}/${DESIGN_NAME}.sdc"
set MAX_ROUTING_LAYER ""
set MIN_ROUTING_LAYER ""
set SUPPLY_VDD "0.45"
##### USER DEFINE #####


##### ENVIRONMENT SETUP #####
set_host_options -max_cores 8

set RES_DIR "/home/jklee/ISLPED2023/result/PNR_RES/${DESIGN_NAME}/util_${UTIL}_lvt_${LVT}_rvt_${RVT}_clk_${CLK_PERIOD}"
set REP_DIR "/home/jklee/ISLPED2023/result/PNR_REP/${DESIGN_NAME}/util_${UTIL}_lvt_${LVT}_rvt_${RVT}_clk_${CLK_PERIOD}"

if { ![file exists "/home/jklee/ISLPED2023/result/PNR_RES/${DESIGN_NAME}"] } { 
    file mkdir "/home/jklee/ISLPED2023/result/PNR_RES/${DESIGN_NAME}" 
}
if { ![file exists "/home/jklee/ISLPED2023/result/PNR_REP/${DESIGN_NAME}"] } { 
    file mkdir "/home/jklee/ISLPED2023/result/PNR_REP/${DESIGN_NAME}" 
}

if { ![file exists $REP_DIR] } { file mkdir $REP_DIR }
if { [file exists $RES_DIR] } { file delete -force $RES_DIR }


create_lib -technology $TECH_FILE -ref_libs $MACRO_LEF "$RES_DIR" -scale_factor 4000
read_verilog -design "${DESIGN_NAME}/import_netlist" -top "${DESIGN_NAME}" ${NETLIST_FILES}
read_parasitic_tech -tlup $TLUP_FILES -name SS
##### ENVIRONMENT SETUP #####


##### MCMM setup #####
set MODE "WS"
remove_modes -all
remove_corners -all
remove_scenarios -all

create_mode $MODE
create_corner $MODE
create_scenario -name $MODE -mode $MODE -corner $MODE
set_parasitic_parameters -late_spec SS -early_spec SS -library "util_${UTIL}_lvt_${LVT}_rvt_${RVT}_clk_${CLK_PERIOD}"
set_voltage $SUPPLY_VDD -corner [current_corner] -object_list [get_supply_nets VDD]
set_voltage 0 -corner [current_corner] -object_list [get_supply_nets VSS]
source $SDC_FILE

set_scenario_status $MODE -none -setup true -hold true -leakage_power true -dynamic_power true -max_transition true -max_capacitance true -min_capacitance false -active true
remove_duplicate_timing_contexts

##### FLOORPLAN #####
initialize_floorplan -core_utilization $UTIL
save_block -force -label "floorplan"
save_lib -all
##### FLOORPLAN #####


##### PDN #####
##### POWER RING SETUP #####
create_pg_ring_pattern ring_pattern -horizontal_layer M9 \
    -horizontal_width {5} -horizontal_spacing {4} \
    -vertical_layer M8 -vertical_width {5} \
    -vertical_spacing {4} -corner_bridge false

set_pg_strategy core_ring -core -pattern \
    {{pattern: ring_pattern}{nets: {VDD VSS}}{offset: {3 3}}} \
    -extension {{stop: innermost_ring}}
##### POWER RING SETUP #####

##### POWER MESH SETUP #####
create_pg_mesh_pattern pg_mesh1 \
   -parameters {w1 p1 w2 p2 f t} \
   -layers {{{vertical_layer: M8} {width: @w1} {spacing: interleaving} \
        {pitch: @p1} {offset: @f} {trim: @t}} \
         {{horizontal_layer: M9 } {width: @w2} {spacing: interleaving} \
        {pitch: @p2} {offset: @f} {trim: @t}}}

set_pg_strategy s_mesh1 -pattern {{pattern: pg_mesh1} {nets: {VDD VSS VSS VDD}} \
{offset_start: 10 20} {parameters: 4 80 6 120 3.344 false}} -core -extension {{stop: outermost_ring}}
##### POWER MESH SETUP #####

##### POWER RAIL SETUP #####
create_pg_std_cell_conn_pattern std_cell_rail -layers {M1} -rail_width 0.072
set_pg_strategy rail_strat -core -pattern {{name: std_cell_rail} {nets: VDD VSS} }
##### POWER RAIL SETUP #####

connect_pg_net -automatic -all_blocks

##### POWER DELIVERY NETWORK GENERATION #####
compile_pg -strategies core_ring
compile_pg -strategies s_mesh1
compile_pg -strategies rail_strat
##### POWER DELIVERY NETWORK GENERATION #####

check_pg_connectivity -check_std_cell_pins none
check_pg_drc -ignore_std_cells

save_block -hier -force -label "powerplan"
save_lib -all
##### PDN #####

set plan.place.auto_generate_blockages true
set_app_options -name place.coarse.continue_on_missing_scandef -value true
       
create_placement -timing_driven -floorplan
estimate_timing
save_block -hier -force -label "global_place"
save_lib -all

remove_corners [get_corners estimated_corner]
place_opt
save_block -hier -force -label "detailed_place"
save_lib -all

clock_opt
save_block -hier -force -label "cts"
save_lib -all

if {$MAX_ROUTING_LAYER != ""} {set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER}
if {$MIN_ROUTING_LAYER != ""} {set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER}

route_auto -max_detail_route_iterations 5
save_block -hier -force -label "route"
save_lib -all

set route_opt.flow.enable_ccd true
route_opt

save_block -hier -force -label "post_route"
save_lib -all

#set FILLER_CELLS [get_object_name [sort_collection -descending [get_lib_cells */FILLER*] area]]
#create_stdcell_fillers -lib_cells $FILLER_CELLS
#route_opt

#save_block -hier -force -label "Tapeout"
#save_lib -all


##### SAVE FINAL DATA #####
report_power -significant_digits 6 > ${REP_DIR}/power.rep
report_design > ${REP_DIR}/design.rep
report_timing -nworst 100 > ${REP_DIR}/timing.rep

set inFile [open ${REP_DIR}/design.rep]
while { [gets $inFile line]>=0 } { 
    if { [regexp {TOTAL LEAF CELLS} $line] } {set CELL_AREA [lindex $line 4]} \
    elseif { [regexp {Core Area} $line] } {set CORE_AREA [lindex $line 3]}
}
close $inFile

set inFile [open ${REP_DIR}/power.rep]
while { [gets $inFile line]>=0 } { 
    if { [regexp {Total} $line] } {
        set INTERNAL_POWER [lindex $line 1]
        set SWITCHING_POWER [lindex $line 3]
        set LEAKAGE_POWER [lindex $line 5]
        set TOTAL_POWER [lindex $line 7]
    }
}
close $inFile

set TOP100 0
set WNS [get_attribute [get_timing_path -nworst 1] slack]
foreach slack [get_attribute [get_timing_path -nworst 100] slack] { set TOP100 [expr $TOP100+$slack] }

set outFile [open ${REP_DIR}/summary.rep w]
puts $outFile "${CELL_AREA},${CORE_AREA},${INTERNAL_POWER},${SWITCHING_POWER},${LEAKAGE_POWER},${TOTAL_POWER},${WNS},${TOP100}"
close $outFile


##### SAVE FINAL DATA #####



exit
