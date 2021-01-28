set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) user_proj_aes

set ::env(VERILOG_FILES) "\
	$script_dir/../../verilog/rtl/defines.v \
	$script_dir/../../verilog/rtl/user_proj_aes/aes_core.v \
	$script_dir/../../third_party/aes_128/aes_sbox.v \
	$script_dir/../../third_party/aes_128/aes_rcon.v \
	$script_dir/../../third_party/aes_128/aes_cipher_top.v \
	$script_dir/../../third_party/aes_128/aes_key_expand_128.v"

set ::env(CLOCK_PORT) "wb_clk_i"
set ::env(CLOCK_PERIOD) "10"

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 2000 2500"
set ::env(DESIGN_IS_CORE) 0

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg
# set ::env(FP_CONTEXT_DEF) $script_dir/../user_project_wrapper/runs/user_project_wrapper/tmp/floorplan/ioPlacer.def.macro_placement.def
# set ::env(FP_CONTEXT_LEF) $script_dir/../user_project_wrapper/runs/user_project_wrapper/tmp/merged_unpadded.lef

set ::env(ROUTING_CORES) [ exec nproc ]

set ::env(FP_CORE_UTIL) 25
set ::env(PL_TARGET_DENSITY) [ expr ($::env(FP_CORE_UTIL)+5) / 100.0 ]
set ::env(CELL_PAD) 6

# Obstruct met4 and met5, reduce layer count
set ::env(GLB_RT_MAXLAYER) 4
set ::env(GLB_RT_OBS) "met4 0 0 1000 1500,met5 0 0 1000 1500"
