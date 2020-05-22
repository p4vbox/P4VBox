#!/bin/bash

#

# All rights reserved.
#


#
# Description:
#              Adapted to run in PvS architecture
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
read -p "Would you like install Vivado? (Y/N): " confirm
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
  echo "export XILINXD_LICENSE_FILE=" >> ~/.bashrc
  echo "#### SDNet ####" >> ~/.bashrc
  echo "export PATH=/opt/Xilinx/SDNet/2018.2/bin:$PATH" >> ~/.bashrc
  echo "source /opt/Xilinx/SDNet/2018.2/settings64.sh" >> ~/.bashrc
  echo "##### Vivado 2018 & SDK #####" >> ~/.bashrc
  echo "source /opt/Xilinx/Vivado/2018.2/settings64.sh" >> ~/.bashrc
  echo "# Set DISPLAY env variable so that xsct works properly from cmdline" >> ~/.bashrc
  echo "if [ -z "$DISPLAY" ]; then" >> ~/.bashrc
  echo "    export DISPLAY=dummy" >> ~/.bashrc
  echo "fi" >> ~/.bashrc
fi

echo " " && echo " "
read -p "Would you like install required packets? (Y/N): " confirm
if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  sudo apt-get install -y gcc g++ minicom  libusb-dev  libc6-i386  python-serial python-wxgtk3.0  python-scapy lib32z1
  sudo apt-get install -y lib32z1 lib32ncurses5 libbz2-1.0 lib64z1 lib64ncurses5 libncurses5-dev libbz2-1.0 lib32stdc++6
  sudo apt-get install -y lib64stdc++6 libgtk2.0-0:i386 libstdc++6:i386 libstdc++5:i386 libstdc++5:amd64 linux-headers-$(uname -r)
  sudo apt-get install -y build-essential git patch vim screen openssh-client openssh-client lsb gcc-multilib g++-multilib
  sudo apt-get install -y python-matplotlib python-pip libc6-dev-i386
  sudo pip install ascii_graph
fi

echo " "
echo " "
echo "##########################"
echo "  Installation completed"
echo "##########################"
cd $folder

exit 0

echo " " && echo " "
read -p "Would you like to run the System Setup [ONLY IF SUME BOARD WERE INSTALLED IN THIS HOST]? (Y/N): " confirm
if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
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

fi

echo " "
echo " "
echo "##########################"
echo "  Installation completed"
echo "##########################"
cd $folder
exit 0
