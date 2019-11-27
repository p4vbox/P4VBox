#!/bin/bash

set folder=$PWD

cd $NF_DESIGN_DIR/bitfiles/
./program_switch.sh

cd $folder
exit 0
