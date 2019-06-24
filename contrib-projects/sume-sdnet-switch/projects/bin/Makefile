#
# Makefile for clean folder
#

BIT_FOLDER=./bitstreams

all: clean

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
	rm -fv *.log
	rm -fv *.jou
	rm -fv *.Xil
