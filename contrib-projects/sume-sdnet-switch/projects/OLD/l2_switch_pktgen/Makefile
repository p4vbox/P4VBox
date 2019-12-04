
# Makefile to build the SUME-SDNet module / wrapper IP for use in the SUME project

PX=sdnet
TARGET=${SUME_FOLDER}/lib/hw/contrib/cores
SWITCH_INFO=src/.sdnet_switch_info.dat

# Compile to HDL with P4-SDNet
# Running vivado_sim.bash or questa.bash compares the HDL simulation output to user provided expected output
all: run_scripts
	rsync -av --ignore-missing-args src/*.tbl ${SDNET_OUT_DIR}/${P4_SWITCH}/
	cp testdata/*.txt ${SDNET_OUT_DIR}/${P4_SWITCH}/
	cp testdata/*.axi ${SDNET_OUT_DIR}/${P4_SWITCH}/

gen_src:
	make -C src/

gen_testdata:
	make -C testdata/

compile:
	$(PX) ./src/${P4_SWITCH}.sdnet -skipEval -busType axi -busWidth 256 -singlecontrolport -workDir ${SDNET_OUT_DIR} -altVivadoScripts -prefix ${P4_SWITCH}

# Need P4_SWITCHs config_writes are copy to config_writes folder, when are building each IP
gen_config_writes:
	${SUME_SDNET}/bin/gen_config_writes.py config_writes/config_writes.txt ${P4_SWITCH_BASE_ADDR} testdata

run_scripts:
	# The following command only applies if running P4_SWITCH Questa Simulation with Ubuntu
	sed -i 's/vsim/vsim \-ldflags \"\-B\/usr\/lib\/x86\_64\-linux-gnu\"/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/questa.bash
	# modify the P4_SWITCH_tb so that it writes the table configuration writes to a file
	${SUME_SDNET}/bin/modify_P4_SWITCH_tb.py ${SDNET_OUT_DIR}/${P4_SWITCH}/Testbench/${P4_SWITCH}_tb.sv
	rsync -av --ignore-missing-args src/*.tbl ${SDNET_OUT_DIR}/${P4_SWITCH}/${P4_SWITCH}.TB/
	cp testdata/src.pcap ${SDNET_OUT_DIR}/${P4_SWITCH}/${P4_SWITCH}.TB/Packet.user
	cp testdata/Tuple_in.txt ${SDNET_OUT_DIR}/${P4_SWITCH}/${P4_SWITCH}.TB/Tuple.user
	# Fix introduced for SDNet 2017.4
	sed -i 's/xsim\.dir\/xsc\/dpi\.so/dpi\.so/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/vivado_sim.bash
	sed -i 's/xsim\.dir\/xsc\/dpi\.so/dpi\.so/g' ${SDNET_OUT_DIR}/${P4_SWITCH}/vivado_sim_waveform.bash

install_sdnet: uninstall_sdnet
	cp -r ${SDNET_OUT_DIR} ${TARGET}/
	mkdir ${TARGET}/${SDNET_OUT_DIR}/wrapper${P4_ID}
	cp ${SUME_SDNET}/templates/sss_wrapper/hdl/changeEndian.v ${TARGET}/${SDNET_OUT_DIR}/wrapper${P4_ID}/
	cp ${SUME_SDNET}/templates/sss_wrapper/hdl/nf_sume_sdnet${P4_ID}.v ${TARGET}/${SDNET_OUT_DIR}/wrapper${P4_ID}/
	cp ${SUME_SDNET}/templates/sss_wrapper/hdl/sume_to_sdnet.v ${TARGET}/${SDNET_OUT_DIR}/wrapper${P4_ID}/
	cp ${SUME_SDNET}/templates/sss_wrapper/tcl/nf_sume_sdnet${P4_ID}.tcl ${TARGET}/${SDNET_OUT_DIR}/
	cp ${SUME_SDNET}/templates/sss_wrapper/Makefile ${TARGET}/${SDNET_OUT_DIR}/
	make -C ${TARGET}/${SDNET_OUT_DIR}/

uninstall_sdnet:
	rm -rf ${TARGET}/${SDNET_OUT_DIR}

# clean only can called for out-script becouse remove all IP folders
clean:
	make -C src/ clean
	make -C testdata/ clean
	rm -rf nf_sume_sdnet*
	rm -f $(shell find -name *.log -o -name *.jou)
	rm -f sw/config_tables.c
