#!/bin/bash

update_env(){
  export NF_PROJECT_NAME=simple_sume_switch
  export SUME_FOLDER=${HOME}/projects/P4-NetFPGA-MOD
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
  export P4NFPGAMOD=${SUME_FOLDER}/scripts/settings.sh
  export P4NFPGAMOD_VSWITCH=${P4_PROJECT_NAME}
  export P4NFPGAMOD_CLI_VSWITCH=${P4_PROJECT_NAME}/sw/CLI_${P4NFPGAMOD_VSWITCH}/P4_SWITCH_CLI.py
  export P4NFPGAMOD_SCRIPTS=${SUME_FOLDER}/scripts
  export P4NFPGAMOD_NEWPROJ=${SUME_SDNET}/bin/make_new_p4_proj.py
  export P4NFPGAMOD_MAKE_LIBRARY=${P4NFPGAMOD_SCRIPTS}/tools/make_library.sh
  export P4NFPGAMOD_CONFIG_SWITCH=${P4NFPGAMOD_SCRIPTS}/tools/config_switch.sh
  export P4NFPGAMOD_PROGSUME=${P4NFPGAMOD_SCRIPTS}/tools/program_sume.sh
  export P4NFPGAMOD_PROGSUME_BITNAME=${P4_PROJECT_NAME}
}

# export P4_PROJECT_NAME=l2_switch
# update_env
# ./project_run.sh
# export P4_PROJECT_NAME=router
# update_env
# ./project_run.sh
# export P4_PROJECT_NAME=firewall
# update_env
# ./project_run.sh
# export P4_PROJECT_NAME=int
# update_env
# ./project_run.sh
# export P4_PROJECT_NAME=l2_l2_band_I
# update_env
# ./project_run.sh
export P4_PROJECT_NAME=router_band_I
update_env
./project_run.sh
export P4_PROJECT_NAME=int_band_I
update_env
./project_run.sh

