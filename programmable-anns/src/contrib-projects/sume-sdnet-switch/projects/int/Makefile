#
# Copyright (c) 2017 Stephen Ibanez
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme.
#

# All rights reserved.
#


#
# Description:
#              Adapted to run in PvS architecture
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

VIRTUAL_SWITCH=vSwitch${P4_SWITCH_ID}
SDNET_OUT_DIR=nf_sdnet_ip_${VIRTUAL_SWITCH}
P4_SWITCH_WRAPPER=nf_sdnet_${VIRTUAL_SWITCH}.v
PX=sdnet
PX_FLAGS=-prefix ${VIRTUAL_SWITCH} -busType axi -busWidth 256 -singlecontrolport -workDir ${SDNET_OUT_DIR} -altVivadoScripts
TARGET=${SUME_FOLDER}/lib/hw/contrib/cores
SWITCH_INFO=src/.sdnet_switch_info_${P4_SWITCH}.dat

# Compile to HDL with P4-SDNet
# Running vivado_sim.bash or questa.bash compares the HDL simulation output to user provided expected output
all: run_scripts
	cp src/*.tbl ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/
	cp testdata/*.txt ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/
	cp testdata/*.axi ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/

# Compile to HDL with P4-SDNet - Not corrently used
# Running vivado_sim.bash or questa.bash compares the HDL simulation output to the C++ simulation output
cpp_test: clean frontend compile_cpp_test run_scripts
	cp src/*.tbl ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/
	cp testdata/src.pcap ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/Packet.user
	cp testdata/Tuple_in.txt ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/Tuple.user
	cp src/*.tbl ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/${VIRTUAL_SWITCH}.TB/
	cp testdata/src.pcap ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/${VIRTUAL_SWITCH}.TB/Packet.user
	cp testdata/Tuple_in.txt ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/${VIRTUAL_SWITCH}.TB/Tuple.user

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
	${SUME_SDNET}/bin/gen_P4_SWITCH_externs.py ${SWITCH_INFO} ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/ ${SUME_SDNET}/templates/ ./testdata/ ./sw/ --base_address ${P4_SWITCH_BASE_ADDR}
	${SUME_SDNET}/bin/gen_P4_SWITCH_API.py ${SWITCH_INFO} ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/ sw/ ${SUME_SDNET}/templates/ --base_address ${P4_SWITCH_BASE_ADDR}
	${SUME_SDNET}/bin/gen_P4_SWITCH_CLI.py ${SWITCH_INFO} ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/ sw/ ${SUME_SDNET}/templates/ --base_address ${P4_SWITCH_BASE_ADDR}
	# The following command only applies if running VIRTUAL_SWITCH Questa Simulation with Ubuntu
	sed -i 's/vsim/vsim \-ldflags \"\-B\/usr\/lib\/x86\_64\-linux-gnu\"/g' ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/questa.bash
	# modify the P4_SWITCH_tb so that it writes the table configuration writes to a file
	${SUME_SDNET}/bin/modify_P4_SWITCH_tb.py ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/Testbench/${VIRTUAL_SWITCH}_tb.sv
	# Fix introduced for SDNet 2017.4
	sed -i 's/xsim\.dir\/xsc\/dpi\.so/dpi\.so/g' ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/vivado_sim.bash
	sed -i 's/xsim\.dir\/xsc\/dpi\.so/dpi\.so/g' ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/vivado_sim_waveform.bash
	# Fix introduced for SDNet 2018.2
	sed -i 's/glbl_sim/glbl/g' ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/vivado_sim_waveform.bash
	sed -i 's/SimpleSumeSwitch_tb_sim#work.glbl/SimpleSumeSwitch_tb/g' ${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/vivado_sim_waveform.bash

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
