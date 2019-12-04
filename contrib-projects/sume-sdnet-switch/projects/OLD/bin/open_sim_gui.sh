#!/bin/bash

echo ----------------- OPEN SIMULATION GUI ---------------------
source ${SUME_SETTINGS}
cd ${SUME_FOLDER}
./tools/scripts/nf_test.py sim --major switch --minor default --gui
cd ${P4_PROJECT_BIN}
