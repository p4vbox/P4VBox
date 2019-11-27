#!/bin/bash

set folder=$PWD

cd $SUME_FOLDER/lib/hw/xilinx/cores/tcam_v1_1_0/ && make update && make
cd $SUME_FOLDER/lib/hw/xilinx/cores/cam_v1_1_0/ && make update && make
cd $SUME_SDNET/sw/sume && make
cd $SUME_FOLDER && make

# Diver
# cd $DRIVER_FOLDER
# make all
# make install
# modprobe sume_riffa
# lsmod | grep sume_riffa

cd $folder

exit 0
