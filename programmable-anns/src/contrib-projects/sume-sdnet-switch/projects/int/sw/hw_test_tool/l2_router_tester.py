#!/usr/bin/env python

#
# Copyright (c) 2017 Stephen Ibanez
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme.
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


import os, sys, re, cmd, subprocess, shlex, time, random, socket, struct
import numpy as np
from threading import Thread
from collections import OrderedDict

from nf_sim_tools import *

"""
========================================================================================
                                Test Network Topology:
========================================================================================
(MAC_addr_H0)            (MAC_addr_SPort0)    (MAC_addr_SPort3)            (MAC_addr_H3)
 (IP_addr_H0)             (IP_addr_SPort0)    (IP_addr_SPort3)             (IP_addr_H3)
          H0 ------------------ nf0                 nf3 ------------------- H3
                                 |    SUME SWITCH    |
          H1 ------------------ nf1                 nf2 ------------------- H2
 (IP_addr_H1)             (IP_addr_SPort1)    (IP_addr_SPort2)             (IP_addr_H2)
(MAC_addr_H1)            (MAC_addr_SPort1)    (MAC_addr_SPort2)            (MAC_addr_H2)
"""


IFACE_H = {0:"eth0", 1:"eth1", 2:"eth2", 3:"eth3"}
sender = IFACE_H[0]    # the network interface of the sender

DEF_PKT_NUM = 24       # default packets number to simulation
DEF_PKT_SIZE = 256     # default packet size (in bytes)
HEADER_SIZE = 46       # headers size: Ether/IP/UDP
DEF_HOST_NUM = 4       # default hosts number in network topology
src_host = 0           # packets sender host
vlan_id = 0            # vlan identifier to matching with IPI architecture and nf_datapath.v
vlan_prio = 0          # vlan priority

dst_host_map = {0:1, 1:0, 2:3, 3:2}                   # map the sender and receiver Hosts H[0, 1, 2, 3] based in network topology
inv_nf_id_map = {0:"nf0", 1:"nf1", 2:"nf2", 3:"nf3"}  # map the keys of dictionary nf_id_map
vlan_id_map = {"l2_switch":1, "router":2}             # map the vlans of parrallel switches

port_slicing = {}                                     # map the slicing of ports of SUME nf[0, 1, 2, 3] based in network topology
port_slicing[0] = "l2_switch"
port_slicing[1] = "l2_switch"
port_slicing[2] = "router"
port_slicing[3] = "router"

MAC_addr_H = {} # MAC of Hosts H[0, 1, 2, 3] connected to SUME Ports nf[0, 1, 2, 3] respectively
MAC_addr_H[0] = "08:11:11:11:11:08"
MAC_addr_H[1] = "08:22:22:22:22:08"
MAC_addr_H[2] = "08:33:33:33:33:08"
MAC_addr_H[3] = "08:44:44:44:44:08"

IP_addr_H = {} # IP of Hosts connected to nf0, nf1, nf2, nf3 respectively. Not used in this case!
IP_addr_H[0] = "10.1.1.1"
IP_addr_H[1] = "10.2.2.2"
IP_addr_H[2] = "10.3.3.3"
IP_addr_H[3] = "10.4.4.4"

MAC_addr_S = {} # MAC of SUME Ports nf[0, 1, 2, 3] connected to Hosts H[0, 1, 2, 3] respectively
MAC_addr_S[0] = "05:11:11:11:11:05"
MAC_addr_S[1] = "05:22:22:22:22:05"
MAC_addr_S[2] = "05:33:33:33:33:05"
MAC_addr_S[3] = "05:44:44:44:44:05"


class SimpleTester(cmd.Cmd):

    prompt = "> "
    intro = "\nThe HW testing tool for the "+os.environ['P4_PROJECT_NAME']+" design\n\tType help to see all commands\n"

    def _get_rand_IP(self):
        return socket.inet_ntoa(struct.pack('>I', random.randint(1, 0xffffffff)))

    def _get_rand_port(self):
        return random.randint(1, 0xffff)

    def _make_packet(self, flow_size, src_host):
        vlan_id = vlan_id_map[port_slicing[src_host]]
        sport = self._get_rand_port()
        dport = self._get_rand_port()
        src_IP = IP_addr_H[src_host]
        dst_IP = IP_addr_H[dst_host_map[src_host]]
        if ( vlan_id == vlan_id_map["l2_switch"] ):
            src_MAC = MAC_addr_H[src_host]
            dst_MAC = MAC_addr_H[dst_host_map[src_host]]
            pkt = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=64, chksum=0x7ce7) / UDP(sport=sport, dport=dport) / ((flow_size - HEADER_SIZE)*"A")
        elif( vlan_id == vlan_id_map["router"] ):
            src_MAC = MAC_addr_H[src_host]
            dst_MAC = MAC_addr_S[src_host]
            pkt = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=64, chksum=0x7ce7) / UDP(sport=sport, dport=dport) / ((flow_size - HEADER_SIZE)*"A")
        else:
            print("\nERROR: vlan_id not mapped!\n")
            exit(1)
        pkt = pad_pkt(pkt, flow_size)
        return pkt

    """
    Generate a flow packets from all hosts in topology
    """
    def _make_flow(self, pkts_num, pkts_size):
        flow = [[] for _ in range(DEF_HOST_NUM)]

        # making flows
        for pid in range(pkts_num):
            src_host = int( pid % (DEF_HOST_NUM) )
            pkt = self._make_packet(pkts_size, src_host)
            flow[src_host].append(pkt)

        # sending packets
        for host in range(DEF_HOST_NUM):
            sender = IFACE_H[host]
            if ( len(flow[host]) != 0 ):
                print "\n  Flow "+str(host+1)+": H" +str(host)+ " -> H" +str(dst_host_map[host])
                sendp(flow[host], iface=sender)
                print ""

    def do_make_flow(self, line):
        pkts_num = None
        pkts_size = None
        args = line.split()
        if (len(args) != 2):
            print >> sys.stderr, "ERROR: usage..."
            self.help_make_flow()
        try:
            pkts_num = int(args[0])
            pkts_size = int(args[1])
        except:
            print >> sys.stderr, "ERROR: all arguments must be valid integers"

        if (pkts_num is not None and pkts_size is not None):
            self._make_flow(pkts_num, pkts_size)

    def help_make_flow(self):
        print """
make_flow <pkts_num> <pkts_size>\n
DESCRIPTION: Create a flow of UDP packets to each host and then apply that to the correct
ethernet interface, based on topology.
    <pkts_num>  : the number of packets to send to the switch
    <pkts_size> : the exactly size(headers + payload) of packet (in bytes)\n
(MAC_addr_H0)            (MAC_addr_SPort0)    (MAC_addr_SPort3)            (MAC_addr_H3)
 (IP_addr_H0)             (IP_addr_SPort0)    (IP_addr_SPort3)             (IP_addr_H3)
          H0 ------------------ nf0                 nf3 ------------------- H3
                                 |    SUME SWITCH    |
          H1 ------------------ nf1                 nf2 ------------------- H2
 (IP_addr_H1)             (IP_addr_SPort1)    (IP_addr_SPort2)             (IP_addr_H2)
(MAC_addr_H1)            (MAC_addr_SPort1)    (MAC_addr_SPort2)            (MAC_addr_H2)
"""

    """
    Generate a simple packets with size indicated by parameters and apply to the switch
    """
    def _gen_packets(self, pkts_num, pkts_size, src_host):
        pkts = []
        for fid in range(pkts_num):
            pkt = self._make_packet(pkts_size, src_host)
            sender = IFACE_H[src_host]
            pkts.append(pkt)
        print "\n  H" +str(src_host)+ " -> H" +str(dst_host_map[src_host])
        sendp(pkts, iface=sender)
        print ""

    def do_gen_packets(self, line):
        pkts_num = None
        pkts_size = None
        src_host = None
        args = line.split()
        if (len(args) != 3):
            print >> sys.stderr, "ERROR: usage..."
            self.help_gen_packets()
        try:
            pkts_num = int(args[0])
            pkts_size = int(args[1])
            src_host = int(args[2])
            if ((src_host < 0) or (src_host > 3)):
                print >> sys.stderr, "ERROR: src_host must be in topology"
        except:
            print >> sys.stderr, "ERROR: all arguments must be valid integers"

        if (pkts_num is not None and pkts_size is not None and src_host is not None):
            self._gen_packets(pkts_num, pkts_size, src_host)

    def help_gen_packets(self):
        print """
gen_packets <pkts_num> <pkts_size> <src_host>\n
DESCRIPTION: Create the number of UDP packets specificated by pkts_num with exactly pkts_size and
apply that to the switch. The src_host defines the ethernet interface to send the packets.\n
    <pkts_num>  : the number of packets to send to the switch
    <pkts_size> : the exactly size(headers + payload) of packet (in bytes)
    <src_host>  : the number of source host sender of packet, based on topology:\n
(MAC_addr_H0)            (MAC_addr_SPort0)    (MAC_addr_SPort3)            (MAC_addr_H3)
 (IP_addr_H0)             (IP_addr_SPort0)    (IP_addr_SPort3)             (IP_addr_H3)
          H0 ------------------ nf0                 nf3 ------------------- H3
                                 |    SUME SWITCH    |
          H1 ------------------ nf1                 nf2 ------------------- H2
 (IP_addr_H1)             (IP_addr_SPort1)    (IP_addr_SPort2)             (IP_addr_H2)
(MAC_addr_H1)            (MAC_addr_SPort1)    (MAC_addr_SPort2)            (MAC_addr_H2)
"""

    def do_exit(self, line):
        print ""
        return True

if __name__ == '__main__':
    if len(sys.argv) > 1:
        SimpleTester().onecmd(' '.join(sys.argv[1:]))
    else:
        SimpleTester().cmdloop()
