#!/bin/bash

cd ${P4_PROJECT_DIR}/config_writes/ && cat confW_* >> config_writes.txt
cd ${P4_PROJECT_DIR}/config_writes/ && cat config_writes.txt
cd ${P4_PROJECT_DIR} && make gen_config_writes
cd ${NF_DESIGN_DIR}/test/sim_switch_default && make
