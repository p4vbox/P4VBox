#!/bin/bash

source ${SUME_SETTINGS}
cd ${P4_PROJECT_DIR} && make
cd ${P4_PROJECT_DIR}/${SDNET_OUT_DIR}/${P4_SWITCH}/
./vivado_sim.bash
cd ${P4_PROJECT_DIR}/
cp -v ${P4_PROJECT_DIR}/${SDNET_OUT_DIR}/${P4_SWITCH}/config_writes.txt ${P4_PROJECT_DIR}/config_writes/IP${P4_ID}_${P4_SWITCH}.txt | tee -a ${P4_PROJECT_DIR}/log/log_2-config_writes.txt
