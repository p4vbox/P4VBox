export P4VBOX_FOLDER=${HOME}/projects/P4VBOX
export P4VBOX_DEMO=${P4VBOX_FOLDER}/NNP4-build

export P4_PROJECT_NAME=NNP4_2vS
export SUME_FOLDER=${P4VBOX_FOLDER}/src
export SUME_SDNET=${SUME_FOLDER}/contrib-projects/sume-sdnet-switch
export DRIVER_NAME=sume_riffa_v1_0_0
export DRIVER_FOLDER=${SUME_FOLDER}/lib/sw/std/driver/${DRIVER_NAME}
export APPS_FOLDER=${SUME_FOLDER}/lib/sw/std/apps/${DRIVER_NAME}

export P4VBOX=${SUME_FOLDER}/scripts/settings.sh
export P4VBOX_VSWITCH=NNP4_S1
export P4VBOX_SCRIPTS=${SUME_FOLDER}/scripts
export P4VBOX_MAKE_LIBRARY=${P4VBOX_SCRIPTS}/tools/make_library.sh
export P4VBOX_INSTALL_DRIVER=${P4VBOX_SCRIPTS}/tools/make_driver.sh
export P4VBOX_TESTER=${P4VBOX_DEMO}/tools/NNP4_tester_2vS
export P4VBOX_TESTER_VIEW=${P4VBOX_DEMO}/tools/view_packets.py
