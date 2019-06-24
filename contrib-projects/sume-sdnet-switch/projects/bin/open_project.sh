#!/bin/bash

echo ------------------- OPEN PROJECT ----------------------
source ${SUME_SETTINGS}
vivado ${NF_DESIGN_DIR}/hw/project/simple_sume_switch.xpr
cd ${P4_PROJECT_BIN}
