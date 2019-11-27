#
# Makefile for clean folder
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
