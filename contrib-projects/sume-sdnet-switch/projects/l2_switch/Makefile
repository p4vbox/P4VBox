##################################################################################
# This software was developed by Institute of Informatics of the Federal
# University of Rio Grande do Sul (INF-UFRGS)
#
# File:
#       Makefile
#
# Author:
#       Mateus Saquetti
#
# Description:
#       Makefile to build the P4 module / wrapper IP for use in VirtP4 project
#
# Create date:
#       15.12.2018
#
# Additional Comments:
#
#
##################################################################################

SDNET_OUT_DIR=nf_sdnet_ip_${P4_SWITCH}
P4_SWITCH_WRAPPER=nf_sdnet_${P4_SWITCH}.v
PX=sdnet
PX_FLAGS=-prefix ${P4_SWITCH} -busType axi -busWidth 256 -singlecontrolport -workDir ${SDNET_OUT_DIR} -altVivadoScripts
TARGET=${SUME_FOLDER}/lib/hw/contrib/cores
SWITCH_INFO=src/.sdnet_switch_info_${P4_SWITCH}.dat

# Compile to HDL with P4-SDNet
# Running vivado_sim.bash or questa.bash compares the HDL simulation output to user provided expected output
all: run_scripts
	cp src/*.tbl ${SDNET_OUT_DIR}/${P4_SWITCH}/
	cp testdata/*.txt ${SDNET_OUT_DIR}/${P4_SWITCH}/
	cp testdata/*.axi ${SDNET_OUT_DIR}/${P4_SWITCH}/

# Compile to HDL with P4-SDNet - Not corrently used
# Running vivado_sim.bash or questa.bash compares the HDL simulation output to the C++ simulation output
cpp_test: clean frontend compile_cpp_test run_scripts
	cp src/*.tbl ${SDNET_OUT_DIR}/${P4_SWITCH}/
	cp testdata/src.pcap ${SDNET_OUT_DIR}/${P4_SWITCH}/Packet.user
	cp testdata/Tuple_in.txt ${SDNET_OUT_DIR}/${P4_SWITCH}/Tuple.user
	cp src/*.tbl ${SDNET_OUT_DIR}/${P4_SWITCH}/${P4_SWITCH}.TB/
	cp testdata/src.pcap ${SDNET_OUT_DIR}/${P4_SWITCH}/${P4_SWITCH}.TB/Packet.user
	cp testdata/Tuple_in.txt ${SDNET_OUT_DIR}/${P4_SWITCH}/${P4_SWITCH}.TB/Tuple.user

gen_src:
	make -C src/

gen_testdata:
	make -C testdata/

# Not corrently used
compile_cpp_test:
	$(PX) ./src/${P4_PROJECT_NAME}.sdnet $(PX_FLAGS)

compile:
	$(PX) ./src/${P4_SWITCH}.sdnet -skipEval $(PX_FLAGS)

# Need P4_SWITCHs config_writes are copy to config_writes folder, when are building each IP
gen_config_writes:
	${SUME_SDNET}/bin/gen_config_writes.py config_writes/config_writes.txt ${P4_SWITCH_BASE_ADDR} testdata

run_scripts:
	${SUME_SDNET}/bin/gen_P4_SWITCH_externs.py ${SWITCH_INFO} ${SDNET_OUT_DIR}/${P4_SWITCH}/ ${SUME_SDNET}/templates/ ./testdata/ ./sw/ --base_address ${P4_SWITCH_BASE_ADDR}
	${SUME_SDNET}/bin/gen_P4_SWITCH_API.py ${SWITCH_INFO} ${SDNET_OUT_DIR}/${P4_SWITCH}/ sw/ ${SUME_SDNET}/templates/ --base_address ${P4_SWITCH_BASE_ADDR}
	${SUME_SDNET}/bin/gen_P4_SWITCH_CLI.py ${SWITCH_INFO} ${SDNET_OUT_DIR}/${P4_SWITCH}/ sw/ ${SUME_SDNET}/templates/ --base_address ${P4_SWITCH_BASE_ADDR}
	# The following command only applies if running P4_SWITCH Questa Simulation with Ubuntu
	sed -i 's/vsim/vsim \-ldflags \"\-B\/usr\/lib\/x86\_64\-linux-gnu\"/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/questa.bash
	# modify the P4_SWITCH_tb so that it writes the table configuration writes to a file
	${SUME_SDNET}/bin/modify_P4_SWITCH_tb.py ${SDNET_OUT_DIR}/${P4_SWITCH}/Testbench/${P4_SWITCH}_tb.sv
	# Fix introduced for SDNet 2017.4
	sed -i 's/xsim\.dir\/xsc\/dpi\.so/dpi\.so/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/vivado_sim.bash
	sed -i 's/xsim\.dir\/xsc\/dpi\.so/dpi\.so/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/vivado_sim_waveform.bash
	# Fix introduced for SDNet 2018.2
	sed -i 's/glbl_sim/glbl/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/vivado_sim_waveform.bash
	sed -i 's/SimpleSumeSwitch_tb_sim#work.glbl/SimpleSumeSwitch_tb/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/vivado_sim_waveform.bash

# install the SDNet core as a NetFPGA-SUME-SDNet library core
install_sdnet: uninstall_sdnet
	cp -r ${SDNET_OUT_DIR} ${TARGET}/
	mkdir ${TARGET}/${SDNET_OUT_DIR}/wrapper
	cp ${SUME_SDNET}/templates/sss_wrapper/hdl/changeEndian.v ${TARGET}/${SDNET_OUT_DIR}/wrapper/
	cp ${SUME_SDNET}/templates/sss_wrapper/hdl/${P4_SWITCH_WRAPPER} ${TARGET}/${SDNET_OUT_DIR}/wrapper/
	cp ${SUME_SDNET}/templates/sss_wrapper/hdl/sume_to_sdnet.v ${TARGET}/${SDNET_OUT_DIR}/wrapper/
	cp ${SUME_SDNET}/templates/sss_wrapper/tcl/nf_sume_sdnet.tcl ${TARGET}/${SDNET_OUT_DIR}/
	cp ${SUME_SDNET}/templates/sss_wrapper/Makefile ${TARGET}/${SDNET_OUT_DIR}/
	make -C ${TARGET}/${SDNET_OUT_DIR}/

uninstall_sdnet:
	rm -rf ${TARGET}/${SDNET_OUT_DIR}

# clean only can called for out-script becouse remove all IP folders
clean:
	make -C src/ clean
	make -C testdata/ clean
	rm -rf nf_sdnet_ip_*
	rm -rf log/ config_writes/
	rm -rf $(shell find -name *.log -o -name *.jou)
	rm -f sw/config_tables.c
