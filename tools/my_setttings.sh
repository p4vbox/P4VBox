################################################################################
#
# Copyright (c) 2015 University of Cambridge
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme.
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

# variable for file settings of SUME repository
export SUME_SETTINGS=/root/projects/P4-NetFPGA/tools/settings.sh

# variables of bitbucket repository
export GIT_P4_PROJECT_NAME=switch_calc
export GIT_NF_PROJECT_NAME=simple_sume_switch
export GIT_FOLDER=~/bitbucket/reconfigurableswitch/projects
export GIT_SUME_FOLDER=${GIT_FOLDER}/P4-NetFPGA
export GIT_SUME_SETTINGS=${GIT_SUME_FOLDER}/tools/my_settings.sh
export GIT_SUME_SDNET=${GIT_SUME_FOLDER}/contrib-projects/sume-sdnet-switch
export GIT_P4_PROJECT_DIR=${GIT_SUME_SDNET}/projects/${GIT_P4_PROJECT_NAME}
export P4_PROJECT_BIN=${SUME_SDNET}/projects/bin
# export LD_LIBRARY_PATH=${GIT_SUME_SDNET}/sw/sume:${LD_LIBRARY_PATH}
# export GIT_PROJECTS=${GIT_SUME_FOLDER}/projects
export GIT_PROJECTS=${GIT_SUME_SDNET}/projects
# export GIT_DEV_PROJECTS=${GIT_SUME_FOLDER}/contrib-projects
# export IP_FOLDER=${GIT_SUME_FOLDER}/lib/hw/std/cores
export GIT_CONTRIB_IP_FOLDER=${GIT_SUME_FOLDER}/lib/hw/contrib/cores
# export CONSTRAINTS=${GIT_SUME_FOLDER}/lib/hw/std/constraints
# export XILINX_IP_FOLDER=${GIT_SUME_FOLDER}/lib/hw/xilinx/cores
export GIT_NF_DESIGN_DIR=${GIT_P4_PROJECT_DIR}/${GIT_NF_PROJECT_NAME}
# export NF_WORK_DIR=/tmp/${USER}
# export PYTHONPATH=.:${GIT_SUME_SDNET}/bin:${GIT_SUME_FOLDER}/tools/scripts/:${GIT_NF_DESIGN_DIR}/lib/Python:${GIT_SUME_FOLDER}/tools/scripts/NFTest
# export DRIVER_NAME=sume_riffa_v1_0_0
# export DRIVER_FOLDER=${GIT_SUME_FOLDER}/lib/sw/std/driver/${DRIVER_NAME}
# export APPS_FOLDER=${GIT_SUME_FOLDER}/lib/sw/std/apps/${DRIVER_NAME}
# export HWTESTLIB_FOLDER=${GIT_SUME_FOLDER}/lib/sw/std/hwtestlib
