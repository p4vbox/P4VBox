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

set folder=$PWD

echo " " && echo " "
read -p "Would you likeinstall Vivado? (Y/N): " confirm
if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  read -p "Enter with the full path to Vivado 2018.2 folder: " vivadopath
  cd $vivadopath
  if [ -f "xsetup" ]; then
    sudo chmod +x xsetup
    sudo ./xsetup
  else
  	echo "xsetup not found."
    cd $folder
    exit 1
  fi
fi

echo " " && echo " "
read -p "Would you like install SDNet? (Y/N): " confirm
if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  read -p "Enter with the full path to SDNet 2018.2 folder: " sdnetpath
  cd $sdnetpath
  if [ -f "xsetup" ]; then
    sudo chmod +x xsetup
    sudo ./xsetup
  else
  	echo "xsetup not found."
    cd $folder
    exit 1
  fi
fi

read -p "Would you like setup your environment variables? (Y/N): " confirm
if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  echo " " >> ~/.bashrc
  echo " " >> ~/.bashrc
  echo " " >> ~/.bashrc
  echo "#### Vivado and SDNet Floating License ####" >> ~/.bashrc
  echo "export XILINXD_LICENSE_FILE=2100@mateus-ufrgs-ubuntu14" >> ~/.bashrc
  echo "#### SDNet ####" >> ~/.bashrc
  echo "export PATH=/opt/Xilinx/SDNet/2018.2/bin:$PATH" >> ~/.bashrc
  echo "source /opt/Xilinx/SDNet/2018.2/settings64.sh" >> ~/.bashrc
  echo "##### Vivado 2018 & SDK #####" >> ~/.bashrc
  echo "source /opt/Xilinx/Vivado/2018.2/settings64.sh" >> ~/.bashrc
  echo "#### P4VBox #####" >> ~/.bashrc
  echo "export P4VBOX=${HOME}/projects/P4VBox/scripts/settings.sh" >> ~/.bashrc
  echo "source ${P4VBOX}" >> ~/.bashrc
  echo "#### P4-NetFPGA #####" >> ~/.bashrc
  echo "export P4_NETFPGA=${HOME}/projects/P4-NetFPGA/tools/settings.sh" >> ~/.bashrc
  echo "# source ${P4_NETFPGA}" >> ~/.bashrc
  echo "#### NetFPGA-SUME-live ####" >> ~/.bashrc
  echo "# export NETFPGA_SUME=${HOME}/projects/NetFPGA-SUME/tools/settings.sh" >> ~/.bashrc
  echo "# source ${NETFPGA_SUME}" >> ~/.bashrc
  echo "# Set DISPLAY env variable so that xsct works properly from cmdline" >> ~/.bashrc
  echo "if [ -z "$DISPLAY" ]; then" >> ~/.bashrc
  echo "    export DISPLAY=dummy" >> ~/.bashrc
  echo "fi" >> ~/.bashrc
fi

echo " " && echo " "
read -p "Would you like install required packets? (Y/N): " confirm
if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  sudo apt-get install -y gcc g++ minicom  libusb-dev  libc6-i386  python-serial python-wxgtk3.0  python-scapy lib32z1 lib32ncurses5 libbz2-1.0 lib64z1 lib64ncurses5 libncurses5-dev libbz2-1.0 lib32stdc++6 lib64stdc++6 libgtk2.0-0:i386 libstdc++6:i386 libstdc++5:i386 libstdc++5:amd64 linux-headers-$(uname -r) build-essential git patch vim screen install openssh-client openssh-client lsb gcc-multilib g++-multilib
  sudo apt-get install -y python-matplotlib python-pip libc6-dev-i386
  sudo pip install ascii_graph
fi

read -p "Would you like clone P4-NetFPGA? (Y/N): " confirm
if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  echo " " && echo " "
  mkdir ~/projects
  cd ~/projects
  git clone https://github.com/NetFPGA/P4-NetFPGA-live.git P4-NetFPGA
  cd P4-NetFPGA
  git pull --tags
  export P4_PROJECT_NAME=switch_calc
  export NF_PROJECT_NAME=simple_sume_switch
  export SUME_FOLDER=${HOME}/projects/P4-NetFPGA
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
  cd $SUME_FOLDER/lib/hw/xilinx/cores/tcam_v1_1_0/ && make update && make
  cd $SUME_FOLDER/lib/hw/xilinx/cores/cam_v1_1_0/ && make update && make
  cd $SUME_SDNET/sw/sume && make
  cd $SUME_FOLDER && make
fi

echo " " && echo " "
read -p "Would you like clone P4VBox? (Y/N): " confirm
if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  echo " " && echo " "
  mkdir ~/projects
  cd ~/projects
  git clone https://github.com/NetFPGA/P4-NetFPGA-live.git P4-NetFPGA
  cd P4-NetFPGA
  git pull --tags
  export P4_PROJECT_NAME=l2_switch
  export NF_PROJECT_NAME=simple_sume_switch
  export SUME_FOLDER=${HOME}/projects/P4VBox
  export SUME_SDNET=${SUME_FOLDER}/contrib-projects/sume-sdnet-switch
  export P4_PROJECT_DIR=${SUME_SDNET}/projects/${P4_PROJECT_NAME}
  export P4_PROJECT_EXAMPLES=${SUME_SDNET}/projects/${CONTRIB_EXAMPLES}/${P4_PROJECT_NAME}
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
  export P4VBOX_SCRIPTS=${SUME_FOLDER}/scripts
  export P4_NEWPROJ=${SUME_SDNET}/bin/make_new_p4_proj.py
  export P4VBOX=${P4VBOX_SCRIPTS}/settings.sh
  cd $SUME_FOLDER/lib/hw/xilinx/cores/tcam_v1_1_0/ && make update && make
  cd $SUME_FOLDER/lib/hw/xilinx/cores/cam_v1_1_0/ && make update && make
  cd $SUME_SDNET/sw/sume && make
  cd $SUME_FOLDER && make
  cd $DRIVER_FOLDER
fi

echo " " && echo " "
read -p "Would you like to run the System Setup [ONLY IF SUME BOARD WERE INSTALLED IN THIS HOST]? (Y/N): " confirm
if [[ "$confirm" !=~ ^([yY][eE][sS]|[yY])+$ ]]; then
  echo " "
  echo " "
  echo "##########################"
  echo "  Installation completed"
  echo "##########################"
  cd $folder
  exit 0
fi

cd $DRIVER_FOLDER
if [ -f "sume_riffa.c" ]; then
  sudo make all
  sudo make install
  sudo modprobe sume_riffa
  ifconfig -a
  lspci -vxx | grep -i Xilinx
else
  echo "Driver Folder not Found"
  cd $folder
  exit 0
fi

echo " " && echo " "
read -p "Enter with the full path to Digilent Adept Tools folder: " digilentpath
cd $digilentpath
if [ -f "digilent.adept.*" ]; then
  sudo dpkg -i digilent.adept.*
else
  echo "Digilent Adept Tools not found."
  cd $folder
  exit 1
fi

sudo chmod 666 /dev/ttyUSB1

sudo echo " " >> /etc/sysctl.d/99-sysctl.conf
sudo echo "# Disable ipv6" >> /etc/sysctl.d/99-sysctl.conf
sudo echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.d/99-sysctl.conf
sudo echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.d/99-sysctl.conf
sudo echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.d/99-sysctl.conf

sudo vim /etc/init/avahi-daemon.conf

sudo vim /etc/default/avahi-daemon

sudo systemctl mask avahi-daemon
sudo systemctl mask avahi-daemon.socket
sudo systemctl stop avahi-daemon
sudo systemctl stop avahi-daemon.socket

sudo vim /etc/init.d/avahi-daemon

sudo vim /etc/NetworkManager/NetworkManager.conf

sudo vim /etc/network/interfaces

sudo vim /etc/default/grub

sudo update-grub && reboot
