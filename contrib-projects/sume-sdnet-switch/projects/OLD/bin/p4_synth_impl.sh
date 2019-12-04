#!/bin/bash

source $SUME_SETTINGS

cd ${NF_DESIGN_DIR} && make
cd ${P4_PROJECT_BIN}
cp -v ${NF_DESIGN_DIR}/hw/project/${NF_PROJECT_NAME}.runs/impl_1/*.bit ${NF_DESIGN_DIR}/bitfiles/${P4_PROJECT_NAME}.bit
cp -v $P4_PROJECT_DIR/testdata/config_writes.sh ${NF_DESIGN_DIR}/bitfiles/
