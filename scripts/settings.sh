##################################################################################
# This software was developed by Institute of Informatics of the Federal
# University of Rio Grande do Sul (INF-UFRGS) basied in setting.sh developed by
# Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268
#
# File:
#       settings_p4vbox.sh
#
# Author:
#       Mateus Saquetti
#
# Description:
#       This script set the environment variables to the P4-NetFPGA lagacy and
#       the new system P4VBox
#
# Create date:
#       11.12.2018
#
# Additional Comments:
#       Add this lines at your enviroment viriables file (~/.bashrc):
#       #### P4VBox #####
#       export P4VBOX_ENV_SETTINGS=/root/projects/P4VBox/scripts/settings_p4vbox.sh
#       source ${P4VBOX_ENV_SETTINGS}
#
##################################################################################

export P4_PROJECT_NAME=l2_switch
export NF_PROJECT_NAME=simple_sume_switch
export SUME_FOLDER=${HOME}/projects/P4VBox
export SUME_SDNET=${SUME_FOLDER}/contrib-projects/sume-sdnet-switch
export P4_PROJECT_DIR=${SUME_SDNET}/projects/${P4_PROJECT_NAME}
export LD_LIBRARY_PATH=${SUME_SDNET}/sw/sume:${LD_LIBRARY_PATH}
export PROJECTS=${SUME_FOLDER}/projects
export DEV_PROJECTS=${SUME_FOLDER}/contrib-projects
export IP_FOLDER=${SUME_FOLDER}/lib/hw/std/cores
export CONTRIB_IP_FOLDER=${SUME_FOLDER}/lib/hw/contrib/cores
export CONSTRAINTS=${SUME_FOLDER}/lib/hw/std/constraints
export XILINX_IP_FOLDER=${SUME_FOLDER}/lib/hw/xilinx/cores
export NF_DESIGN_DIR=${P4_PROJECT_DIR}/${NF_PROJECT_NAME}
export NF_WORK_DIR=/tmp/${USER}
export PYTHONPATH=.:${SUME_SDNET}/bin:${SUME_FOLDER}/tools/scripts/:${NF_DESIGN_DIR}/lib/Python:${SUME_FOLDER}/tools/scripts/NFTest
export DRIVER_NAME=sume_riffa_v1_0_0
export DRIVER_FOLDER=${SUME_FOLDER}/lib/sw/std/driver/${DRIVER_NAME}
export APPS_FOLDER=${SUME_FOLDER}/lib/sw/std/apps/${DRIVER_NAME}
export HWTESTLIB_FOLDER=${SUME_FOLDER}/lib/sw/std/hwtestlib

export P4_SCRIPTS=${SUME_FOLDER}/scripts
export P4_NEWPROJ=${SUME_SDNET}/bin/make_new_p4_proj.py
# export P4VBOX=${SUME_FOLDER}/scripts/settings_p4vbox.sh
