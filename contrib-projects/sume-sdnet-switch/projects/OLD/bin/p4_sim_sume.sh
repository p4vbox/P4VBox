#!/bin/bash

source ${SUME_SETTINGS}
cd ${NF_DESIGN_DIR}/test/sim_switch_default && make
cd ${SUME_FOLDER}
./tools/scripts/nf_test.py sim --major switch --minor default
