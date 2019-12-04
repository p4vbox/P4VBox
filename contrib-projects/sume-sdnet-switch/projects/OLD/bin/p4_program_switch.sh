#!/bin/bash

source $SUME_SETTINGS

cd ${NF_DESIGN_DIR}/bitfiles/
bash program_switch.sh
# djtgcfg enum
# djtgcfg init -d NetSUME
# dsumecfg write -d NetSUME -s 1 -f ${P4_PROJECT_NAME}.bit
# dsumecfg reconfig -d NetSUME -s 1

# tclargs 0 -> corresponde ao Id do device XC7VX690T obtido com o comando init -d NetSUME
# vivado -nolog -nojournal -mode batch -source download.tcl -tclargs 0 ${P4_PROJECT_NAME}.bit
cd ${P4_PROJECT_BIN}
