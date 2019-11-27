#
# Makefile for clean folder
#

BIT_FOLDER=./bitstreams

all: clean

lib_cores:
	make -C ${SUME_FOLDER}/lib/hw/xilinx/cores/tcam_v1_1_0/ update
	make -C ${SUME_FOLDER}/lib/hw/xilinx/cores/tcam_v1_1_0/ all
	make -C ${SUME_FOLDER}/lib/hw/xilinx/cores/cam_v1_1_0/ update
	make -C ${SUME_FOLDER}/lib/hw/xilinx/cores/cam_v1_1_0/ all
	make -C ${SUME_SDNET}/sw/sume all
	make -C ${SUME_FOLDER} all

	# cd $DRIVER_FOLDER
	# make all
	# make install
	# modprobe sume_riffa
	# lsmod | grep sume_riffa

program_fpga_nf_loopback: init_sume
	vivado -nolog -nojournal -mode batch -source ${BIT_FOLDER}/download.tcl -tclargs 0 ${BIT_FOLDER}/nf_sume_10g_loopback.bit

program_fpga_l2_pktgen: init_sume
	vivado -nolog -nojournal -mode batch -source ${BIT_FOLDER}/download.tcl -tclargs 0 ${BIT_FOLDER}/l2_switch_pktgen.bit

program_fpga_simple_sume: init_sume
	vivado -nolog -nojournal -mode batch -source ${BIT_FOLDER}/download.tcl -tclargs 0 ${BIT_FOLDER}/simple_sume_switch.bit

init_sume:
	djtgcfg enum
	djtgcfg init -d NetSUME

clean:
	rm -fv *.log *.jou *.Xil
	make -C ${P4_PROJECT_DIR} clean
