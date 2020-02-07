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

# This script initialize the switch V0330 with commands in config_file
# Dependenses: apt install sshpass
# How to use:
#   Connect the ethernet cable in your machine and the ETH port of switch
#   In a terminal with root, run the this script: ./config_switch.sh
# Tips:
#   To configure the ssh acess to switch:
#     Connect the serial cable in your machine and in CON port of switch; The device can be: /dev/ttyS0 or /dev/ttyS1
#     In a terminal: minicom -b 9600 -8 -w -D /dev/ttyS0
#     In switch:
#       Switch# configure terminal
#       Switch(config)# ip ssh server enable
#       Switch(config)# ip ssh server authentication-type password
#       Switch(config)# username admin password admin
#       Switch(config)# exit
#       Switch# show ip ssh server status

folder=$pwd
cd ${P4VBOX_SCRIPTS}/tools

iface=eth4
switch_ip=10.0.0.3
switch_log=admin
switch_passw=admin
config_file=config_switch_commands.sh

ifconfig ${iface} 10.0.0.1

sshpass -p ${switch_passw} ssh ${switch_log}@${switch_ip} < ${config_file}

ifconfig ${iface} 0.0.0.0

cd $folder

exit
