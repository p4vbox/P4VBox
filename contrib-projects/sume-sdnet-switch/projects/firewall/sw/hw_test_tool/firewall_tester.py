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


IFACE_H0 = "eth0" # network interface down
IFACE_H1 = "eth1" # network interface up
IFACE_H2 = "eth2" # network interface up
IFACE_H3 = "eth3" # network interface up
sender = IFACE_H0 # the network interface of the sender

VLANS = 1
VLAN_ID = 3
HEADER_SIZE = 46    # size of Ether/Dot1Q/IP/UDP headers

dst_host_map = {0:1, 1:0, 2:3, 3:2} # dictionary to map the sender and receiver Hosts H[0, 1, 2, 3] based in network topology

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

BLOCK_SPORT = 1234
BLOCK_DPORT = 8888


class SimpleTester(cmd.Cmd):

    prompt = "> "
    intro = "\nThe HW testing tool for the "+os.environ['P4_PROJECT_NAME']+" design\n\tType help to see all commands\n"

    def _get_rand_IP(self):
        return socket.inet_ntoa(struct.pack('>I', random.randint(1, 0xffffffff)))

    def _get_rand_port(self):
        return random.randint(1, 0xffff)

    def _get_rand_block(self):
        rand_sport = self._get_rand_port()
        rand_dport = self._get_rand_port()
        while ((rand_sport == BLOCK_SPORT) or (rand_dport == BLOCK_DPORT)):
            rand_sport = self._get_rand_port()
            rand_dport = self._get_rand_port()
        rand_block = bool(random.getrandbits(1))
        if ( rand_block ):
            if ( bool(random.getrandbits(1)) ):
                rand_sport = BLOCK_SPORT
            else:
                rand_dport = BLOCK_DPORT

        return (rand_sport, rand_dport, rand_block)

    def _make_packet(self, flow_size, src_ind):
        src_MAC = MAC_addr_H[src_ind]
        dst_MAC = MAC_addr_H[dst_host_map[src_ind]]
        src_IP = IP_addr_H[src_ind]
        dst_IP = IP_addr_H[dst_host_map[src_ind]]
        (sport, dport, block) = self._get_rand_block()
        if ( block ):
            if ( sport == BLOCK_SPORT ):
                print "\nBlocked!  H" +str(src_ind)+" to H"+str(dst_host_map[src_ind])+" | Source Port: "+str(sport)
            elif ( dport == BLOCK_DPORT ):
                print "\nBlocked!  H" +str(src_ind)+" to H"+str(dst_host_map[src_ind])+" | Destination Port: "+str(dport)
            else:
                print "\nBlocked!  H" +str(src_ind)+" to H"+str(dst_host_map[src_ind])+" | Unknown motive"
        else:
            print "\nSent from H" +str(src_ind)+" to H" +str(dst_host_map[src_ind])
        # make the data pkts
        vlan_prio = 0
        pkt = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=VLAN_ID, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=20) / UDP(sport=sport, dport=dport) / ((flow_size - HEADER_SIZE)*"A")
        pkt = pad_pkt(pkt, flow_size)
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
