#!/bin/bash

source ${SUME_SETTINGS}
cd ${P4_PROJECT_DIR} && rm -rf -v log
cd ${P4_PROJECT_DIR} && rm -rf -v *.jou
cd ${CONTRIB_IP_FOLDER} && rm -rf nf_sume_sdnet*
cd ${P4_PROJECT_DIR} && make clean
cd ${NF_DESIGN_DIR} && make clean
cd ${P4_PROJECT_BIN} && rm -rf -v .Xil*
cd ${P4_PROJECT_DIR} && rm -rf -v *.jou
cd ${P4_PROJECT_DIR}/config_writes && rm -rf -v *
cd ${P4_PROJECT_BIN} && rm -rf -v *.jou
cd ${P4_PROJECT_BIN} && rm -rf -v vivado*.log
