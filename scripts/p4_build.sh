#!/bin/bash

#
# Copyright (c) 2019 Mateus Saquetti
# All rights reserved.
#
# This software was modified by Institute of Informatics of the Federal
# University of Rio Grande do Sul (INF-UFRGS)
#
# Description:
#              Adapted to run in P4VBox architecture
# Create Date:
#              31.05.2019
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#

verbose=$1

dir=${PWD}
VIRTUAL_SWITCH=vSwitch${P4_SWITCH_ID}
SDNET_OUT_DIR=nf_sdnet_ip_${VIRTUAL_SWITCH}

echo
echo Setting SDNET_OUT_DIR = ${SDNET_OUT_DIR}
echo         Generating P4 = ${P4_SWITCH}
echo                    ID = ${P4_SWITCH_ID}
cd ${P4_PROJECT_DIR} && make gen_src
echo
echo Compiling P4: ${P4_SWITCH}
cd ${P4_PROJECT_DIR} && make compile
echo

if [ -z $verbose ]; then
  echo Generating IP: ${P4_SWITCH}
  cd ${P4_PROJECT_DIR}
  make >> log/build_${P4_SWITCH}.log
  cd ${P4_PROJECT_DIR}/${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/
  ./vivado_sim.bash >> ../../log/build_${P4_SWITCH}.log
  echo
  echo Installing IP: ${P4_SWITCH}
  cd ${P4_PROJECT_DIR}
  make install_sdnet >> log/install_${P4_SWITCH}.log
else
  echo Generating IP: ${P4_SWITCH}
  cd ${P4_PROJECT_DIR}
  make | tee -a log/build_${P4_SWITCH}.log
  cd ${P4_PROJECT_DIR}/${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/
  ./vivado_sim.bash | tee -a ../../log/build_${P4_SWITCH}.log
  echo
  echo Installing IP: ${P4_SWITCH}
  cd ${P4_PROJECT_DIR}
  make install_sdnet | tee -a log/install_${P4_SWITCH}.log

fi

echo
echo Get Config Writes: ${P4_SWITCH}
writes_src=${P4_PROJECT_DIR}/${SDNET_OUT_DIR}/${VIRTUAL_SWITCH}/config_writes.txt
writes_dst=${P4_PROJECT_DIR}/config_writes/confW_${P4_SWITCH}.txt
cp -fv  ${writes_src} ${writes_dst}
echo

cd ${dir}
