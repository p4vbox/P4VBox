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
# Unless requipink by applicable law or agreed to in writing, Work distributed
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
set vswitch_id 0
foreach p4_switch $p4_switches {
  set vswitch_name vSwitch${vswitch_id}
  set p4_switch_name nf_sdnet_${vswitch_name}
  puts "Creating P4 Switch IP: ${p4_switch}. With name: ${p4_switch_name}"
  #source ../hw/create_ip/nf_sume_sdnet.tcl  # only need this if have sdnet_to_sume fifo in wrapper
  create_ip -name ${p4_switch_name} -vendor NetFPGA -library NetFPGA -module_name ${p4_switch_name}_ip
  set_property generate_synth_checkpoint false [get_files ${p4_switch_name}_ip.xci]
  reset_target all [get_ips ${p4_switch_name}_ip]
  generate_target all [get_ips ${p4_switch_name}_ip]
  incr vswitch_id
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
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/input_vs_interface.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/control_vs_interface.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/small_fifo.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/fallthrough_small_fifo.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/output_vs_interface.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/wrapper_vSwitch1.v"
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
add_wave $nf_datapath/s_axis_0_tdata -color teal
add_wave $nf_datapath/s_axis_0_tkeep -color teal
add_wave $nf_datapath/s_axis_0_tuser -color teal
add_wave $nf_datapath/s_axis_0_tvalid -color teal
add_wave $nf_datapath/s_axis_0_tready -color teal
add_wave $nf_datapath/s_axis_0_tlast -color teal
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
add_wave $nf_datapath/s_axis_3_tdata -color maroon
add_wave $nf_datapath/s_axis_3_tkeep -color maroon
add_wave $nf_datapath/s_axis_3_tuser -color maroon
add_wave $nf_datapath/s_axis_3_tvalid -color maroon
add_wave $nf_datapath/s_axis_3_tready -color maroon
add_wave $nf_datapath/s_axis_3_tlast -color maroon
add_wave $nf_datapath/s_axis_4_tdata -color khaki
add_wave $nf_datapath/s_axis_4_tkeep -color khaki
add_wave $nf_datapath/s_axis_4_tuser -color khaki
add_wave $nf_datapath/s_axis_4_tvalid -color khaki
add_wave $nf_datapath/s_axis_4_tready -color khaki
add_wave $nf_datapath/s_axis_4_tlast -color khaki

add_wave_divider {output queues output signals}
add_wave $nf_datapath/m_axis_0_tdata -color teal
add_wave $nf_datapath/m_axis_0_tkeep -color teal
add_wave $nf_datapath/m_axis_0_tuser -color teal
add_wave $nf_datapath/m_axis_0_tvalid -color teal
add_wave $nf_datapath/m_axis_0_tready -color teal
add_wave $nf_datapath/m_axis_0_tlast -color teal
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
add_wave $nf_datapath/m_axis_3_tdata -color maroon
add_wave $nf_datapath/m_axis_3_tkeep -color maroon
add_wave $nf_datapath/m_axis_3_tuser -color maroon
add_wave $nf_datapath/m_axis_3_tvalid -color maroon
add_wave $nf_datapath/m_axis_3_tready -color maroon
add_wave $nf_datapath/m_axis_3_tlast -color maroon
add_wave $nf_datapath/m_axis_4_tdata -color khaki
add_wave $nf_datapath/m_axis_4_tkeep -color khaki
add_wave $nf_datapath/m_axis_4_tuser -color khaki
add_wave $nf_datapath/m_axis_4_tvalid -color khaki
add_wave $nf_datapath/m_axis_4_tready -color khaki
add_wave $nf_datapath/m_axis_4_tlast -color khaki

set input_arbiter_ip top_tb/top_sim/nf_datapath_0/IvSI/input_arbiter_drr_v1_0/inst/
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
add_wave_divider {Clock and Reset Global} -color white
add_wave $sig_clock -name clock
add_wave $sig_resetn -name reset_n

# Add top level datapath IO
add_wave_divider {Output Packets} -color white
add_wave_virtual_bus Port_0_Out -color teal
add_wave $nf_datapath/m_axis_0_tdata -into Port_0_Out -color teal
add_wave $nf_datapath/m_axis_0_tvalid -into Port_0_Out -color teal
add_wave_virtual_bus Port_1_Out -color gold
add_wave $nf_datapath/m_axis_1_tdata -into Port_1_Out -color gold
add_wave $nf_datapath/m_axis_1_tvalid -into Port_1_Out -color gold
add_wave_virtual_bus Port_2_Out -color orange
add_wave $nf_datapath/m_axis_2_tdata -into Port_2_Out -color orange
add_wave $nf_datapath/m_axis_2_tvalid -into Port_2_Out -color orange
add_wave_virtual_bus Port_3_Out -color maroon
add_wave $nf_datapath/m_axis_3_tdata -into Port_3_Out -color maroon
add_wave $nf_datapath/m_axis_3_tvalid -into Port_3_Out -color maroon
add_wave_virtual_bus DMA_Out -color khaki
add_wave $nf_datapath/m_axis_4_tdata -into DMA_Out -color khaki
add_wave $nf_datapath/m_axis_4_tvalid -into DMA_Out -color khaki

add_wave_divider {Input Packets} -color white
add_wave_virtual_bus Port_0_In -color teal
add_wave $nf_datapath/s_axis_0_tdata -into Port_0_In -color teal
add_wave $nf_datapath/s_axis_0_tvalid -into Port_0_In -color teal
add_wave_virtual_bus Port_1_In -color gold
add_wave $nf_datapath/s_axis_1_tdata -into Port_1_In -color gold
add_wave $nf_datapath/s_axis_1_tvalid -into Port_1_In -color gold
add_wave_virtual_bus Port_2_In -color orange
add_wave $nf_datapath/s_axis_2_tdata -into Port_2_In -color orange
add_wave $nf_datapath/s_axis_2_tvalid -into Port_2_In -color orange
add_wave_virtual_bus Port_3_In -color maroon
add_wave $nf_datapath/s_axis_3_tdata -into Port_3_In -color maroon
add_wave $nf_datapath/s_axis_3_tvalid -into Port_3_In -color maroon
add_wave_virtual_bus DMA_In -color khaki
add_wave $nf_datapath/s_axis_4_tdata -into DMA_In -color khaki
add_wave $nf_datapath/s_axis_4_tvalid -into DMA_In -color khaki

add_wave_divider {Datapath AXI Stream} -color white
add_wave_group Datapath_Output
add_wave $nf_datapath/m_axis_0_tdata -into Datapath_Output -color teal
add_wave $nf_datapath/m_axis_0_tkeep -into Datapath_Output -color teal
add_wave $nf_datapath/m_axis_0_tuser -into Datapath_Output -color teal
add_wave $nf_datapath/m_axis_0_tvalid -into Datapath_Output -color teal
add_wave $nf_datapath/m_axis_0_tready -into Datapath_Output -color teal
add_wave $nf_datapath/m_axis_0_tlast -into Datapath_Output -color teal
add_wave $nf_datapath/m_axis_1_tdata -into Datapath_Output -color gold
add_wave $nf_datapath/m_axis_1_tkeep -into Datapath_Output -color gold
add_wave $nf_datapath/m_axis_1_tuser -into Datapath_Output -color gold
add_wave $nf_datapath/m_axis_1_tvalid -into Datapath_Output -color gold
add_wave $nf_datapath/m_axis_1_tready -into Datapath_Output -color gold
add_wave $nf_datapath/m_axis_1_tlast -into Datapath_Output -color gold
add_wave $nf_datapath/m_axis_2_tdata -into Datapath_Output -color orange
add_wave $nf_datapath/m_axis_2_tkeep -into Datapath_Output -color orange
add_wave $nf_datapath/m_axis_2_tuser -into Datapath_Output -color orange
add_wave $nf_datapath/m_axis_2_tvalid -into Datapath_Output -color orange
add_wave $nf_datapath/m_axis_2_tready -into Datapath_Output -color orange
add_wave $nf_datapath/m_axis_2_tlast -into Datapath_Output -color orange
add_wave $nf_datapath/m_axis_3_tdata -into Datapath_Output -color maroon
add_wave $nf_datapath/m_axis_3_tkeep -into Datapath_Output -color maroon
add_wave $nf_datapath/m_axis_3_tuser -into Datapath_Output -color maroon
add_wave $nf_datapath/m_axis_3_tvalid -into Datapath_Output -color maroon
add_wave $nf_datapath/m_axis_3_tready -into Datapath_Output -color maroon
add_wave $nf_datapath/m_axis_3_tlast -into Datapath_Output -color maroon
add_wave $nf_datapath/m_axis_4_tdata -into Datapath_Output -color khaki
add_wave $nf_datapath/m_axis_4_tkeep -into Datapath_Output -color khaki
add_wave $nf_datapath/m_axis_4_tuser -into Datapath_Output -color khaki
add_wave $nf_datapath/m_axis_4_tvalid -into Datapath_Output -color khaki
add_wave $nf_datapath/m_axis_4_tready -into Datapath_Output -color khaki
add_wave $nf_datapath/m_axis_4_tlast -into Datapath_Output -color khaki
add_wave_group Datapath_Input
add_wave $nf_datapath/s_axis_0_tdata -into Datapath_Input -color teal
add_wave $nf_datapath/s_axis_0_tvalid -into Datapath_Input -color teal
add_wave $nf_datapath/s_axis_0_tkeep -into Datapath_Input -color teal
add_wave $nf_datapath/s_axis_0_tuser -into Datapath_Input -color teal
add_wave $nf_datapath/s_axis_0_tready -into Datapath_Input -color teal
add_wave $nf_datapath/s_axis_0_tlast -into Datapath_Input -color teal
add_wave $nf_datapath/s_axis_1_tdata -into Datapath_Input -color gold
add_wave $nf_datapath/s_axis_1_tkeep -into Datapath_Input -color gold
add_wave $nf_datapath/s_axis_1_tuser -into Datapath_Input -color gold
add_wave $nf_datapath/s_axis_1_tvalid -into Datapath_Input -color gold
add_wave $nf_datapath/s_axis_1_tready -into Datapath_Input -color gold
add_wave $nf_datapath/s_axis_1_tlast -into Datapath_Input -color gold
add_wave $nf_datapath/s_axis_2_tdata -into Datapath_Input -color orange
add_wave $nf_datapath/s_axis_2_tkeep -into Datapath_Input -color orange
add_wave $nf_datapath/s_axis_2_tuser -into Datapath_Input -color orange
add_wave $nf_datapath/s_axis_2_tvalid -into Datapath_Input -color orange
add_wave $nf_datapath/s_axis_2_tready -into Datapath_Input -color orange
add_wave $nf_datapath/s_axis_2_tlast -into Datapath_Input -color orange
add_wave $nf_datapath/s_axis_3_tdata -into Datapath_Input -color maroon
add_wave $nf_datapath/s_axis_3_tkeep -into Datapath_Input -color maroon
add_wave $nf_datapath/s_axis_3_tuser -into Datapath_Input -color maroon
add_wave $nf_datapath/s_axis_3_tvalid -into Datapath_Input -color maroon
add_wave $nf_datapath/s_axis_3_tready -into Datapath_Input -color maroon
add_wave $nf_datapath/s_axis_3_tlast -into Datapath_Input -color maroon
add_wave $nf_datapath/s_axis_4_tdata -into Datapath_Input -color khaki
add_wave $nf_datapath/s_axis_4_tkeep -into Datapath_Input -color khaki
add_wave $nf_datapath/s_axis_4_tuser -into Datapath_Input -color khaki
add_wave $nf_datapath/s_axis_4_tvalid -into Datapath_Input -color khaki
add_wave $nf_datapath/s_axis_4_tready -into Datapath_Input -color khaki
add_wave $nf_datapath/s_axis_4_tlast -into Datapath_Input -color khaki

# Control vS Interface
set CvSI $nf_datapath/CvSI
add_wave_divider {Control P4 Interface} -color darkgray
add_wave_virtual_bus clock_CvSI
add_wave $sig_clock -name clock -into clock_CvSI
add_wave $sig_resetn -name reset_n -into clock_CvSI
add_wave_group M_AXI
add_wave $CvSI/M_AXI_AWADDR -into M_AXI
add_wave $CvSI/M_AXI_AWVALID -into M_AXI
add_wave $CvSI/M_AXI_AWREADY -into M_AXI -color khaki
add_wave $CvSI/M_AXI_WDATA -into M_AXI
add_wave $CvSI/M_AXI_WSTRB -into M_AXI
add_wave $CvSI/M_AXI_WVALID -into M_AXI
add_wave $CvSI/M_AXI_WREADY -into M_AXI -color khaki
add_wave $CvSI/M_AXI_BRESP -into M_AXI -color khaki
add_wave $CvSI/M_AXI_BVALID -into M_AXI -color khaki
add_wave $CvSI/M_AXI_BREADY -into M_AXI
add_wave $CvSI/M_AXI_ARADDR -into M_AXI
add_wave $CvSI/M_AXI_ARVALID -into M_AXI
add_wave $CvSI/M_AXI_ARREADY -into M_AXI -color khaki
add_wave $CvSI/M_AXI_RDATA -into M_AXI -color khaki
add_wave $CvSI/M_AXI_RRESP -into M_AXI -color khaki
add_wave $CvSI/M_AXI_RVALID -into M_AXI -color khaki
add_wave $CvSI/M_AXI_RREADY -into M_AXI
add_wave_group S_AXI_vS0
add_wave $CvSI/S_AXI_vS0_AWADDR -into S_AXI_vS0
add_wave $CvSI/S_AXI_vS0_AWVALID -into S_AXI_vS0
add_wave $CvSI/S_AXI_vS0_AWREADY -into S_AXI_vS0 -color khaki
add_wave $CvSI/S_AXI_vS0_WDATA -into S_AXI_vS0
add_wave $CvSI/S_AXI_vS0_WSTRB -into S_AXI_vS0
add_wave $CvSI/S_AXI_vS0_WVALID -into S_AXI_vS0
add_wave $CvSI/S_AXI_vS0_WREADY -into S_AXI_vS0 -color khaki
add_wave $CvSI/S_AXI_vS0_BRESP -into S_AXI_vS0 -color khaki
add_wave $CvSI/S_AXI_vS0_BVALID -into S_AXI_vS0 -color khaki
add_wave $CvSI/S_AXI_vS0_BREADY -into S_AXI_vS0
add_wave $CvSI/S_AXI_vS0_ARADDR -into S_AXI_vS0
add_wave $CvSI/S_AXI_vS0_ARVALID -into S_AXI_vS0
add_wave $CvSI/S_AXI_vS0_ARREADY -into S_AXI_vS0 -color khaki
add_wave $CvSI/S_AXI_vS0_RDATA -into S_AXI_vS0 -color khaki
add_wave $CvSI/S_AXI_vS0_RRESP -into S_AXI_vS0 -color khaki
add_wave $CvSI/S_AXI_vS0_RVALID -into S_AXI_vS0 -color khaki
add_wave $CvSI/S_AXI_vS0_RREADY -into S_AXI_vS0
add_wave_group S_AXI_vS1
add_wave $CvSI/S_AXI_vS1_AWADDR -into S_AXI_vS1
add_wave $CvSI/S_AXI_vS1_AWVALID -into S_AXI_vS1
add_wave $CvSI/S_AXI_vS1_AWREADY -into S_AXI_vS1 -color khaki
add_wave $CvSI/S_AXI_vS1_WDATA -into S_AXI_vS1
add_wave $CvSI/S_AXI_vS1_WSTRB -into S_AXI_vS1
add_wave $CvSI/S_AXI_vS1_WVALID -into S_AXI_vS1
add_wave $CvSI/S_AXI_vS1_WREADY -into S_AXI_vS1 -color khaki
add_wave $CvSI/S_AXI_vS1_BRESP -into S_AXI_vS1 -color khaki
add_wave $CvSI/S_AXI_vS1_BVALID -into S_AXI_vS1 -color khaki
add_wave $CvSI/S_AXI_vS1_BREADY -into S_AXI_vS1
add_wave $CvSI/S_AXI_vS1_ARADDR -into S_AXI_vS1
add_wave $CvSI/S_AXI_vS1_ARVALID -into S_AXI_vS1
add_wave $CvSI/S_AXI_vS1_ARREADY -into S_AXI_vS1 -color khaki
add_wave $CvSI/S_AXI_vS1_RDATA -into S_AXI_vS1 -color khaki
add_wave $CvSI/S_AXI_vS1_RRESP -into S_AXI_vS1 -color khaki
add_wave $CvSI/S_AXI_vS1_RVALID -into S_AXI_vS1 -color khaki
add_wave $CvSI/S_AXI_vS1_RREADY -into S_AXI_vS1
add_wave_group S_AXI_vS2
add_wave $CvSI/S_AXI_vS2_AWADDR -into S_AXI_vS2
add_wave $CvSI/S_AXI_vS2_AWVALID -into S_AXI_vS2
add_wave $CvSI/S_AXI_vS2_AWREADY -into S_AXI_vS2 -color khaki
add_wave $CvSI/S_AXI_vS2_WDATA -into S_AXI_vS2
add_wave $CvSI/S_AXI_vS2_WSTRB -into S_AXI_vS2
add_wave $CvSI/S_AXI_vS2_WVALID -into S_AXI_vS2
add_wave $CvSI/S_AXI_vS2_WREADY -into S_AXI_vS2 -color khaki
add_wave $CvSI/S_AXI_vS2_BRESP -into S_AXI_vS2 -color khaki
add_wave $CvSI/S_AXI_vS2_BVALID -into S_AXI_vS2 -color khaki
add_wave $CvSI/S_AXI_vS2_BREADY -into S_AXI_vS2
add_wave $CvSI/S_AXI_vS2_ARADDR -into S_AXI_vS2
add_wave $CvSI/S_AXI_vS2_ARVALID -into S_AXI_vS2
add_wave $CvSI/S_AXI_vS2_ARREADY -into S_AXI_vS2 -color khaki
add_wave $CvSI/S_AXI_vS2_RDATA -into S_AXI_vS2 -color khaki
add_wave $CvSI/S_AXI_vS2_RRESP -into S_AXI_vS2 -color khaki
add_wave $CvSI/S_AXI_vS2_RVALID -into S_AXI_vS2 -color khaki
add_wave $CvSI/S_AXI_vS2_RREADY -into S_AXI_vS2
add_wave_group S_AXI_vS3
add_wave $CvSI/S_AXI_vS3_AWADDR -into S_AXI_vS3
add_wave $CvSI/S_AXI_vS3_AWVALID -into S_AXI_vS3
add_wave $CvSI/S_AXI_vS3_AWREADY -into S_AXI_vS3 -color khaki
add_wave $CvSI/S_AXI_vS3_WDATA -into S_AXI_vS3
add_wave $CvSI/S_AXI_vS3_WSTRB -into S_AXI_vS3
add_wave $CvSI/S_AXI_vS3_WVALID -into S_AXI_vS3
add_wave $CvSI/S_AXI_vS3_WREADY -into S_AXI_vS3 -color khaki
add_wave $CvSI/S_AXI_vS3_BRESP -into S_AXI_vS3 -color khaki
add_wave $CvSI/S_AXI_vS3_BVALID -into S_AXI_vS3 -color khaki
add_wave $CvSI/S_AXI_vS3_BREADY -into S_AXI_vS3
add_wave $CvSI/S_AXI_vS3_ARADDR -into S_AXI_vS3
add_wave $CvSI/S_AXI_vS3_ARVALID -into S_AXI_vS3
add_wave $CvSI/S_AXI_vS3_ARREADY -into S_AXI_vS3 -color khaki
add_wave $CvSI/S_AXI_vS3_RDATA -into S_AXI_vS3 -color khaki
add_wave $CvSI/S_AXI_vS3_RRESP -into S_AXI_vS3 -color khaki
add_wave $CvSI/S_AXI_vS3_RVALID -into S_AXI_vS3 -color khaki
add_wave $CvSI/S_AXI_vS3_RREADY -into S_AXI_vS3
add_wave_group S_AXI_vS4
add_wave $CvSI/S_AXI_vS4_AWADDR -into S_AXI_vS4
add_wave $CvSI/S_AXI_vS4_AWVALID -into S_AXI_vS4
add_wave $CvSI/S_AXI_vS4_AWREADY -into S_AXI_vS4 -color khaki
add_wave $CvSI/S_AXI_vS4_WDATA -into S_AXI_vS4
add_wave $CvSI/S_AXI_vS4_WSTRB -into S_AXI_vS4
add_wave $CvSI/S_AXI_vS4_WVALID -into S_AXI_vS4
add_wave $CvSI/S_AXI_vS4_WREADY -into S_AXI_vS4 -color khaki
add_wave $CvSI/S_AXI_vS4_BRESP -into S_AXI_vS4 -color khaki
add_wave $CvSI/S_AXI_vS4_BVALID -into S_AXI_vS4 -color khaki
add_wave $CvSI/S_AXI_vS4_BREADY -into S_AXI_vS4
add_wave $CvSI/S_AXI_vS4_ARADDR -into S_AXI_vS4
add_wave $CvSI/S_AXI_vS4_ARVALID -into S_AXI_vS4
add_wave $CvSI/S_AXI_vS4_ARREADY -into S_AXI_vS4 -color khaki
add_wave $CvSI/S_AXI_vS4_RDATA -into S_AXI_vS4 -color khaki
add_wave $CvSI/S_AXI_vS4_RRESP -into S_AXI_vS4 -color khaki
add_wave $CvSI/S_AXI_vS4_RVALID -into S_AXI_vS4 -color khaki
add_wave $CvSI/S_AXI_vS4_RREADY -into S_AXI_vS4
add_wave_group S_AXI_vS5
add_wave $CvSI/S_AXI_vS5_AWADDR -into S_AXI_vS5
add_wave $CvSI/S_AXI_vS5_AWVALID -into S_AXI_vS5
add_wave $CvSI/S_AXI_vS5_AWREADY -into S_AXI_vS5 -color khaki
add_wave $CvSI/S_AXI_vS5_WDATA -into S_AXI_vS5
add_wave $CvSI/S_AXI_vS5_WSTRB -into S_AXI_vS5
add_wave $CvSI/S_AXI_vS5_WVALID -into S_AXI_vS5
add_wave $CvSI/S_AXI_vS5_WREADY -into S_AXI_vS5 -color khaki
add_wave $CvSI/S_AXI_vS5_BRESP -into S_AXI_vS5 -color khaki
add_wave $CvSI/S_AXI_vS5_BVALID -into S_AXI_vS5 -color khaki
add_wave $CvSI/S_AXI_vS5_BREADY -into S_AXI_vS5
add_wave $CvSI/S_AXI_vS5_ARADDR -into S_AXI_vS5
add_wave $CvSI/S_AXI_vS5_ARVALID -into S_AXI_vS5
add_wave $CvSI/S_AXI_vS5_ARREADY -into S_AXI_vS5 -color khaki
add_wave $CvSI/S_AXI_vS5_RDATA -into S_AXI_vS5 -color khaki
add_wave $CvSI/S_AXI_vS5_RRESP -into S_AXI_vS5 -color khaki
add_wave $CvSI/S_AXI_vS5_RVALID -into S_AXI_vS5 -color khaki
add_wave $CvSI/S_AXI_vS5_RREADY -into S_AXI_vS5
add_wave_group S_AXI_vS6
add_wave $CvSI/S_AXI_vS6_AWADDR -into S_AXI_vS6
add_wave $CvSI/S_AXI_vS6_AWVALID -into S_AXI_vS6
add_wave $CvSI/S_AXI_vS6_AWREADY -into S_AXI_vS6 -color khaki
add_wave $CvSI/S_AXI_vS6_WDATA -into S_AXI_vS6
add_wave $CvSI/S_AXI_vS6_WSTRB -into S_AXI_vS6
add_wave $CvSI/S_AXI_vS6_WVALID -into S_AXI_vS6
add_wave $CvSI/S_AXI_vS6_WREADY -into S_AXI_vS6 -color khaki
add_wave $CvSI/S_AXI_vS6_BRESP -into S_AXI_vS6 -color khaki
add_wave $CvSI/S_AXI_vS6_BVALID -into S_AXI_vS6 -color khaki
add_wave $CvSI/S_AXI_vS6_BREADY -into S_AXI_vS6
add_wave $CvSI/S_AXI_vS6_ARADDR -into S_AXI_vS6
add_wave $CvSI/S_AXI_vS6_ARVALID -into S_AXI_vS6
add_wave $CvSI/S_AXI_vS6_ARREADY -into S_AXI_vS6 -color khaki
add_wave $CvSI/S_AXI_vS6_RDATA -into S_AXI_vS6 -color khaki
add_wave $CvSI/S_AXI_vS6_RRESP -into S_AXI_vS6 -color khaki
add_wave $CvSI/S_AXI_vS6_RVALID -into S_AXI_vS6 -color khaki
add_wave $CvSI/S_AXI_vS6_RREADY -into S_AXI_vS6
add_wave_group S_AXI_vS7
add_wave $CvSI/S_AXI_vS7_AWADDR -into S_AXI_vS7
add_wave $CvSI/S_AXI_vS7_AWVALID -into S_AXI_vS7
add_wave $CvSI/S_AXI_vS7_AWREADY -into S_AXI_vS7 -color khaki
add_wave $CvSI/S_AXI_vS7_WDATA -into S_AXI_vS7
add_wave $CvSI/S_AXI_vS7_WSTRB -into S_AXI_vS7
add_wave $CvSI/S_AXI_vS7_WVALID -into S_AXI_vS7
add_wave $CvSI/S_AXI_vS7_WREADY -into S_AXI_vS7 -color khaki
add_wave $CvSI/S_AXI_vS7_BRESP -into S_AXI_vS7 -color khaki
add_wave $CvSI/S_AXI_vS7_BVALID -into S_AXI_vS7 -color khaki
add_wave $CvSI/S_AXI_vS7_BREADY -into S_AXI_vS7
add_wave $CvSI/S_AXI_vS7_ARADDR -into S_AXI_vS7
add_wave $CvSI/S_AXI_vS7_ARVALID -into S_AXI_vS7
add_wave $CvSI/S_AXI_vS7_ARREADY -into S_AXI_vS7 -color khaki
add_wave $CvSI/S_AXI_vS7_RDATA -into S_AXI_vS7 -color khaki
add_wave $CvSI/S_AXI_vS7_RRESP -into S_AXI_vS7 -color khaki
add_wave $CvSI/S_AXI_vS7_RVALID -into S_AXI_vS7 -color khaki
add_wave $CvSI/S_AXI_vS7_RREADY -into S_AXI_vS7
add_wave_group Internal_CvSI
add_wave $CvSI/axi_awaddr -into Internal_CvSI
add_wave $CvSI/axi_awready -into Internal_CvSI
add_wave $CvSI/axi_wready -into Internal_CvSI
add_wave $CvSI/axi_bresp -into Internal_CvSI
add_wave $CvSI/axi_bvalid -into Internal_CvSI
add_wave $CvSI/axi_araddr -into Internal_CvSI
add_wave $CvSI/axi_arready -into Internal_CvSI
add_wave $CvSI/axi_rdata -into Internal_CvSI
add_wave $CvSI/axi_rresp -into Internal_CvSI
add_wave $CvSI/axi_rvalid -into Internal_CvSI

# Input vS Interface
set IvSI $nf_datapath/IvSI
add_wave_divider {Input vS Interface} -color darkgray
add_wave_virtual_bus clock_IvSI
add_wave $sig_clock -name clock -into clock_IvSI
add_wave $sig_resetn -name reset_n -into clock_IvSI
add_wave_group m_axis_0_IvSI
add_wave $IvSI/m_axis_0_tdata -into m_axis_0_IvSI -color gold
add_wave $IvSI/m_axis_0_tkeep -into m_axis_0_IvSI -color gold
add_wave $IvSI/m_axis_0_tuser -into m_axis_0_IvSI -color gold
add_wave $IvSI/m_axis_0_tvalid -into m_axis_0_IvSI -color gold
add_wave $IvSI/m_axis_0_tready -into m_axis_0_IvSI -color gold
add_wave $IvSI/m_axis_0_tlast -into m_axis_0_IvSI -color gold
add_wave_group m_axis_1_IvSI
add_wave $IvSI/m_axis_1_tdata -into m_axis_1_IvSI -color orange
add_wave $IvSI/m_axis_1_tkeep -into m_axis_1_IvSI -color orange
add_wave $IvSI/m_axis_1_tuser -into m_axis_1_IvSI -color orange
add_wave $IvSI/m_axis_1_tvalid -into m_axis_1_IvSI -color orange
add_wave $IvSI/m_axis_1_tready -into m_axis_1_IvSI -color orange
add_wave $IvSI/m_axis_1_tlast -into m_axis_1_IvSI -color orange
add_wave_group m_axis_2_IvSI
add_wave $IvSI/m_axis_2_tdata -into m_axis_2_IvSI -color maroon
add_wave $IvSI/m_axis_2_tkeep -into m_axis_2_IvSI -color maroon
add_wave $IvSI/m_axis_2_tuser -into m_axis_2_IvSI -color maroon
add_wave $IvSI/m_axis_2_tvalid -into m_axis_2_IvSI -color maroon
add_wave $IvSI/m_axis_2_tready -into m_axis_2_IvSI -color maroon
add_wave $IvSI/m_axis_2_tlast -into m_axis_2_IvSI -color maroon
add_wave_group m_axis_3_IvSI
add_wave $IvSI/m_axis_3_tdata -into m_axis_3_IvSI -color khaki
add_wave $IvSI/m_axis_3_tkeep -into m_axis_3_IvSI -color khaki
add_wave $IvSI/m_axis_3_tuser -into m_axis_3_IvSI -color khaki
add_wave $IvSI/m_axis_3_tvalid -into m_axis_3_IvSI -color khaki
add_wave $IvSI/m_axis_3_tready -into m_axis_3_IvSI -color khaki
add_wave $IvSI/m_axis_3_tlast -into m_axis_3_IvSI -color khaki
add_wave_group m_axis_4_IvSI
add_wave $IvSI/m_axis_4_tdata -into m_axis_4_IvSI -color gold
add_wave $IvSI/m_axis_4_tkeep -into m_axis_4_IvSI -color gold
add_wave $IvSI/m_axis_4_tuser -into m_axis_4_IvSI -color gold
add_wave $IvSI/m_axis_4_tvalid -into m_axis_4_IvSI -color gold
add_wave $IvSI/m_axis_4_tready -into m_axis_4_IvSI -color gold
add_wave $IvSI/m_axis_4_tlast -into m_axis_4_IvSI -color gold
add_wave_group m_axis_5_IvSI
add_wave $IvSI/m_axis_5_tdata -into m_axis_5_IvSI -color orange
add_wave $IvSI/m_axis_5_tkeep -into m_axis_5_IvSI -color orange
add_wave $IvSI/m_axis_5_tuser -into m_axis_5_IvSI -color orange
add_wave $IvSI/m_axis_5_tvalid -into m_axis_5_IvSI -color orange
add_wave $IvSI/m_axis_5_tready -into m_axis_5_IvSI -color orange
add_wave $IvSI/m_axis_5_tlast -into m_axis_5_IvSI -color orange
add_wave_group m_axis_6_IvSI
add_wave $IvSI/m_axis_6_tdata -into m_axis_6_IvSI -color maroon
add_wave $IvSI/m_axis_6_tkeep -into m_axis_6_IvSI -color maroon
add_wave $IvSI/m_axis_6_tuser -into m_axis_6_IvSI -color maroon
add_wave $IvSI/m_axis_6_tvalid -into m_axis_6_IvSI -color maroon
add_wave $IvSI/m_axis_6_tready -into m_axis_6_IvSI -color maroon
add_wave $IvSI/m_axis_6_tlast -into m_axis_6_IvSI -color maroon
add_wave_group m_axis_7_IvSI
add_wave $IvSI/m_axis_7_tdata -into m_axis_7_IvSI -color khaki
add_wave $IvSI/m_axis_7_tkeep -into m_axis_7_IvSI -color khaki
add_wave $IvSI/m_axis_7_tuser -into m_axis_7_IvSI -color khaki
add_wave $IvSI/m_axis_7_tvalid -into m_axis_7_IvSI -color khaki
add_wave $IvSI/m_axis_7_tready -into m_axis_7_IvSI -color khaki
add_wave $IvSI/m_axis_7_tlast -into m_axis_7_IvSI -color khaki
add_wave_group s_axis_0_IvSI
add_wave $IvSI/s_axis_0_tdata -into s_axis_0_IvSI -color gold
add_wave $IvSI/s_axis_0_tkeep -into s_axis_0_IvSI -color gold
add_wave $IvSI/s_axis_0_tuser -into s_axis_0_IvSI -color gold
add_wave $IvSI/s_axis_0_tvalid -into s_axis_0_IvSI -color gold
add_wave $IvSI/s_axis_0_tready -into s_axis_0_IvSI -color gold
add_wave $IvSI/s_axis_0_tlast -into s_axis_0_IvSI -color gold
add_wave_group s_axis_1_IvSI
add_wave $IvSI/s_axis_1_tdata -into s_axis_1_IvSI -color orange
add_wave $IvSI/s_axis_1_tkeep -into s_axis_1_IvSI -color orange
add_wave $IvSI/s_axis_1_tuser -into s_axis_1_IvSI -color orange
add_wave $IvSI/s_axis_1_tvalid -into s_axis_1_IvSI -color orange
add_wave $IvSI/s_axis_1_tready -into s_axis_1_IvSI -color orange
add_wave $IvSI/s_axis_1_tlast -into s_axis_1_IvSI -color orange
add_wave_group s_axis_2_IvSI
add_wave $IvSI/s_axis_2_tdata -into s_axis_2_IvSI -color maroon
add_wave $IvSI/s_axis_2_tkeep -into s_axis_2_IvSI -color maroon
add_wave $IvSI/s_axis_2_tuser -into s_axis_2_IvSI -color maroon
add_wave $IvSI/s_axis_2_tvalid -into s_axis_2_IvSI -color maroon
add_wave $IvSI/s_axis_2_tready -into s_axis_2_IvSI -color maroon
add_wave $IvSI/s_axis_2_tlast -into s_axis_2_IvSI -color maroon
add_wave_group s_axis_3_IvSI
add_wave $IvSI/s_axis_3_tdata -into s_axis_3_IvSI -color khaki
add_wave $IvSI/s_axis_3_tkeep -into s_axis_3_IvSI -color khaki
add_wave $IvSI/s_axis_3_tuser -into s_axis_3_IvSI -color khaki
add_wave $IvSI/s_axis_3_tvalid -into s_axis_3_IvSI -color khaki
add_wave $IvSI/s_axis_3_tready -into s_axis_3_IvSI -color khaki
add_wave $IvSI/s_axis_3_tlast -into s_axis_3_IvSI -color khaki
add_wave_group s_axis_4_IvSI
add_wave $IvSI/s_axis_4_tdata -into s_axis_4_IvSI -color pink
add_wave $IvSI/s_axis_4_tkeep -into s_axis_4_IvSI -color pink
add_wave $IvSI/s_axis_4_tuser -into s_axis_4_IvSI -color pink
add_wave $IvSI/s_axis_4_tvalid -into s_axis_4_IvSI -color pink
add_wave $IvSI/s_axis_4_tready -into s_axis_4_IvSI -color pink
add_wave $IvSI/s_axis_4_tlast -into s_axis_4_IvSI -color pink
add_wave_group VLAN_parser_IvSI
add_wave $IvSI/vlan_tdata -into VLAN_parser_IvSI
add_wave $IvSI/vlan_prot_id -into VLAN_parser_IvSI
add_wave $IvSI/vlan_info -into VLAN_parser_IvSI
add_wave $IvSI/vlan_info_prio -into VLAN_parser_IvSI
add_wave $IvSI/vlan_info_drop -into VLAN_parser_IvSI
add_wave $IvSI/vlan_info_id -into VLAN_parser_IvSI
add_wave_group Internal_IvSI
add_wave $IvSI/ipi_state -into Internal_IvSI
add_wave $IvSI/ipi_vlan_prot_id -into Internal_IvSI
add_wave $IvSI/ipi_vlan_info_id -into Internal_IvSI
add_wave_group RX_Queues_IvSI
add_wave $IvSI/axis_tdata -into RX_Queues_IvSI -color teal
add_wave $IvSI/axis_tkeep -into RX_Queues_IvSI -color teal
add_wave $IvSI/axis_tuser -into RX_Queues_IvSI -color teal
add_wave $IvSI/axis_tvalid -into RX_Queues_IvSI -color teal
add_wave $IvSI/axis_tready -into RX_Queues_IvSI -color teal
add_wave $IvSI/axis_tlast -into RX_Queues_IvSI -color teal
add_wave $IvSI/pkt_fwd -into RX_Queues_IvSI

# Output P4 Interface
set OvSI $nf_datapath/OvSI
add_wave_divider {Output vS Interface} -color darkgray
add_wave_virtual_bus clock_OvSI
add_wave $sig_clock -name clock -into clock_OvSI
add_wave $sig_resetn -name reset_n -into clock_OvSI
add_wave_group m_axis_0_OvSI
add_wave $OvSI/m_axis_0_tdata -into m_axis_0_OvSI -color gold
add_wave $OvSI/m_axis_0_tkeep -into m_axis_0_OvSI -color gold
add_wave $OvSI/m_axis_0_tuser -into m_axis_0_OvSI -color gold
add_wave $OvSI/m_axis_0_tvalid -into m_axis_0_OvSI -color gold
add_wave $OvSI/m_axis_0_tready -into m_axis_0_OvSI -color gold
add_wave $OvSI/m_axis_0_tlast -into m_axis_0_OvSI -color gold
add_wave_group m_axis_1_OvSI
add_wave $OvSI/m_axis_1_tdata -into m_axis_1_OvSI -color orange
add_wave $OvSI/m_axis_1_tkeep -into m_axis_1_OvSI -color orange
add_wave $OvSI/m_axis_1_tuser -into m_axis_1_OvSI -color orange
add_wave $OvSI/m_axis_1_tvalid -into m_axis_1_OvSI -color orange
add_wave $OvSI/m_axis_1_tready -into m_axis_1_OvSI -color orange
add_wave $OvSI/m_axis_1_tlast -into m_axis_1_OvSI -color orange
add_wave_group m_axis_2_OvSI
add_wave $OvSI/m_axis_2_tdata -into m_axis_2_OvSI -color maroon
add_wave $OvSI/m_axis_2_tkeep -into m_axis_2_OvSI -color maroon
add_wave $OvSI/m_axis_2_tuser -into m_axis_2_OvSI -color maroon
add_wave $OvSI/m_axis_2_tvalid -into m_axis_2_OvSI -color maroon
add_wave $OvSI/m_axis_2_tready -into m_axis_2_OvSI -color maroon
add_wave $OvSI/m_axis_2_tlast -into m_axis_2_OvSI -color maroon
add_wave_group m_axis_3_OvSI
add_wave $OvSI/m_axis_3_tdata -into m_axis_3_OvSI -color khaki
add_wave $OvSI/m_axis_3_tkeep -into m_axis_3_OvSI -color khaki
add_wave $OvSI/m_axis_3_tuser -into m_axis_3_OvSI -color khaki
add_wave $OvSI/m_axis_3_tvalid -into m_axis_3_OvSI -color khaki
add_wave $OvSI/m_axis_3_tready -into m_axis_3_OvSI -color khaki
add_wave $OvSI/m_axis_3_tlast -into m_axis_3_OvSI -color khaki
add_wave_group m_axis_4_OvSI
add_wave $OvSI/m_axis_4_tdata -into m_axis_4_OvSI -color pink
add_wave $OvSI/m_axis_4_tkeep -into m_axis_4_OvSI -color pink
add_wave $OvSI/m_axis_4_tuser -into m_axis_4_OvSI -color pink
add_wave $OvSI/m_axis_4_tvalid -into m_axis_4_OvSI -color pink
add_wave $OvSI/m_axis_4_tready -into m_axis_4_OvSI -color pink
add_wave $OvSI/m_axis_4_tlast -into m_axis_4_OvSI -color pink
add_wave_group s_axis_0_OvSI
add_wave $OvSI/s_axis_0_tdata -into s_axis_0_OvSI -color gold
add_wave $OvSI/s_axis_0_tkeep -into s_axis_0_OvSI -color gold
add_wave $OvSI/s_axis_0_tuser -into s_axis_0_OvSI -color gold
add_wave $OvSI/s_axis_0_tvalid -into s_axis_0_OvSI -color gold
add_wave $OvSI/s_axis_0_tready -into s_axis_0_OvSI -color gold
add_wave $OvSI/s_axis_0_tlast -into s_axis_0_OvSI -color gold
add_wave_group s_axis_1_OvSI
add_wave $OvSI/s_axis_1_tdata -into s_axis_1_OvSI -color orange
add_wave $OvSI/s_axis_1_tkeep -into s_axis_1_OvSI -color orange
add_wave $OvSI/s_axis_1_tuser -into s_axis_1_OvSI -color orange
add_wave $OvSI/s_axis_1_tvalid -into s_axis_1_OvSI -color orange
add_wave $OvSI/s_axis_1_tready -into s_axis_1_OvSI -color orange
add_wave $OvSI/s_axis_1_tlast -into s_axis_1_OvSI -color orange
add_wave_group s_axis_2_OvSI
add_wave $OvSI/s_axis_2_tdata -into s_axis_2_OvSI -color maroon
add_wave $OvSI/s_axis_2_tkeep -into s_axis_2_OvSI -color maroon
add_wave $OvSI/s_axis_2_tuser -into s_axis_2_OvSI -color maroon
add_wave $OvSI/s_axis_2_tvalid -into s_axis_2_OvSI -color maroon
add_wave $OvSI/s_axis_2_tready -into s_axis_2_OvSI -color maroon
add_wave $OvSI/s_axis_2_tlast -into s_axis_2_OvSI -color maroon
add_wave_group s_axis_3_OvSI
add_wave $OvSI/s_axis_3_tdata -into s_axis_3_OvSI -color khaki
add_wave $OvSI/s_axis_3_tkeep -into s_axis_3_OvSI -color khaki
add_wave $OvSI/s_axis_3_tuser -into s_axis_3_OvSI -color khaki
add_wave $OvSI/s_axis_3_tvalid -into s_axis_3_OvSI -color khaki
add_wave $OvSI/s_axis_3_tready -into s_axis_3_OvSI -color khaki
add_wave $OvSI/s_axis_3_tlast -into s_axis_3_OvSI -color khaki
add_wave_group s_axis_4_OvSI
add_wave $OvSI/s_axis_4_tdata -into s_axis_4_OvSI -color pink
add_wave $OvSI/s_axis_4_tkeep -into s_axis_4_OvSI -color pink
add_wave $OvSI/s_axis_4_tuser -into s_axis_4_OvSI -color pink
add_wave $OvSI/s_axis_4_tvalid -into s_axis_4_OvSI -color pink
add_wave $OvSI/s_axis_4_tready -into s_axis_4_OvSI -color pink
add_wave $OvSI/s_axis_4_tlast -into s_axis_4_OvSI -color pink
add_wave_group s_axis_5_OvSI
add_wave $OvSI/s_axis_5_tdata -into s_axis_5_OvSI -color gold
add_wave $OvSI/s_axis_5_tkeep -into s_axis_5_OvSI -color gold
add_wave $OvSI/s_axis_5_tuser -into s_axis_5_OvSI -color gold
add_wave $OvSI/s_axis_5_tvalid -into s_axis_5_OvSI -color gold
add_wave $OvSI/s_axis_5_tready -into s_axis_5_OvSI -color gold
add_wave $OvSI/s_axis_5_tlast -into s_axis_5_OvSI -color gold
add_wave_group s_axis_6_OvSI
add_wave $OvSI/s_axis_6_tdata -into s_axis_6_OvSI -color orange
add_wave $OvSI/s_axis_6_tkeep -into s_axis_6_OvSI -color orange
add_wave $OvSI/s_axis_6_tuser -into s_axis_6_OvSI -color orange
add_wave $OvSI/s_axis_6_tvalid -into s_axis_6_OvSI -color orange
add_wave $OvSI/s_axis_6_tready -into s_axis_6_OvSI -color orange
add_wave $OvSI/s_axis_6_tlast -into s_axis_6_OvSI -color orange
add_wave_group s_axis_7_OvSI
add_wave $OvSI/s_axis_7_tdata -into s_axis_7_OvSI -color maroon
add_wave $OvSI/s_axis_7_tkeep -into s_axis_7_OvSI -color maroon
add_wave $OvSI/s_axis_7_tuser -into s_axis_7_OvSI -color maroon
add_wave $OvSI/s_axis_7_tvalid -into s_axis_7_OvSI -color maroon
add_wave $OvSI/s_axis_7_tready -into s_axis_7_OvSI -color maroon
add_wave $OvSI/s_axis_7_tlast -into s_axis_7_OvSI -color maroon
add_wave_group TX_Queues_OvSI
add_wave $OvSI/axis_tdata -into TX_Queues_OvSI -color teal
add_wave $OvSI/axis_tkeep -into TX_Queues_OvSI -color teal
add_wave $OvSI/axis_tuser -into TX_Queues_OvSI -color teal
add_wave $OvSI/axis_tvalid -into TX_Queues_OvSI -color teal
add_wave $OvSI/axis_tready -into TX_Queues_OvSI -color teal
add_wave $OvSI/axis_tlast -into TX_Queues_OvSI -color teal
add_wave $OvSI/nf0_q_size -into TX_Queues_OvSI
add_wave $OvSI/nf1_q_size -into TX_Queues_OvSI
add_wave $OvSI/nf2_q_size -into TX_Queues_OvSI
add_wave $OvSI/nf3_q_size -into TX_Queues_OvSI
add_wave $OvSI/bytes_stored -into TX_Queues_OvSI
add_wave $OvSI/bytes_removed_0 -into TX_Queues_OvSI
add_wave $OvSI/bytes_removed_1 -into TX_Queues_OvSI
add_wave $OvSI/bytes_removed_2 -into TX_Queues_OvSI
add_wave $OvSI/bytes_removed_3 -into TX_Queues_OvSI
add_wave $OvSI/bytes_removed_4 -into TX_Queues_OvSI
add_wave $OvSI/pkt_removed_0 -into TX_Queues_OvSI
add_wave $OvSI/pkt_removed_1 -into TX_Queues_OvSI
add_wave $OvSI/pkt_removed_2 -into TX_Queues_OvSI
add_wave $OvSI/pkt_removed_3 -into TX_Queues_OvSI
add_wave $OvSI/pkt_removed_4 -into TX_Queues_OvSI
add_wave $OvSI/bytes_dropped -into TX_Queues_OvSI
add_wave $OvSI/pkt_dropped -into TX_Queues_OvSI
add_wave_group Internal_OvSI
add_wave $OvSI/nearly_full -into Internal_OvSI
add_wave $OvSI/empty -into Internal_OvSI
add_wave $OvSI/in_tdata -into Internal_OvSI
add_wave $OvSI/in_tkeep -into Internal_OvSI
add_wave $OvSI/in_tuser -into Internal_OvSI
add_wave $OvSI/in_tvalid -into Internal_OvSI
add_wave $OvSI/in_tlast -into Internal_OvSI
add_wave $OvSI/fifo_out_tuser -into Internal_OvSI
add_wave $OvSI/fifo_out_tdata -into Internal_OvSI
add_wave $OvSI/fifo_out_tkeep -into Internal_OvSI
add_wave $OvSI/fifo_out_tlast -into Internal_OvSI
add_wave $OvSI/fifo_tvalid -into Internal_OvSI
add_wave $OvSI/fifo_tlast -into Internal_OvSI
add_wave $OvSI/rd_en -into Internal_OvSI
add_wave $OvSI/cur_queue_plus1 -into Internal_OvSI
add_wave $OvSI/cur_queue -into Internal_OvSI
add_wave $OvSI/cur_queue_next -into Internal_OvSI
add_wave $OvSI/in_arb_cur_queue -into Internal_OvSI
add_wave $OvSI/state -into Internal_OvSI
add_wave $OvSI/state_next -into Internal_OvSI
add_wave $OvSI/in_arb_state -into Internal_OvSI

# Virtual Switch 0
set vSwitch0_ip /top_tb/top_sim/nf_datapath_0/sdnet_vSwitch0/inst/vSwitch0_inst/
set vSwitch0_wrapper /top_tb/top_sim/nf_datapath_0/sdnet_vSwitch0/inst/
add_wave_divider {SDNet - Virtual Switch 0} -color chocolate
add_wave_virtual_bus clock_VS_0
add_wave $vSwitch0_ip/clk_lookup_rst -into clock_VS_0
add_wave $vSwitch0_ip/clk_lookup -into clock_VS_0
add_wave_virtual_bus Output_VS_0 -color blue
add_wave $vSwitch0_wrapper/m_axis_tdata -into Output_VS_0 -color blue
add_wave $vSwitch0_wrapper/m_axis_tkeep -into Output_VS_0 -color blue
add_wave $vSwitch0_wrapper/m_axis_tvalid -into Output_VS_0 -color blue
add_wave $vSwitch0_wrapper/m_axis_tready -into Output_VS_0
add_wave $vSwitch0_wrapper/m_axis_tlast -into Output_VS_0 -color blue
add_wave_virtual_bus Input_VS_0 -color purple
add_wave $vSwitch0_wrapper/s_axis_tdata -into Input_VS_0 -color purple
add_wave $vSwitch0_wrapper/s_axis_tkeep -into Input_VS_0 -color purple
add_wave $vSwitch0_wrapper/s_axis_tvalid -into Input_VS_0 -color purple
add_wave $vSwitch0_wrapper/s_axis_tready -into Input_VS_0
add_wave $vSwitch0_wrapper/s_axis_tlast -into Input_VS_0 -color purple
add_wave_virtual_bus Tuple-out_VS_0 -color aqua
add_wave $vSwitch0_wrapper/sume_tuple_out_VALID -into Tuple-out_VS_0 -color white
add_wave $vSwitch0_wrapper/m_axis_tuser -into Tuple-out_VS_0 -color aqua
add_wave $vSwitch0_wrapper/out_pkt_len -into Tuple-out_VS_0 -color aqua -radix unsigned
add_wave $vSwitch0_wrapper/out_src_port -into Tuple-out_VS_0 -color aqua -radix bin
add_wave $vSwitch0_wrapper/out_dst_port -into Tuple-out_VS_0 -color aqua -radix bin
add_wave_virtual_bus Tuple-In_VS_0 -color magenta
add_wave $vSwitch0_wrapper/sume_tuple_in_VALID -into Tuple-In_VS_0 -color white
add_wave $vSwitch0_wrapper/s_axis_tuser -into Tuple-In_VS_0 -color magenta
add_wave $vSwitch0_wrapper/in_pkt_len -into Tuple-In_VS_0 -color magenta -radix unsigned
add_wave $vSwitch0_wrapper/in_src_port -into Tuple-In_VS_0 -color magenta -radix bin
add_wave $vSwitch0_wrapper/in_dst_port -into Tuple-In_VS_0 -color magenta -radix bin
add_wave_virtual_bus Control_VS_0 -color yellow
add_wave $vSwitch0_ip/internal_rst_done -into Control_VS_0 -color white
add_wave $vSwitch0_ip/control_S_AXI_AWADDR -into Control_VS_0  -color yellow
add_wave $vSwitch0_ip/control_S_AXI_AWVALID -into Control_VS_0 -color yellow
add_wave $vSwitch0_ip/control_S_AXI_AWREADY -into Control_VS_0
add_wave $vSwitch0_ip/control_S_AXI_WDATA -into Control_VS_0 -color yellow
add_wave $vSwitch0_ip/control_S_AXI_WSTRB -into Control_VS_0 -color yellow
add_wave $vSwitch0_ip/control_S_AXI_WVALID -into Control_VS_0 -color yellow
add_wave $vSwitch0_ip/control_S_AXI_WREADY -into Control_VS_0
add_wave $vSwitch0_ip/control_S_AXI_BRESP -into Control_VS_0
add_wave $vSwitch0_ip/control_S_AXI_BVALID -into Control_VS_0
add_wave $vSwitch0_ip/control_S_AXI_BREADY -into Control_VS_0 -color yellow
add_wave $vSwitch0_ip/control_S_AXI_ARADDR -into Control_VS_0 -color yellow
add_wave $vSwitch0_ip/control_S_AXI_ARVALID -into Control_VS_0 -color yellow
add_wave $vSwitch0_ip/control_S_AXI_ARREADY -into Control_VS_0
add_wave $vSwitch0_ip/control_S_AXI_RDATA -into Control_VS_0
add_wave $vSwitch0_ip/control_S_AXI_RRESP -into Control_VS_0
add_wave $vSwitch0_ip/control_S_AXI_RVALID -into Control_VS_0
add_wave $vSwitch0_ip/control_S_AXI_RREADY -into Control_VS_0 -color yellow

# Virtual Switch 1
set vSwitch1_ip /top_tb/top_sim/nf_datapath_0/sdnet_vSwitch1/inst/vSwitch1_inst/
set vSwitch1_wrapper /top_tb/top_sim/nf_datapath_0/sdnet_vSwitch1/inst/
add_wave_divider {SDNet - Virtual Switch 1} -color chocolate
add_wave_virtual_bus clock_VS_1
add_wave $vSwitch1_ip/clk_lookup_rst -into clock_VS_1
add_wave $vSwitch1_ip/clk_lookup -into clock_VS_1
add_wave_virtual_bus Output_VS_1 -color blue
add_wave $vSwitch1_wrapper/m_axis_tdata -into Output_VS_1 -color blue
add_wave $vSwitch1_wrapper/m_axis_tkeep -into Output_VS_1 -color blue
add_wave $vSwitch1_wrapper/m_axis_tvalid -into Output_VS_1 -color blue
add_wave $vSwitch1_wrapper/m_axis_tready -into Output_VS_1
add_wave $vSwitch1_wrapper/m_axis_tlast -into Output_VS_1 -color blue
add_wave_virtual_bus Input_VS_1 -color purple
add_wave $vSwitch1_wrapper/s_axis_tdata -into Input_VS_1 -color purple
add_wave $vSwitch1_wrapper/s_axis_tkeep -into Input_VS_1 -color purple
add_wave $vSwitch1_wrapper/s_axis_tvalid -into Input_VS_1 -color purple
add_wave $vSwitch1_wrapper/s_axis_tready -into Input_VS_1
add_wave $vSwitch1_wrapper/s_axis_tlast -into Input_VS_1 -color purple
add_wave_virtual_bus Tuple-out_VS_1 -color aqua
add_wave $vSwitch1_wrapper/sume_tuple_out_VALID -into Tuple-out_VS_1 -color white
add_wave $vSwitch1_wrapper/m_axis_tuser -into Tuple-out_VS_1 -color aqua
add_wave $vSwitch1_wrapper/out_pkt_len -into Tuple-out_VS_1 -color aqua -radix unsigned
add_wave $vSwitch1_wrapper/out_src_port -into Tuple-out_VS_1 -color aqua -radix bin
add_wave $vSwitch1_wrapper/out_dst_port -into Tuple-out_VS_1 -color aqua -radix bin
add_wave_virtual_bus Tuple-In_VS_1 -color magenta
add_wave $vSwitch1_wrapper/sume_tuple_in_VALID -into Tuple-In_VS_1 -color white
add_wave $vSwitch1_wrapper/s_axis_tuser -into Tuple-In_VS_1 -color magenta
add_wave $vSwitch1_wrapper/in_pkt_len -into Tuple-In_VS_1 -color magenta -radix unsigned
add_wave $vSwitch1_wrapper/in_src_port -into Tuple-In_VS_1 -color magenta -radix bin
add_wave $vSwitch1_wrapper/in_dst_port -into Tuple-In_VS_1 -color magenta -radix bin
add_wave_virtual_bus Control_VS_1 -color yellow
add_wave $vSwitch1_ip/internal_rst_done -into Control_VS_1 -color white
add_wave $vSwitch1_ip/control_S_AXI_AWADDR -into Control_VS_1  -color yellow
add_wave $vSwitch1_ip/control_S_AXI_AWVALID -into Control_VS_1 -color yellow
add_wave $vSwitch1_ip/control_S_AXI_AWREADY -into Control_VS_1
add_wave $vSwitch1_ip/control_S_AXI_WDATA -into Control_VS_1 -color yellow
add_wave $vSwitch1_ip/control_S_AXI_WSTRB -into Control_VS_1 -color yellow
add_wave $vSwitch1_ip/control_S_AXI_WVALID -into Control_VS_1 -color yellow
add_wave $vSwitch1_ip/control_S_AXI_WREADY -into Control_VS_1
add_wave $vSwitch1_ip/control_S_AXI_BRESP -into Control_VS_1
add_wave $vSwitch1_ip/control_S_AXI_BVALID -into Control_VS_1
add_wave $vSwitch1_ip/control_S_AXI_BREADY -into Control_VS_1 -color yellow
add_wave $vSwitch1_ip/control_S_AXI_ARADDR -into Control_VS_1 -color yellow
add_wave $vSwitch1_ip/control_S_AXI_ARVALID -into Control_VS_1 -color yellow
add_wave $vSwitch1_ip/control_S_AXI_ARREADY -into Control_VS_1
add_wave $vSwitch1_ip/control_S_AXI_RDATA -into Control_VS_1
add_wave $vSwitch1_ip/control_S_AXI_RRESP -into Control_VS_1
add_wave $vSwitch1_ip/control_S_AXI_RVALID -into Control_VS_1
add_wave $vSwitch1_ip/control_S_AXI_RREADY -into Control_VS_1 -color yellow

# # Virtual Switch 2
# set vSwitch2_ip /top_tb/top_sim/nf_datapath_0/sdnet_vSwitch2/inst/vSwitch2_inst/
# set vSwitch2_wrapper /top_tb/top_sim/nf_datapath_0/sdnet_vSwitch2/inst/
# add_wave_divider {SDNet - Virtual Switch 2} -color chocolate
# add_wave_virtual_bus clock_VS_2
# add_wave $vSwitch2_ip/clk_lookup_rst -into clock_VS_2
# add_wave $vSwitch2_ip/clk_lookup -into clock_VS_2
# add_wave_virtual_bus Output_VS_2 -color blue
# add_wave $vSwitch2_wrapper/m_axis_tdata -into Output_VS_2 -color blue
# add_wave $vSwitch2_wrapper/m_axis_tkeep -into Output_VS_2 -color blue
# add_wave $vSwitch2_wrapper/m_axis_tvalid -into Output_VS_2 -color blue
# add_wave $vSwitch2_wrapper/m_axis_tready -into Output_VS_2
# add_wave $vSwitch2_wrapper/m_axis_tlast -into Output_VS_2 -color blue
# add_wave_virtual_bus Input_VS_2 -color purple
# add_wave $vSwitch2_wrapper/s_axis_tdata -into Input_VS_2 -color purple
# add_wave $vSwitch2_wrapper/s_axis_tkeep -into Input_VS_2 -color purple
# add_wave $vSwitch2_wrapper/s_axis_tvalid -into Input_VS_2 -color purple
# add_wave $vSwitch2_wrapper/s_axis_tready -into Input_VS_2
# add_wave $vSwitch2_wrapper/s_axis_tlast -into Input_VS_2 -color purple
# add_wave_virtual_bus Tuple-out_VS_2 -color aqua
# add_wave $vSwitch2_wrapper/sume_tuple_out_VALID -into Tuple-out_VS_2 -color white
# add_wave $vSwitch2_wrapper/m_axis_tuser -into Tuple-out_VS_2 -color aqua
# add_wave $vSwitch2_wrapper/out_pkt_len -into Tuple-out_VS_2 -color aqua -radix unsigned
# add_wave $vSwitch2_wrapper/out_src_port -into Tuple-out_VS_2 -color aqua -radix bin
# add_wave $vSwitch2_wrapper/out_dst_port -into Tuple-out_VS_2 -color aqua -radix bin
# add_wave_virtual_bus Tuple-In_VS_2 -color magenta
# add_wave $vSwitch2_wrapper/sume_tuple_in_VALID -into Tuple-In_VS_2 -color white
# add_wave $vSwitch2_wrapper/s_axis_tuser -into Tuple-In_VS_2 -color magenta
# add_wave $vSwitch2_wrapper/in_pkt_len -into Tuple-In_VS_2 -color magenta -radix unsigned
# add_wave $vSwitch2_wrapper/in_src_port -into Tuple-In_VS_2 -color magenta -radix bin
# add_wave $vSwitch2_wrapper/in_dst_port -into Tuple-In_VS_2 -color magenta -radix bin
# add_wave_virtual_bus Control_VS_2 -color yellow
# add_wave $vSwitch2_ip/internal_rst_done -into Control_VS_2 -color white
# add_wave $vSwitch2_ip/control_S_AXI_AWADDR -into Control_VS_2  -color yellow
# add_wave $vSwitch2_ip/control_S_AXI_AWVALID -into Control_VS_2 -color yellow
# add_wave $vSwitch2_ip/control_S_AXI_AWREADY -into Control_VS_2
# add_wave $vSwitch2_ip/control_S_AXI_WDATA -into Control_VS_2 -color yellow
# add_wave $vSwitch2_ip/control_S_AXI_WSTRB -into Control_VS_2 -color yellow
# add_wave $vSwitch2_ip/control_S_AXI_WVALID -into Control_VS_2 -color yellow
# add_wave $vSwitch2_ip/control_S_AXI_WREADY -into Control_VS_2
# add_wave $vSwitch2_ip/control_S_AXI_BRESP -into Control_VS_2
# add_wave $vSwitch2_ip/control_S_AXI_BVALID -into Control_VS_2
# add_wave $vSwitch2_ip/control_S_AXI_BREADY -into Control_VS_2 -color yellow
# add_wave $vSwitch2_ip/control_S_AXI_ARADDR -into Control_VS_2 -color yellow
# add_wave $vSwitch2_ip/control_S_AXI_ARVALID -into Control_VS_2 -color yellow
# add_wave $vSwitch2_ip/control_S_AXI_ARREADY -into Control_VS_2
# add_wave $vSwitch2_ip/control_S_AXI_RDATA -into Control_VS_2
# add_wave $vSwitch2_ip/control_S_AXI_RRESP -into Control_VS_2
# add_wave $vSwitch2_ip/control_S_AXI_RVALID -into Control_VS_2
# add_wave $vSwitch2_ip/control_S_AXI_RREADY -into Control_VS_2 -color yellow
#
# # Virtual Switch 3
# set vSwitch3_ip /top_tb/top_sim/nf_datapath_0/sdnet_vSwitch3/inst/vSwitch3_inst/
# set vSwitch3_wrapper /top_tb/top_sim/nf_datapath_0/sdnet_vSwitch3/inst/
# add_wave_divider {SDNet - Virtual Switch 3} -color chocolate
# add_wave_virtual_bus clock_VS_3
# add_wave $vSwitch3_ip/clk_lookup_rst -into clock_VS_3
# add_wave $vSwitch3_ip/clk_lookup -into clock_VS_3
# add_wave_virtual_bus Output_VS_3 -color blue
# add_wave $vSwitch3_wrapper/m_axis_tdata -into Output_VS_3 -color blue
# add_wave $vSwitch3_wrapper/m_axis_tkeep -into Output_VS_3 -color blue
# add_wave $vSwitch3_wrapper/m_axis_tvalid -into Output_VS_3 -color blue
# add_wave $vSwitch3_wrapper/m_axis_tready -into Output_VS_3
# add_wave $vSwitch3_wrapper/m_axis_tlast -into Output_VS_3 -color blue
# add_wave_virtual_bus Input_VS_3 -color purple
# add_wave $vSwitch3_wrapper/s_axis_tdata -into Input_VS_3 -color purple
# add_wave $vSwitch3_wrapper/s_axis_tkeep -into Input_VS_3 -color purple
# add_wave $vSwitch3_wrapper/s_axis_tvalid -into Input_VS_3 -color purple
# add_wave $vSwitch3_wrapper/s_axis_tready -into Input_VS_3
# add_wave $vSwitch3_wrapper/s_axis_tlast -into Input_VS_3 -color purple
# add_wave_virtual_bus Tuple-out_VS_3 -color aqua
# add_wave $vSwitch3_wrapper/sume_tuple_out_VALID -into Tuple-out_VS_3 -color white
# add_wave $vSwitch3_wrapper/m_axis_tuser -into Tuple-out_VS_3 -color aqua
# add_wave $vSwitch3_wrapper/out_pkt_len -into Tuple-out_VS_3 -color aqua -radix unsigned
# add_wave $vSwitch3_wrapper/out_src_port -into Tuple-out_VS_3 -color aqua -radix bin
# add_wave $vSwitch3_wrapper/out_dst_port -into Tuple-out_VS_3 -color aqua -radix bin
# add_wave_virtual_bus Tuple-In_VS_3 -color magenta
# add_wave $vSwitch3_wrapper/sume_tuple_in_VALID -into Tuple-In_VS_3 -color white
# add_wave $vSwitch3_wrapper/s_axis_tuser -into Tuple-In_VS_3 -color magenta
# add_wave $vSwitch3_wrapper/in_pkt_len -into Tuple-In_VS_3 -color magenta -radix unsigned
# add_wave $vSwitch3_wrapper/in_src_port -into Tuple-In_VS_3 -color magenta -radix bin
# add_wave $vSwitch3_wrapper/in_dst_port -into Tuple-In_VS_3 -color magenta -radix bin
# add_wave_virtual_bus Control_VS_3 -color yellow
# add_wave $vSwitch3_ip/internal_rst_done -into Control_VS_3 -color white
# add_wave $vSwitch3_ip/control_S_AXI_AWADDR -into Control_VS_3  -color yellow
# add_wave $vSwitch3_ip/control_S_AXI_AWVALID -into Control_VS_3 -color yellow
# add_wave $vSwitch3_ip/control_S_AXI_AWREADY -into Control_VS_3
# add_wave $vSwitch3_ip/control_S_AXI_WDATA -into Control_VS_3 -color yellow
# add_wave $vSwitch3_ip/control_S_AXI_WSTRB -into Control_VS_3 -color yellow
# add_wave $vSwitch3_ip/control_S_AXI_WVALID -into Control_VS_3 -color yellow
# add_wave $vSwitch3_ip/control_S_AXI_WREADY -into Control_VS_3
# add_wave $vSwitch3_ip/control_S_AXI_BRESP -into Control_VS_3
# add_wave $vSwitch3_ip/control_S_AXI_BVALID -into Control_VS_3
# add_wave $vSwitch3_ip/control_S_AXI_BREADY -into Control_VS_3 -color yellow
# add_wave $vSwitch3_ip/control_S_AXI_ARADDR -into Control_VS_3 -color yellow
# add_wave $vSwitch3_ip/control_S_AXI_ARVALID -into Control_VS_3 -color yellow
# add_wave $vSwitch3_ip/control_S_AXI_ARREADY -into Control_VS_3
# add_wave $vSwitch3_ip/control_S_AXI_RDATA -into Control_VS_3
# add_wave $vSwitch3_ip/control_S_AXI_RRESP -into Control_VS_3
# add_wave $vSwitch3_ip/control_S_AXI_RVALID -into Control_VS_3
# add_wave $vSwitch3_ip/control_S_AXI_RREADY -into Control_VS_3 -color yellow



run 100us

set_property needs_save false [get_wave_configs P4-NetFPGA]
set_property needs_save false [get_wave_configs P4VBox]
