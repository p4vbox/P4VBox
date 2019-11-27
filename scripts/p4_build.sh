#!/bin/bash

dir=${PWD}
SDNET_OUT_DIR=nf_sdnet_ip_${P4_SWITCH}

echo
echo Setting SDNET_OUT_DIR = ${SDNET_OUT_DIR}
echo Source Generating P4: ${P4_SWITCH}
cd ${P4_PROJECT_DIR} && make gen_src
echo
echo Compiling P4: ${P4_SWITCH}
cd ${P4_PROJECT_DIR} && make compile
echo
echo Generating IP: ${P4_SWITCH}
cd ${P4_PROJECT_DIR} && make
cd ${P4_PROJECT_DIR}/${SDNET_OUT_DIR}/${P4_SWITCH}/
./vivado_sim.bash | tee ../../log/${P4_SWITCH}.log
echo
echo Installing IP: ${P4_SWITCH}
cd ${P4_PROJECT_DIR} && make install_sdnet
echo
echo Get Config Writes: ${P4_SWITCH}
writes_src=${P4_PROJECT_DIR}/${SDNET_OUT_DIR}/${P4_SWITCH}/config_writes.txt
writes_dst=${P4_PROJECT_DIR}/config_writes/confW_${P4_SWITCH}.txt
cp -fv  ${writes_src} ${writes_dst}
echo

cd ${dir}
