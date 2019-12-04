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

BIT_FOLDER=./bitstreams

PROJECTS_DIR = ${SUME_SDNET}/projects/
PROJECTS_DIR_INSTANCES := $(shell cd $(PROJECTS_DIR) && find . -maxdepth 1 -type d)
PROJECTS_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(PROJECTS_DIR_INSTANCES)))

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
	rm -rf .Xil
	rm -rf $(shell find -name *.log -o -name *.jou)
	make -C ${P4_PROJECT_DIR} clean

projectsclean:
	for lib in $(PROJECTS_DIR_INSTANCES) ; do \
		if test -f $(PROJECTS_DIR)/$$lib/Makefile; \
			then $(MAKE) -C $(PROJECTS_DIR)/$$lib/ clean; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//projects cleaned.";
	@echo "/////////////////////////////////////////";
