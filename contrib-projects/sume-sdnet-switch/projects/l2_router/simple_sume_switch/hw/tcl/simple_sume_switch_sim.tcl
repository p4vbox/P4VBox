#
# Copyright (c) 2015 Georgina Kalogeridou
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme.
#
# Copyright (c) 2019 Mateus Saquetti
# All rights reserved.
#
# This software was modified by Institute of Informatics of the Federal
# University of Rio Grande do Sul (INF-UFRGS)
#
# Description:
#              Adapted to run in P4VBox architecture
# Create Date:
#              31.05.2019
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#

# Get P4VBox variables from enviroment
set arg_p4_switches $::env(P4_PROJ_SWITCHES)
set p4_switches [split $arg_p4_switches :]

# Set Project variables.
set design $::env(NF_PROJECT_NAME)
set top top_sim
set sim_top top_tb
set device  xc7vx690t-3-ffg1761
set proj_dir ./project
set public_repo_dir $::env(SUME_FOLDER)/lib/hw/
set xilinx_repo_dir $::env(XILINX_VIVADO)/data/ip/xilinx/
set repo_dir ./ip_repo
set bit_settings $::env(CONSTRAINTS)/generic_bit.xdc
set project_constraints $::env(NF_DESIGN_DIR)/hw/constraints/nf_sume_general.xdc
set nf_10g_constraints $::env(NF_DESIGN_DIR)/hw/constraints/nf_sume_10g.xdc


set test_name [lindex $argv 0]

#####################################
# Read IP Addresses and export registers
#####################################
source $::env(NF_DESIGN_DIR)/hw/tcl/$::env(NF_PROJECT_NAME)_defines.tcl -notrace

# Build project.
create_project -name ${design} -force -dir "$::env(NF_DESIGN_DIR)/hw/${proj_dir}" -part ${device}
set_property source_mgmt_mode DisplayOnly [current_project]
set_property top ${top} [current_fileset]
puts "\n Creating User Datapath reference project \n"

create_fileset -constrset -quiet constraints
file copy ${public_repo_dir}/ ${repo_dir}
set_property ip_repo_paths ${repo_dir} [current_fileset]
add_files -fileset constraints -norecurse ${bit_settings}
add_files -fileset constraints -norecurse ${project_constraints}
add_files -fileset constraints -norecurse ${nf_10g_constraints}
set_property is_enabled true [get_files ${project_constraints}]
set_property is_enabled true [get_files ${bit_settings}]
set_property is_enabled true [get_files ${project_constraints}]

update_ip_catalog


puts "\n All P4 switches = ${p4_switches} \n"
foreach p4_switch $p4_switches {
  set p4_switch_name nf_sdnet_${p4_switch}
  puts "Creating P4 Switch IP: ${p4_switch}. With name: ${p4_switch_name}"
  #source ../hw/create_ip/nf_sume_sdnet.tcl  # only need this if have sdnet_to_sume fifo in wrapper
  create_ip -name ${p4_switch_name} -vendor NetFPGA -library NetFPGA -module_name ${p4_switch_name}_ip
  set_property generate_synth_checkpoint false [get_files ${p4_switch_name}_ip.xci]
  reset_target all [get_ips ${p4_switch_name}_ip]
  generate_target all [get_ips ${p4_switch_name}_ip]
  puts ""
}


create_ip -name input_arbiter_drr -vendor NetFPGA -library NetFPGA -module_name input_arbiter_drr_ip
set_property -dict [list CONFIG.C_BASEADDR $INPUT_ARBITER_BASEADDR] [get_ips input_arbiter_drr_ip]
set_property generate_synth_checkpoint false [get_files input_arbiter_drr_ip.xci]
reset_target all [get_ips input_arbiter_drr_ip]
generate_target all [get_ips input_arbiter_drr_ip]

create_ip -name sss_output_queues -vendor NetFPGA -library NetFPGA -module_name sss_output_queues_ip
set_property -dict [list CONFIG.C_BASEADDR $OUTPUT_QUEUES_BASEADDR] [get_ips sss_output_queues_ip]
set_property generate_synth_checkpoint false [get_files sss_output_queues_ip.xci]
reset_target all [get_ips sss_output_queues_ip]
generate_target all [get_ips sss_output_queues_ip]

#Add ID block
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name identifier_ip
set_property -dict [list CONFIG.Interface_Type {AXI4} CONFIG.AXI_Type {AXI4_Lite} CONFIG.AXI_Slave_Type {Memory_Slave} CONFIG.Use_AXI_ID {false} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../create_ip/id_rom16x32.coe} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Remaining_Memory_Locations {DEADDEAD} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {1024} CONFIG.Read_Width_A {32} CONFIG.Operating_Mode_A {READ_FIRST} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false} CONFIG.Use_RSTB_Pin {true} CONFIG.Reset_Type {ASYNC} CONFIG.Port_A_Write_Rate {50} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips identifier_ip]
set_property generate_synth_checkpoint false [get_files identifier_ip.xci]
reset_target all [get_ips identifier_ip]
generate_target all [get_ips identifier_ip]

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_ip
set_property -dict [list CONFIG.PRIM_IN_FREQ {200.00} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} CONFIG.USE_SAFE_CLOCK_STARTUP {true} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.CLKIN1_JITTER_PS {50.0} CONFIG.CLKOUT1_DRIVES {BUFGCE} CONFIG.CLKOUT2_DRIVES {BUFGCE} CONFIG.CLKOUT3_DRIVES {BUFGCE} CONFIG.CLKOUT4_DRIVES {BUFGCE} CONFIG.CLKOUT5_DRIVES {BUFGCE} CONFIG.CLKOUT6_DRIVES {BUFGCE} CONFIG.CLKOUT7_DRIVES {BUFGCE} CONFIG.MMCM_CLKFBOUT_MULT_F {5.000} CONFIG.MMCM_CLKIN1_PERIOD {5.0} CONFIG.MMCM_CLKOUT0_DIVIDE_F {5.000} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_JITTER {98.146} CONFIG.CLKOUT1_PHASE_ERROR {89.971}] [get_ips clk_wiz_ip]
set_property generate_synth_checkpoint false [get_files clk_wiz_ip.xci]
reset_target all [get_ips clk_wiz_ip]
generate_target all [get_ips clk_wiz_ip]


create_ip -name barrier -vendor NetFPGA -library NetFPGA -module_name barrier_ip
reset_target all [get_ips barrier_ip]
generate_target all [get_ips barrier_ip]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip0
set_property -dict [list CONFIG.OUTPUT_FILE $::env(NF_DESIGN_DIR)/test/nf_interface_0_log.axi] [get_ips axis_sim_record_ip0]
reset_target all [get_ips axis_sim_record_ip0]
generate_target all [get_ips axis_sim_record_ip0]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip1
set_property -dict [list CONFIG.OUTPUT_FILE $::env(NF_DESIGN_DIR)/test/nf_interface_1_log.axi] [get_ips axis_sim_record_ip1]
reset_target all [get_ips axis_sim_record_ip1]
generate_target all [get_ips axis_sim_record_ip1]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip2
set_property -dict [list CONFIG.OUTPUT_FILE $::env(NF_DESIGN_DIR)/test/nf_interface_2_log.axi] [get_ips axis_sim_record_ip2]
reset_target all [get_ips axis_sim_record_ip2]
generate_target all [get_ips axis_sim_record_ip2]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip3
set_property -dict [list CONFIG.OUTPUT_FILE $::env(NF_DESIGN_DIR)/test/nf_interface_3_log.axi] [get_ips axis_sim_record_ip3]
reset_target all [get_ips axis_sim_record_ip3]
generate_target all [get_ips axis_sim_record_ip3]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip4
set_property -dict [list CONFIG.OUTPUT_FILE $::env(NF_DESIGN_DIR)/test/dma_0_log.axi] [get_ips axis_sim_record_ip4]
reset_target all [get_ips axis_sim_record_ip4]
generate_target all [get_ips axis_sim_record_ip4]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip0
set_property -dict [list CONFIG.input_file $::env(NF_DESIGN_DIR)/test/nf_interface_0_stim.axi] [get_ips axis_sim_stim_ip0]
generate_target all [get_ips axis_sim_stim_ip0]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip1
set_property -dict [list CONFIG.input_file $::env(NF_DESIGN_DIR)/test/nf_interface_1_stim.axi] [get_ips axis_sim_stim_ip1]
generate_target all [get_ips axis_sim_stim_ip1]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip2
set_property -dict [list CONFIG.input_file $::env(NF_DESIGN_DIR)/test/nf_interface_2_stim.axi] [get_ips axis_sim_stim_ip2]
generate_target all [get_ips axis_sim_stim_ip2]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip3
set_property -dict [list CONFIG.input_file $::env(NF_DESIGN_DIR)/test/nf_interface_3_stim.axi] [get_ips axis_sim_stim_ip3]
generate_target all [get_ips axis_sim_stim_ip3]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip4
set_property -dict [list CONFIG.input_file $::env(NF_DESIGN_DIR)/test/dma_0_stim.axi] [get_ips axis_sim_stim_ip4]
generate_target all [get_ips axis_sim_stim_ip4]

create_ip -name axi_sim_transactor -vendor NetFPGA -library NetFPGA -module_name axi_sim_transactor_ip
set_property -dict [list CONFIG.STIM_FILE $::env(NF_DESIGN_DIR)/test/reg_stim.axi CONFIG.EXPECT_FILE $::env(NF_DESIGN_DIR)/test/reg_expect.axi CONFIG.LOG_FILE $::env(NF_DESIGN_DIR)/test/reg_stim.log] [get_ips axi_sim_transactor_ip]
reset_target all [get_ips axi_sim_transactor_ip]
generate_target all [get_ips axi_sim_transactor_ip]

update_ip_catalog

source $::env(NF_DESIGN_DIR)/hw/tcl/control_sub_sim.tcl -notrace

read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/axi_clocking.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/input_p4_interface.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/control_p4_interface.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/small_fifo.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/fallthrough_small_fifo.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/output_p4_interface.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/top_sim.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/nf_datapath.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/top_tb.v"

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property top ${sim_top} [get_filesets sim_1]
set_property include_dirs ${proj_dir} [get_filesets sim_1]
set_property simulator_language Mixed [current_project]
set_property verilog_define { {SIMULATION=1} } [get_filesets sim_1]
set_property -name xsim.more_options -value {-testplusarg TESTNAME=basic_test} -objects [get_filesets sim_1]
set_property runtime {} [get_filesets sim_1]
set_property target_simulator xsim [current_project]
set_property compxlib.xsim_compiled_library_dir {} [current_project]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

set output [exec python $::env(NF_DESIGN_DIR)/test/${test_name}/run.py]
puts $output

set_property xsim.view {} [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral

# Close Untitled waveform and create a new wave to P4-NetFPGA signals
close_wave_config [current_wave_config]
create_wave_config P4-NetFPGA

set nf_datapath top_tb/top_sim/nf_datapath_0/
add_wave_divider {input arbiter input signals}
add_wave $nf_datapath/s_axis_0_tdata -color blue
add_wave $nf_datapath/s_axis_0_tkeep -color blue
add_wave $nf_datapath/s_axis_0_tuser -color blue
add_wave $nf_datapath/s_axis_0_tvalid -color blue
add_wave $nf_datapath/s_axis_0_tready -color blue
add_wave $nf_datapath/s_axis_0_tlast -color blue
add_wave $nf_datapath/s_axis_1_tdata -color gold
add_wave $nf_datapath/s_axis_1_tkeep -color gold
add_wave $nf_datapath/s_axis_1_tuser -color gold
add_wave $nf_datapath/s_axis_1_tvalid -color gold
add_wave $nf_datapath/s_axis_1_tready -color gold
add_wave $nf_datapath/s_axis_1_tlast -color gold
add_wave $nf_datapath/s_axis_2_tdata -color orange
add_wave $nf_datapath/s_axis_2_tkeep -color orange
add_wave $nf_datapath/s_axis_2_tuser -color orange
add_wave $nf_datapath/s_axis_2_tvalid -color orange
add_wave $nf_datapath/s_axis_2_tready -color orange
add_wave $nf_datapath/s_axis_2_tlast -color orange
add_wave $nf_datapath/s_axis_3_tdata -color purple
add_wave $nf_datapath/s_axis_3_tkeep -color purple
add_wave $nf_datapath/s_axis_3_tuser -color purple
add_wave $nf_datapath/s_axis_3_tvalid -color purple
add_wave $nf_datapath/s_axis_3_tready -color purple
add_wave $nf_datapath/s_axis_3_tlast -color purple
add_wave $nf_datapath/s_axis_4_tdata -color cyan
add_wave $nf_datapath/s_axis_4_tkeep -color cyan
add_wave $nf_datapath/s_axis_4_tuser -color cyan
add_wave $nf_datapath/s_axis_4_tvalid -color cyan
add_wave $nf_datapath/s_axis_4_tready -color cyan
add_wave $nf_datapath/s_axis_4_tlast -color cyan

add_wave_divider {output queues output signals}
add_wave $nf_datapath/m_axis_0_tdata -color blue
add_wave $nf_datapath/m_axis_0_tkeep -color blue
add_wave $nf_datapath/m_axis_0_tuser -color blue
add_wave $nf_datapath/m_axis_0_tvalid -color blue
add_wave $nf_datapath/m_axis_0_tready -color blue
add_wave $nf_datapath/m_axis_0_tlast -color blue
add_wave $nf_datapath/m_axis_1_tdata -color gold
add_wave $nf_datapath/m_axis_1_tkeep -color gold
add_wave $nf_datapath/m_axis_1_tuser -color gold
add_wave $nf_datapath/m_axis_1_tvalid -color gold
add_wave $nf_datapath/m_axis_1_tready -color gold
add_wave $nf_datapath/m_axis_1_tlast -color gold
add_wave $nf_datapath/m_axis_2_tdata -color orange
add_wave $nf_datapath/m_axis_2_tkeep -color orange
add_wave $nf_datapath/m_axis_2_tuser -color orange
add_wave $nf_datapath/m_axis_2_tvalid -color orange
add_wave $nf_datapath/m_axis_2_tready -color orange
add_wave $nf_datapath/m_axis_2_tlast -color orange
add_wave $nf_datapath/m_axis_3_tdata -color purple
add_wave $nf_datapath/m_axis_3_tkeep -color purple
add_wave $nf_datapath/m_axis_3_tuser -color purple
add_wave $nf_datapath/m_axis_3_tvalid -color purple
add_wave $nf_datapath/m_axis_3_tready -color purple
add_wave $nf_datapath/m_axis_3_tlast -color purple
add_wave $nf_datapath/m_axis_4_tdata -color cyan
add_wave $nf_datapath/m_axis_4_tkeep -color cyan
add_wave $nf_datapath/m_axis_4_tuser -color cyan
add_wave $nf_datapath/m_axis_4_tvalid -color cyan
add_wave $nf_datapath/m_axis_4_tready -color cyan
add_wave $nf_datapath/m_axis_4_tlast -color cyan

set input_arbiter_ip top_tb/top_sim/nf_datapath_0/input_arbiter_drr_v1_0/inst/
add_wave_divider {Input Arbiter Intern Signals}
add_wave $input_arbiter_ip/dbg_ddr_count0
add_wave $input_arbiter_ip/dbg_ddr_count1
add_wave $input_arbiter_ip/dbg_ddr_count2
add_wave $input_arbiter_ip/dbg_ddr_count3
add_wave $input_arbiter_ip/dbg_ddr_count4
add_wave $input_arbiter_ip/cur_queue

# Add top level AXI Lite control signals to P4_SWITCH
add_wave_divider {Top-Level SDNet Control Signals}
add_wave top_tb/top_sim/M02_AXI_araddr
add_wave top_tb/top_sim/M02_AXI_arprot
add_wave top_tb/top_sim/M02_AXI_arready
add_wave top_tb/top_sim/M02_AXI_arvalid
add_wave top_tb/top_sim/M02_AXI_awaddr
add_wave top_tb/top_sim/M02_AXI_awprot
add_wave top_tb/top_sim/M02_AXI_awready
add_wave top_tb/top_sim/M02_AXI_awvalid
add_wave top_tb/top_sim/M02_AXI_bready
add_wave top_tb/top_sim/M02_AXI_bresp
add_wave top_tb/top_sim/M02_AXI_bvalid
add_wave top_tb/top_sim/M02_AXI_rdata
add_wave top_tb/top_sim/M02_AXI_rready
add_wave top_tb/top_sim/M02_AXI_rresp
add_wave top_tb/top_sim/M02_AXI_rvalid
add_wave top_tb/top_sim/M02_AXI_wdata
add_wave top_tb/top_sim/M02_AXI_wready
add_wave top_tb/top_sim/M02_AXI_wstrb
add_wave top_tb/top_sim/M02_AXI_wvalid


# Create new waveform to P4VBox Signals
create_wave_config P4VBox
set_property needs_save false [get_wave_configs P4-NetFPGA]
set_property needs_save false [get_wave_configs P4VBox]

# Create variables to clock and reset sinals
set sig_clock /top_tb/top_sim/clk_200
set sig_resetn /top_tb/top_sim/sys_rst_n_c
add_wave_divider {Clock and Reset Global}
add_wave $sig_clock -name clock
add_wave $sig_resetn -name reset_n

# Add top level datapath IO
add_wave_divider {Output Packets}
add_wave $nf_datapath/m_axis_0_tdata -color blue -into P4VBox
add_wave $nf_datapath/m_axis_0_tvalid -color blue -into P4VBox
add_wave $nf_datapath/m_axis_1_tdata -color gold -into P4VBox
add_wave $nf_datapath/m_axis_1_tvalid -color gold -into P4VBox
add_wave $nf_datapath/m_axis_2_tdata -color orange -into P4VBox
add_wave $nf_datapath/m_axis_2_tvalid -color orange -into P4VBox
add_wave $nf_datapath/m_axis_3_tdata -color purple -into P4VBox
add_wave $nf_datapath/m_axis_3_tvalid -color purple -into P4VBox
add_wave $nf_datapath/m_axis_4_tdata -color cyan -into P4VBox
add_wave $nf_datapath/m_axis_4_tvalid -color cyan -into P4VBox

add_wave_divider {Input Packets}
add_wave $nf_datapath/s_axis_0_tdata -color blue -into P4VBox
add_wave $nf_datapath/s_axis_0_tvalid -color blue -into P4VBox
add_wave $nf_datapath/s_axis_1_tdata -color gold -into P4VBox
add_wave $nf_datapath/s_axis_1_tvalid -color gold -into P4VBox
add_wave $nf_datapath/s_axis_2_tdata -color orange -into P4VBox
add_wave $nf_datapath/s_axis_2_tvalid -color orange -into P4VBox
add_wave $nf_datapath/s_axis_3_tdata -color purple -into P4VBox
add_wave $nf_datapath/s_axis_3_tvalid -color purple -into P4VBox
add_wave $nf_datapath/s_axis_4_tdata -color cyan -into P4VBox
add_wave $nf_datapath/s_axis_4_tvalid -color cyan -into P4VBox

add_wave_divider {Datapath AXI Stream}
add_wave $sig_clock -name clock
add_wave $sig_resetn -name reset_n
add_wave_group Datapath_Output
add_wave $nf_datapath/m_axis_0_tdata -color blue -into Datapath_Output
add_wave $nf_datapath/m_axis_0_tkeep -color blue -into Datapath_Output
add_wave $nf_datapath/m_axis_0_tuser -color blue -into Datapath_Output
add_wave $nf_datapath/m_axis_0_tvalid -color blue -into Datapath_Output
add_wave $nf_datapath/m_axis_0_tready -color blue -into Datapath_Output
add_wave $nf_datapath/m_axis_0_tlast -color blue -into Datapath_Output
add_wave $nf_datapath/m_axis_1_tdata -color gold -into Datapath_Output
add_wave $nf_datapath/m_axis_1_tkeep -color gold -into Datapath_Output
add_wave $nf_datapath/m_axis_1_tuser -color gold -into Datapath_Output
add_wave $nf_datapath/m_axis_1_tvalid -color gold -into Datapath_Output
add_wave $nf_datapath/m_axis_1_tready -color gold -into Datapath_Output
add_wave $nf_datapath/m_axis_1_tlast -color gold -into Datapath_Output
add_wave $nf_datapath/m_axis_2_tdata -color orange -into Datapath_Output
add_wave $nf_datapath/m_axis_2_tkeep -color orange -into Datapath_Output
add_wave $nf_datapath/m_axis_2_tuser -color orange -into Datapath_Output
add_wave $nf_datapath/m_axis_2_tvalid -color orange -into Datapath_Output
add_wave $nf_datapath/m_axis_2_tready -color orange -into Datapath_Output
add_wave $nf_datapath/m_axis_2_tlast -color orange -into Datapath_Output
add_wave $nf_datapath/m_axis_3_tdata -color purple -into Datapath_Output
add_wave $nf_datapath/m_axis_3_tkeep -color purple -into Datapath_Output
add_wave $nf_datapath/m_axis_3_tuser -color purple -into Datapath_Output
add_wave $nf_datapath/m_axis_3_tvalid -color purple -into Datapath_Output
add_wave $nf_datapath/m_axis_3_tready -color purple -into Datapath_Output
add_wave $nf_datapath/m_axis_3_tlast -color purple -into Datapath_Output
add_wave $nf_datapath/m_axis_4_tdata -color cyan -into Datapath_Output
add_wave $nf_datapath/m_axis_4_tkeep -color cyan -into Datapath_Output
add_wave $nf_datapath/m_axis_4_tuser -color cyan -into Datapath_Output
add_wave $nf_datapath/m_axis_4_tvalid -color cyan -into Datapath_Output
add_wave $nf_datapath/m_axis_4_tready -color cyan -into Datapath_Output
add_wave $nf_datapath/m_axis_4_tlast -color cyan -into Datapath_Output
add_wave_group Datapath_Input
add_wave $nf_datapath/s_axis_0_tdata -color blue -into Datapath_Input
add_wave $nf_datapath/s_axis_0_tvalid -color blue -into Datapath_Input
add_wave $nf_datapath/s_axis_0_tkeep -color blue -into Datapath_Input
add_wave $nf_datapath/s_axis_0_tuser -color blue -into Datapath_Input
add_wave $nf_datapath/s_axis_0_tready -color blue -into Datapath_Input
add_wave $nf_datapath/s_axis_0_tlast -color blue -into Datapath_Input
add_wave $nf_datapath/s_axis_1_tdata -color gold -into Datapath_Input
add_wave $nf_datapath/s_axis_1_tkeep -color gold -into Datapath_Input
add_wave $nf_datapath/s_axis_1_tuser -color gold -into Datapath_Input
add_wave $nf_datapath/s_axis_1_tvalid -color gold -into Datapath_Input
add_wave $nf_datapath/s_axis_1_tready -color gold -into Datapath_Input
add_wave $nf_datapath/s_axis_1_tlast -color gold -into Datapath_Input
add_wave $nf_datapath/s_axis_2_tdata -color orange -into Datapath_Input
add_wave $nf_datapath/s_axis_2_tkeep -color orange -into Datapath_Input
add_wave $nf_datapath/s_axis_2_tuser -color orange -into Datapath_Input
add_wave $nf_datapath/s_axis_2_tvalid -color orange -into Datapath_Input
add_wave $nf_datapath/s_axis_2_tready -color orange -into Datapath_Input
add_wave $nf_datapath/s_axis_2_tlast -color orange -into Datapath_Input
add_wave $nf_datapath/s_axis_3_tdata -color purple -into Datapath_Input
add_wave $nf_datapath/s_axis_3_tkeep -color purple -into Datapath_Input
add_wave $nf_datapath/s_axis_3_tuser -color purple -into Datapath_Input
add_wave $nf_datapath/s_axis_3_tvalid -color purple -into Datapath_Input
add_wave $nf_datapath/s_axis_3_tready -color purple -into Datapath_Input
add_wave $nf_datapath/s_axis_3_tlast -color purple -into Datapath_Input
add_wave $nf_datapath/s_axis_4_tdata -color cyan -into Datapath_Input
add_wave $nf_datapath/s_axis_4_tkeep -color cyan -into Datapath_Input
add_wave $nf_datapath/s_axis_4_tuser -color cyan -into Datapath_Input
add_wave $nf_datapath/s_axis_4_tvalid -color cyan -into Datapath_Input
add_wave $nf_datapath/s_axis_4_tready -color cyan -into Datapath_Input
add_wave $nf_datapath/s_axis_4_tlast -color cyan -into Datapath_Input

# Control P4 Interface
add_wave_divider {Control P4 Interface}
add_wave $sig_clock -name clock
add_wave $sig_resetn -name reset_n
add_wave_group M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_AWADDR -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_AWVALID -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_AWREADY -color aqua -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_WDATA -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_WSTRB -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_WVALID -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_WREADY -color aqua -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_BRESP -color aqua -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_BVALID -color aqua -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_BREADY -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_ARADDR -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_ARVALID -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_ARREADY -color aqua -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_RDATA -color aqua -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_RRESP -color aqua -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_RVALID -color aqua -into M_AXI
add_wave $nf_datapath/control_p4_interface_0/M_AXI_RREADY -into M_AXI
add_wave_group S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_AWADDR -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_AWVALID -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_AWREADY -color aqua -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_WDATA -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_WSTRB -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_WVALID -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_WREADY -color aqua -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_BRESP -color aqua -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_BVALID -color aqua -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_BREADY -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_ARADDR -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_ARVALID -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_ARREADY -color aqua -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_RDATA -color aqua -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_RRESP -color aqua -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_RVALID -color aqua -into S_AXI_0
add_wave $nf_datapath/control_p4_interface_0/S_AXI_0_RREADY -into S_AXI_0
add_wave_group S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_AWADDR -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_AWVALID -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_AWREADY -color aqua -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_WDATA -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_WSTRB -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_WVALID -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_WREADY -color aqua -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_BRESP -color aqua -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_BVALID -color aqua -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_BREADY -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_ARADDR -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_ARVALID -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_ARREADY -color aqua -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_RDATA -color aqua -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_RRESP -color aqua -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_RVALID -color aqua -into S_AXI_1
add_wave $nf_datapath/control_p4_interface_0/S_AXI_1_RREADY -into S_AXI_1
add_wave_group Internal_CPI
add_wave $nf_datapath/control_p4_interface_0/axi_awaddr -into Internal_CPI
add_wave $nf_datapath/control_p4_interface_0/axi_awready -into Internal_CPI
add_wave $nf_datapath/control_p4_interface_0/axi_wready -into Internal_CPI
add_wave $nf_datapath/control_p4_interface_0/axi_bresp -into Internal_CPI
add_wave $nf_datapath/control_p4_interface_0/axi_bvalid -into Internal_CPI
add_wave $nf_datapath/control_p4_interface_0/axi_araddr -into Internal_CPI
add_wave $nf_datapath/control_p4_interface_0/axi_arready -into Internal_CPI
add_wave $nf_datapath/control_p4_interface_0/axi_rdata -into Internal_CPI
add_wave $nf_datapath/control_p4_interface_0/axi_rresp -into Internal_CPI
add_wave $nf_datapath/control_p4_interface_0/axi_rvalid -into Internal_CPI

# Input P4 Interface
set ipi $nf_datapath/input_p4_interface_0
add_wave_divider {Input P4 Interface}
add_wave $sig_clock -name clock
add_wave $sig_resetn -name reset_n
add_wave_group s_axis_IPI
add_wave $ipi/s_axis_tdata -into s_axis_IPI -color blue
add_wave $ipi/s_axis_tkeep -into s_axis_IPI -color blue
add_wave $ipi/s_axis_tuser -into s_axis_IPI -color blue
add_wave $ipi/s_axis_tvalid -into s_axis_IPI -color blue
add_wave $ipi/s_axis_tready -into s_axis_IPI -color blue
add_wave $ipi/s_axis_tlast -into s_axis_IPI -color blue
add_wave_group m_axis_0_IPI
add_wave $ipi/m_axis_0_tdata -into m_axis_0_IPI -color gold
add_wave $ipi/m_axis_0_tkeep -into m_axis_0_IPI -color gold
add_wave $ipi/m_axis_0_tuser -into m_axis_0_IPI -color gold
add_wave $ipi/m_axis_0_tvalid -into m_axis_0_IPI -color gold
add_wave $ipi/m_axis_0_tready -into m_axis_0_IPI -color gold
add_wave $ipi/m_axis_0_tlast -into m_axis_0_IPI -color gold
add_wave_group m_axis_1_IPI
add_wave $ipi/m_axis_1_tdata -into m_axis_1_IPI -color orange
add_wave $ipi/m_axis_1_tkeep -into m_axis_1_IPI -color orange
add_wave $ipi/m_axis_1_tuser -into m_axis_1_IPI -color orange
add_wave $ipi/m_axis_1_tvalid -into m_axis_1_IPI -color orange
add_wave $ipi/m_axis_1_tready -into m_axis_1_IPI -color orange
add_wave $ipi/m_axis_1_tlast -into m_axis_1_IPI -color orange
add_wave_group m_axis_2_IPI
add_wave $ipi/m_axis_2_tdata -into m_axis_2_IPI -color purple
add_wave $ipi/m_axis_2_tkeep -into m_axis_2_IPI -color purple
add_wave $ipi/m_axis_2_tuser -into m_axis_2_IPI -color purple
add_wave $ipi/m_axis_2_tvalid -into m_axis_2_IPI -color purple
add_wave $ipi/m_axis_2_tready -into m_axis_2_IPI -color purple
add_wave $ipi/m_axis_2_tlast -into m_axis_2_IPI -color purple
add_wave_group m_axis_3_IPI
add_wave $ipi/m_axis_3_tdata -into m_axis_3_IPI -color cyan
add_wave $ipi/m_axis_3_tkeep -into m_axis_3_IPI -color cyan
add_wave $ipi/m_axis_3_tuser -into m_axis_3_IPI -color cyan
add_wave $ipi/m_axis_3_tvalid -into m_axis_3_IPI -color cyan
add_wave $ipi/m_axis_3_tready -into m_axis_3_IPI -color cyan
add_wave $ipi/m_axis_3_tlast -into m_axis_3_IPI -color cyan
add_wave_group vlan_IPI
add_wave $ipi/vlan_tdata -into vlan_IPI -color aqua
add_wave $ipi/vlan_prot_id -into vlan_IPI -color aqua
add_wave $ipi/vlan_info -into vlan_IPI -color aqua
add_wave $ipi/vlan_info_prio -into vlan_IPI -color aqua
add_wave $ipi/vlan_info_drop -into vlan_IPI -color aqua
add_wave $ipi/vlan_info_id -into vlan_IPI -color aqua
add_wave_group Internal_IPI
add_wave $ipi/ipi_state -into Internal_IPI
add_wave $ipi/ipi_vlan_prot_id -into Internal_IPI
add_wave $ipi/ipi_vlan_info_id -into Internal_IPI


run 65us

set_property needs_save false [get_wave_configs P4-NetFPGA]
set_property needs_save false [get_wave_configs P4VBox]

# # Add SDNet Interface Signals
# set sdnet_ip top_tb/top_sim/nf_datapath_0/nf_sume_sdnet_wrapper_1/inst/SimpleSumeSwitch_inst/
# add_wave_divider {SDNet Control Interface}
# add_wave top_tb/top_sim/nf_datapath_0/nf_sume_sdnet_wrapper_1/inst/internal_rst_done -color yellow
# add_wave $sdnet_ip/control_S_AXI_AWADDR
# add_wave $sdnet_ip/control_S_AXI_AWVALID
# add_wave $sdnet_ip/control_S_AXI_AWREADY
# add_wave $sdnet_ip/control_S_AXI_WDATA
# add_wave $sdnet_ip/control_S_AXI_WSTRB
# add_wave $sdnet_ip/control_S_AXI_WVALID
# add_wave $sdnet_ip/control_S_AXI_WREADY
# add_wave $sdnet_ip/control_S_AXI_BRESP
# add_wave $sdnet_ip/control_S_AXI_BVALID
# add_wave $sdnet_ip/control_S_AXI_BREADY
# add_wave $sdnet_ip/control_S_AXI_ARADDR
# add_wave $sdnet_ip/control_S_AXI_ARVALID
# add_wave $sdnet_ip/control_S_AXI_ARREADY
# add_wave $sdnet_ip/control_S_AXI_RDATA
# add_wave $sdnet_ip/control_S_AXI_RRESP
# add_wave $sdnet_ip/control_S_AXI_RVALID
# add_wave $sdnet_ip/control_S_AXI_RREADY
#
# set nf_sume_sdnet_ip top_tb/top_sim/nf_datapath_0/nf_sume_sdnet_wrapper_1/inst/
# add_wave_divider {nf_sume_sdnet input interface}
# add_wave $sdnet_ip/clk_lookup_rst
# add_wave $sdnet_ip/clk_lookup
# add_wave $nf_sume_sdnet_ip/s_axis_tdata -radix hex
# add_wave $nf_sume_sdnet_ip/s_axis_tkeep -radix hex
# add_wave $nf_sume_sdnet_ip/s_axis_tvalid
# add_wave $nf_sume_sdnet_ip/s_axis_tready
# add_wave $nf_sume_sdnet_ip/s_axis_tlast
#
# add_wave_divider {SDNet Tuple-In}
# add_wave $nf_sume_sdnet_ip/sume_tuple_in_VALID
# add_wave $nf_sume_sdnet_ip/s_axis_tuser -radix hex
# add_wave $nf_sume_sdnet_ip/in_pkt_len
# add_wave $nf_sume_sdnet_ip/in_src_port
# add_wave $nf_sume_sdnet_ip/in_dst_port
#
# add_wave_divider {nf_sume_sdnet output interface}
# add_wave $sdnet_ip/clk_lookup_rst
# add_wave $sdnet_ip/clk_lookup
# add_wave $nf_sume_sdnet_ip/m_axis_tdata -radix hex
# add_wave $nf_sume_sdnet_ip/m_axis_tkeep -radix hex
# add_wave $nf_sume_sdnet_ip/m_axis_tvalid
# add_wave $nf_sume_sdnet_ip/m_axis_tready
# add_wave $nf_sume_sdnet_ip/m_axis_tlast
#
# add_wave_divider {SDNet Tuple-Out}
# add_wave $nf_sume_sdnet_ip/sume_tuple_out_VALID
# add_wave $nf_sume_sdnet_ip/m_axis_tuser -radix hex
# add_wave $nf_sume_sdnet_ip/out_pkt_len
# add_wave $nf_sume_sdnet_ip/out_src_port
# add_wave $nf_sume_sdnet_ip/out_dst_port
