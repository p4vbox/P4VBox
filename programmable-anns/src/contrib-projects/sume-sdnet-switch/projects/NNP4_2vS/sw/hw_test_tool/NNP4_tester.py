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


import os, sys, re, cmd, subprocess, shlex, time, random, socket, struct
#import numpy as np
from threading import Thread
from probe_hdrs import *
from collections import OrderedDict

#from nf_sim_tools import *

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


DEF_PKT_SIZE = 256  # default packet size (in bytes)
HEADER_SIZE = 46    # headers size: Ether/IP/UDP
DEF_PKT_NUM = 24    # default packets number to simulation
DEF_HOST_NUM = 4    # default hosts number in network topology
LEN_PROBE = len(ProbeData())
src_host = 0        # packets sender host
vlan_id = 1         # vlan identifier to matching with IPI architecture and nf_datapath.v
vlan_prio = 0       # vlan priority
extra_len = 0

IFACE_H0 = "enp1s0np0" # network interface down
IFACE_H1 = "enp1s0np1" # network interface up
IFACE_H2 = "enp1s0np0" # network interface up
IFACE_H3 = "enp1s0np1" # network interface up
sender = IFACE_H0 # the network interface of the sender

VLANS = 1
VLAN_ID = 1
HEADER_SIZE = 46    # size of Ether/Dot1Q/IP/UDP headers

dst_host_map = {0:1, 1:0, 2:3, 3:2} # dictionary to map the sender and receiver Hosts H[0, 1, 2, 3] based in network topology
nf_id_map = {"nf0":0, "nf1":1, "nf2":2, "nf3":3}

MAC_addr_H = {}
MAC_addr_H[nf_id_map["nf0"]] = "08:00:00:00:01:11"
MAC_addr_H[nf_id_map["nf1"]] = "08:00:00:00:02:22"
MAC_addr_H[nf_id_map["nf2"]] = "08:00:00:00:03:33"
MAC_addr_H[nf_id_map["nf3"]] = "08:00:00:00:04:44"

IP_addr_H = {}
IP_addr_H[nf_id_map["nf0"]] = "10.0.1.1"
IP_addr_H[nf_id_map["nf1"]] = "10.0.2.2"
IP_addr_H[nf_id_map["nf2"]] = "10.0.3.3"
IP_addr_H[nf_id_map["nf3"]] = "10.0.4.4"

MAC_addr_S = {}
MAC_addr_S[nf_id_map["nf0"]] = "05:00:00:00:01:05"
MAC_addr_S[nf_id_map["nf1"]] = "05:00:00:00:02:05"
MAC_addr_S[nf_id_map["nf2"]] = "05:00:00:00:03:05"
MAC_addr_S[nf_id_map["nf3"]] = "05:00:00:00:04:05"


class SimpleTester(cmd.Cmd):

    prompt = "> "
    intro = "\nThe HW testing tool for the NNP4 design\n\tType help to see all commands\n"

    def _pad_pkt(self, pkt, size):
        if len(pkt) >= size:
            return pkt
        else:
            return pkt / ('\x00'*(size - len(pkt)))

    def _get_rand_IP(self):
        return socket.inet_ntoa(struct.pack('>I', random.randint(1, 0xffffffff)))

    def _get_rand_port(self):
        return random.randint(1, 0xffff)

    def _make_packet(self, flow_size, src_ind):
        # src_IP = self._get_rand_IP()
        # dst_IP = self._get_rand_IP()
        src_MAC = MAC_addr_H[src_ind]
        # dst_MAC = MAC_addr_H[dst_host_map[src_ind]]
        # I need fix this to work with:    dst_MAC = MAC_addr_H[dst_host_map[src_ind]]
        dst_MAC = MAC_addr_S[dst_host_map[src_ind]]
        src_IP = IP_addr_H[src_ind]
        dst_IP = IP_addr_H[dst_host_map[src_ind]]
        sport = self._get_rand_port()
        dport = self._get_rand_port()
        # make the data pkts
        vlan_prio = 0
        pkt = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=64, chksum=0x7ce7) / ((DEF_PKT_SIZE - HEADER_SIZE)*"A")
        #pkt = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=VLAN_ID, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=20) / UDP(sport=sport, dport=dport) / ((flow_size - HEADER_SIZE)*"A")
        pkt = self._pad_pkt(pkt, flow_size)
        return pkt

    """
    Generate a simple packets with size indicated by parameters and apply to the switch
    """
    def _gen_packets(self, pkts_num, pkts_size, src_host):
        pkts = []
        for fid in range(pkts_num):
            pkt = self._make_packet(pkts_size, src_host)
            # apply trace to the switch
            if src_host == 0:
                sender = IFACE_H0
            elif src_host == 1:
                sender = IFACE_H1
            elif src_host == 2:
                sender = IFACE_H2
            elif src_host == 3:
                sender = IFACE_H3
            else:
                print >> sys.stderr, "ERROR: usage..."
            pkts.append(pkt)
        print "\n  H" +str(src_host)+ " -> H" +str(dst_host_map[src_host])
        sendp(pkts, iface=sender)

    def _parse_line_gen_packets(self, line):
        args = line.split()
        if (len(args) != 3):
            print >> sys.stderr, "ERROR: usage..."
            self.help_gen_packets()
            return (None, None, None)
        try:
            pkts_num = int(args[0])
            pkts_size = int(args[1])
            src_host = int(args[2])
            if ((src_host < 0) or (src_host > 3)):
                print >> sys.stderr, "ERROR: src_host must be in topology"
                return (None, None, None)
        except:
            print >> sys.stderr, "ERROR: all arguments must be valid integers"
            return (None, None, None)

        return (pkts_num, pkts_size, src_host)

    def do_gen_packets(self, line):
        (pkts_num, pkts_size, src_host) = self._parse_line_gen_packets(line)
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
