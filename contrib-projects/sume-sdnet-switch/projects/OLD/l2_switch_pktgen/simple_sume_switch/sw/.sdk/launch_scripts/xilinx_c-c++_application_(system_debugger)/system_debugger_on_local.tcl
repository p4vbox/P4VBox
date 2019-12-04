connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent NetFPGA-SUME 210301763027A" && level==0} -index 0
fpga -file /root/projects/P4-NetFPGA/contrib-projects/sume-sdnet-switch/projects/l2_switch_pktgen/simple_sume_switch/sw/embedded/SDK_Workspace/simple_sume_switch/hw_platform/top.bit
targets -set -nocase -filter {name =~ "microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent NetFPGA-SUME 210301763027A"} -index 0
loadhw /root/projects/P4-NetFPGA/contrib-projects/sume-sdnet-switch/projects/l2_switch_pktgen/simple_sume_switch/sw/embedded/SDK_Workspace/simple_sume_switch/hw_platform/system.hdf
targets -set -nocase -filter {name =~ "microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent NetFPGA-SUME 210301763027A"} -index 0
rst -system
after 3000
