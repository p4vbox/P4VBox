#!/bin/bash

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
cd ~/projects/
iface=eth2
switch_ip=10.0.0.3
switch_log=admin
switch_passw=admin
config_file=config_switch_commands.sh

ifconfig ${iface} 10.0.0.1

sshpass -p ${switch_passw} ssh ${switch_log}@${switch_ip} < ${config_file}

ifconfig ${iface} 0.0.0.0

cd $folder

exit
